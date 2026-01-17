local RunService = game:GetService("RunService")

local TableUtil = require("../../../roblox_packages/TableUtil")

local vide = require("../../../roblox_packages/vide")

local Types = require("../../Types")
local ImageLabel = require("../../Components/ImageLabel")

local effect = vide.effect
local source = vide.source
local read = vide.read

export type AnimationFrameProps =
	Types.props<{
		ImageContents: { Content },
		Frame: number?,
		AutoPlay: boolean?,
		Fps: number?,
	}>
	& ImageLabel.ImageLabelProps

	
local function getInitialFrame(props, totalFrames): number
	if props.Frame ~= nil and totalFrames > 0 then
		return math.clamp(props.Frame, 1, totalFrames) -- props.Frame이 있으면 해당 값으로, 범위 제한
	elseif totalFrames > 0 then
		return 1 -- 이미지가 있으면 첫 번째 프레임
	end
	return 0 -- 유효한 프레임이 없거나 이미지가 없는 경우 (렌더링 시 빈 이미지 처리)
end

local function AnimationFrame(props: AnimationFrameProps)
	local totalFrames = vide.derive(function()
		return #(read(props.ImageContents) or {})
	end)

	local currentFrameIndex = source(getInitialFrame(props, totalFrames))

	-- props.Frame이 변경될 때 currentFrameIndex를 업데이트하는 Effect
	effect(function()
		local frame = read(props.Frame) or 1

		if totalFrames > 0 then
			currentFrameIndex(frame, 1, totalFrames)
		else
			currentFrameIndex(0) -- 이미지가 없으면 유효한 프레임 없음
		end
	end)

	-- AutoPlay 로직을 처리하는 Effect
	effect(function()
		-- 자동 재생 조건:
		-- 1. props.AutoPlay가 true
		-- 2. props.Frame이 설정되지 않음 (수동 프레임 설정이 우선)
		-- 3. 재생할 이미지가 하나 이상 존재
		if props.AutoPlay and props.Frame == nil and totalFrames > 0 then
			local fps = props.Fps or 16
			if fps <= 0 then
				fps = 16
			end
			local frameDuration = 1 / fps -- 각 프레임의 지속 시간
			local accumulatedTime = 0 -- 경과 시간 누적

			-- 자동 재생 시작 시, 현재 프레임이 유효하지 않으면 첫 프레임부터 시작하도록 보정
			local frameForAutoplay = currentFrameIndex()
			if frameForAutoplay == 0 or frameForAutoplay > totalFrames then
				frameForAutoplay = 1
				currentFrameIndex(1) -- 상태도 업데이트하여 다음 렌더링 및 로직에 반영
			end

			local conn = RunService.RenderStepped:Connect(function(dt: number)
				accumulatedTime = accumulatedTime + dt
				if accumulatedTime >= frameDuration then
					accumulatedTime = accumulatedTime - frameDuration -- 초과된 시간은 다음 프레임 계산에 사용 (정확도 향상)

					-- 함수형 업데이트를 사용하여 이전 상태 값에 안전하게 접근
					local prev = currentFrameIndex()
					local nextFrame = prev + 1
					if nextFrame > totalFrames then
						nextFrame = 1
					end
					currentFrameIndex(nextFrame)
				end
			end)

			vide.cleanup(function()
				conn:Disconnect()
			end)
		end
	end)

	local labelProps = table.clone(props)

	labelProps.ImageContent = function()
		local index = math.clamp(currentFrameIndex(), 1, totalFrames())
		return read(props.ImageContents or {})[index]
	end
	labelProps.Frame = nil
	labelProps.AutoPlay = nil
	labelProps.Fps = nil

	return ImageLabel(labelProps)
end

return AnimationFrame
