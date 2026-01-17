--[[ 
    Frame 컴포넌트의 무지개 반동 스토리입니다.
    - 둥근 모서리(UICorner) 경계에 맞춘 실제 반사(원호 법선 반사)
    - spring()으로 스쿼시/스트레치
    - 무지개 잔상(풀/링버퍼), UIGradient 회전
    - UI Labs controls → Vide.Source 로 실시간 조정
]]

local RunService = game:GetService("RunService")

local vide = require("../../../roblox_packages/vide")

local create = vide.create
local effect = vide.effect
local source = vide.source
local cleanup = vide.cleanup
local changed = vide.changed
local spring = vide.spring
local derive = vide.derive
local read = vide.read

-- 기본 컨트롤(UILabs가 Source로 래핑해 props.controls로 넣어줌)
local controls = {
	Speed = 1.0, -- 공 속도 배수
	Bounciness = 0.96, -- 튕김 계수 (0~1.05)
	CornerRadius = 24, -- 컨테이너 모서리 반경(px)
	BallSize = 30, -- 공 지름(px)
	HueSpeed = 0.20, -- 무지개 진행 속도(HSV)
	TrailCount = 36, -- 잔상 최대 개수(풀 크기)
	TrailLife = 0.75, -- 잔상 생존시간(초)
	TrailSampleRate = 30, -- 초당 잔상 샘플 횟수
	Border = true, -- 컨테이너 외곽선
	Glow = true, -- 공 광휘(Gradient+Stroke)
}

-- ──────────────────────────────────────────────────────────────────────────────
-- 수학 유틸
local function clamp(x, a, b)
	return math.max(a, math.min(b, x))
end
local function wrap01(t)
	t = t % 1
	if t < 0 then
		t += 1
	end
	return t
end
local function reflect(v: Vector2, n: Vector2): Vector2
	-- v' = v - 2*(v·n)*n
	local d = v:Dot(n)
	return v - 2 * d * n
end

-- 원호(모서리 둥근 부분) 충돌 처리: 중심 c, 반지름 r, 공 반지름 br
local function collideCircle(pos: Vector2, vel: Vector2, c: Vector2, r: number, br: number)
	local delta = pos - c
	local dist = delta.Magnitude
	if dist == 0 then
		-- 병적 케이스: 중심과 정확히 겹침 → 약간 밀어내기
		delta = Vector2.new(1, 0)
		dist = 1
	end
	local limit = r - br
	if dist > limit then
		local n = delta.Unit
		local newPos = c + n * limit
		local newVel = reflect(vel, n)
		return true, newPos, newVel, n
	end
	return false, pos, vel, Vector2.zero
end

-- ColorSequence 헬퍼(무지개)
local function rainbowSeq(h: number)
	local h0 = wrap01(h)
	local h1 = wrap01(h + 1 / 6)
	local h2 = wrap01(h + 2 / 6)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromHSV(h0, 1, 1)),
		ColorSequenceKeypoint.new(0.5, Color3.fromHSV(h1, 1, 1)),
		ColorSequenceKeypoint.new(1.0, Color3.fromHSV(h2, 1, 1)),
	})
end

-- 투명도(가우시안 느낌) 커브
local function trailAlpha(t) -- t: 0(막생성) ~ 1(사라짐)
	local x = clamp(t, 0, 1)
	local bell = math.exp(-8 * x * x)
	return bell -- 0~1, 1에 가까울수록 불투명
end

-- ──────────────────────────────────────────────────────────────────────────────
local story = {
	vide = vide,
	controls = controls,

	story = function(props)
		-- 컨테이너 실제 픽셀 크기
		local containerSize = source(Vector2.new(0, 0))

		-- 공 상태
		local pos = source(Vector2.new(120, 80))
		local vel = source(Vector2.new(220, 170)) -- px/s 기준 초기값

		-- 색/연출 상태
		local hue = source(0.0)
		local gradRotation = source(0.0)

		-- 스케일(스쿼시/스트레치) 스프링
		local scaleTarget = source(Vector2.new(1, 1)) -- 기본은 (1,1) 타깃
		local scale, scaleCfg = spring(scaleTarget, 0.18, 0.85) -- period, damping

		-- 컨트롤 캐시(Heartbeat에서 빠르게 접근)
		local conf = {
			speed = 1.0,
			bounce = 0.96,
			corner = 24,
			ball = 30,
			hueSpeed = 0.2,
			trailCount = 36,
			trailLife = 0.75,
			trailRate = 30,
			border = true,
			glow = true,
		}
		effect(function()
			-- props.controls는 Vide.Source 이므로 함수처럼 호출하면 최신값
			conf.speed = clamp(props.controls.Speed(), 0.1, 4.0)
			conf.bounce = clamp(props.controls.Bounciness(), 0.2, 1.05)
			conf.corner = math.max(0, props.controls.CornerRadius())
			conf.ball = math.max(4, props.controls.BallSize())
			conf.hueSpeed = clamp(props.controls.HueSpeed(), 0.01, 3.0)
			conf.trailCount = clamp(props.controls.TrailCount(), 8, 96)
			conf.trailLife = clamp(props.controls.TrailLife(), 0.2, 2.0)
			conf.trailRate = clamp(props.controls.TrailSampleRate(), 8, 120)
			conf.border = props.controls.Border()
			conf.glow = props.controls.Glow()
		end)

		-- 루트 프레임(타깃의 자식으로 적용됨)
		local root = create("Frame")({
			Name = "RainbowBounce",
			BackgroundColor3 = Color3.fromRGB(10, 12, 18),
			BackgroundTransparency = 0,
			Size = UDim2.fromScale(1, 1),
			ClipsDescendants = true,

			-- 사이즈 추적
			changed("AbsoluteSize", function(v: Vector2)
				containerSize(v)
			end),

			-- 둥근 경계
			create("UICorner")({
				CornerRadius = function()
					return UDim.new(0, conf.corner)
				end,
			}),

			-- 약한 배경 그라데이션 (회전 애니메이션)
			create("UIGradient")({
				Rotation = function()
					return gradRotation()
				end,
				Color = function()
					-- 배경은 흐릿한 무지개
					return rainbowSeq(hue() * 0.5)
				end,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.25),
					NumberSequenceKeypoint.new(1, 0.25),
				}),
			}),

			-- 테두리
			create("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Thickness = 1.5,
				Transparency = function()
					return conf.border and 0.35 or 1
				end,
				Color = Color3.fromRGB(255, 255, 255),
			}),
		})

		-- 잔상 풀
		local TRAIL_MAX = 96 -- 하드 상한 (controls로 실제 사용량 제한)
		local trailFolder = create("Folder")({ Name = "Trail", Parent = root })
		local trails = table.create(TRAIL_MAX)
		for i = 1, TRAIL_MAX do
			local tf = create("Frame")({
				Name = `Ghost_{i}`,
				Visible = false,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(0, 0),
				Position = UDim2.fromOffset(0, 0),
				ZIndex = 5,
				Parent = trailFolder,

				create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
				create("UIStroke")({
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Thickness = 1,
					Transparency = 0.4,
				}),
				create("UIGradient")({ -- 각 잔상도 살짝 무지개
					Rotation = 0,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0.1),
						NumberSequenceKeypoint.new(1, 0.9),
					}),
				}),
			})
			trails[i] = {
				frame = tf,
				alive = false,
				age = 0, -- 0 ~ life
				hue = 0,
				size = 0,
				pos = Vector2.zero,
			}
		end
		local trailHead = 0
		local function spawnTrail(p: Vector2, sizePx: number, h: number)
			trailHead = (trailHead % conf.trailCount) + 1
			local t = trails[trailHead]
			t.alive = true
			t.age = 0
			t.hue = h
			t.size = sizePx
			t.pos = p
			local fr = t.frame
			fr.Visible = true
			fr.ZIndex = 5
		end

		-- 공
		local ball = create("Frame")({
			Name = "Ball",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Size = function()
				local s = scale() -- spring된 스케일
				local d = conf.ball
				return UDim2.fromOffset(d * s.X, d * s.Y)
			end,
			Position = function()
				local p = pos()
				local d = conf.ball
				return UDim2.fromOffset(p.X - d * 0.5, p.Y - d * 0.5)
			end,
			BorderSizePixel = 0,
			ZIndex = 10,
			Parent = root,

			create("UICorner")({ CornerRadius = UDim.new(1, 0) }),

			-- 공 하이라이트(광휘) - Gradient + Stroke
			create("UIGradient")({
				Rotation = function()
					return gradRotation()
				end,
				Color = function()
					return rainbowSeq(hue())
				end,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0.00, 0.0),
					NumberSequenceKeypoint.new(0.70, 0.15),
					NumberSequenceKeypoint.new(1.00, 1.0),
				}),
			}),
			create("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Thickness = function()
					return conf.glow and 2 or 0
				end,
				Transparency = 0.2,
				Color = Color3.fromRGB(255, 255, 255),
			}),
		})

		-- Heartbeat 루프
		effect(function()
			local hb
			local sampleTimer = 0
			hb = RunService.Heartbeat:Connect(function(dt)
				if dt <= 0 or containerSize().X <= 0 then
					return
				end

				-- 색상/회전 애니
				local nextHue = hue() + conf.hueSpeed * dt
				hue(wrap01(nextHue))
				gradRotation((gradRotation() + 60 * dt) % 360)

				-- 물리 업데이트
				local p = pos()
				local v = vel()
				local speedMul = conf.speed
				p += v * (dt * speedMul)

				local size = containerSize()
				local W, H = size.X, size.Y
				local r = conf.corner
				local d = conf.ball
				local br = d * 0.5

				local collided = false
				local normal = Vector2.zero

				-- 1) 직선 벽 충돌(모서리의 사각 코어 영역)
				local leftWall = r + br
				local rightWall = W - r - br
				local topWall = r + br
				local bottomWall = H - r - br

				-- 가로벽
				if p.Y < topWall then
					p = Vector2.new(p.X, topWall)
					v = Vector2.new(v.X, -v.Y)
					collided = true
					normal = Vector2.new(0, 1)
				elseif p.Y > bottomWall then
					p = Vector2.new(p.X, bottomWall)
					v = Vector2.new(v.X, -v.Y)
					collided = true
					normal = Vector2.new(0, -1)
				end

				-- 세로벽
				if p.X < leftWall then
					p = Vector2.new(leftWall, p.Y)
					v = Vector2.new(-v.X, v.Y)
					collided = true
					normal = Vector2.new(1, 0)
				elseif p.X > rightWall then
					p = Vector2.new(rightWall, p.Y)
					v = Vector2.new(-v.X, v.Y)
					collided = true
					normal = Vector2.new(-1, 0)
				end

				-- 2) 둥근 모서리(원호) 충돌 처리
				if not collided then
					-- TL
					if p.X < r + br and p.Y < r + br then
						local hit, np, nv, n = collideCircle(p, v, Vector2.new(r, r), r, br)
						if hit then
							p, v, collided, normal = np, nv, true, n
						end
					-- TR
					elseif p.X > W - r - br and p.Y < r + br then
						local hit, np, nv, n = collideCircle(p, v, Vector2.new(W - r, r), r, br)
						if hit then
							p, v, collided, normal = np, nv, true, n
						end
					-- BL
					elseif p.X < r + br and p.Y > H - r - br then
						local hit, np, nv, n = collideCircle(p, v, Vector2.new(r, H - r), r, br)
						if hit then
							p, v, collided, normal = np, nv, true, n
						end
					-- BR
					elseif p.X > W - r - br and p.Y > H - r - br then
						local hit, np, nv, n = collideCircle(p, v, Vector2.new(W - r, H - r), r, br)
						if hit then
							p, v, collided, normal = np, nv, true, n
						end
					end
				end

				if collided then
					-- 반발계수
					v *= conf.bounce

					-- 스쿼시/스트레치: 법선 방향으로 즉각적인 스프링 임펄스
					local impulse = Vector2.new(-0.55 * normal.X, 0.55 * normal.Y)
					scaleCfg({ impulse = impulse })
				end

				pos(p)
				vel(v)

				-- 잔상 샘플
				sampleTimer += dt
				local sampleStep = 1 / conf.trailRate
				while sampleTimer >= sampleStep do
					sampleTimer -= sampleStep
					spawnTrail(p, d, hue())
				end

				-- 잔상 업데이트
				for i = 1, conf.trailCount do
					local t = trails[i]
					if t and t.alive then
						t.age += dt
						if t.age >= conf.trailLife then
							t.alive = false
							t.frame.Visible = false
						else
							local k = t.age / conf.trailLife
							local alpha = trailAlpha(k) -- 0~1 (불투명도 커브)
							local sizeK = 0.8 + 0.6 * (1 - k) -- 점점 작아짐
							local s = t.size * sizeK
							local fr = t.frame
							fr.Visible = true
							fr.Size = UDim2.fromOffset(s, s)
							fr.Position = UDim2.fromOffset(t.pos.X - s * 0.5, t.pos.Y - s * 0.5)
							fr.BackgroundTransparency = 1 - 0.2 * alpha
							local st = fr:FindFirstChildOfClass("UIStroke")
							if st then
								st.Transparency = 1 - 0.05 * alpha
								st.Color = Color3.fromHSV(wrap01(t.hue + 0.02), 1, 1)
							end
							local ug = fr:FindFirstChildOfClass("UIGradient")
							if ug then
								ug.Color = rainbowSeq(wrap01(t.hue + 0.04))
								ug.Rotation = (gradRotation() + 90 * k) % 360
							end
						end
					end
				end
			end)

			cleanup(function()
				if hb then
					hb:Disconnect()
				end
			end)
		end)

		return root
	end,
}

return story
