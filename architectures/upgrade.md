# BakeryVideKit 업그레이드 설계도

## 배경
- 현재 컴포넌트는 `TableUtil.merge`, `table.clone`, 수동 nil 처리로 props를 조합한다.
- 조합을 쓰고 싶어도 "깊은 props"로 내려 보내는 방식은 유지보수와 확장에 불리하다.
- Vide는 `create`, `action`, `cleanup` 등으로 인스턴스 추가 없이 동작을 붙일 수 있다.

이 문서는 BakeryVideKit에서 "mixin처럼 동작을 붙여넣기"를 표준으로 만들기 위한 설계를 정리한다.

## 목표
- 동작을 "컴포넌트 상속"이 아니라 "조합"으로 붙일 수 있다.
- 인스턴스 추가 없이 행동을 부착할 수 있다.
- 컴포넌트 내부 코드에서 props 분리/전달 규칙을 표준화한다.
- 성능, 유지보수성, 가독성을 함께 만족한다.

## 비목표
- Vide 내부 동작을 변경하지 않는다.
- 모든 컴포넌트를 즉시 리라이트하지 않는다.
- 깊은 props 트리를 공식 패턴으로 만들지 않는다.

## 용어 정의
- owned props: 컴포넌트가 직접 소유하고 처리하는 키.
- rest props: 컴포넌트가 처리하지 않고 하위 root 인스턴스로 전달하는 키.
- modifier(mixin): props 조각. 인스턴스에 적용 가능한 속성/이벤트/children/action만 담는다.
- behavior(action): 인스턴스를 참조하여 동작을 붙이는 액션.

## 핵심 규약
1) 컴포넌트는 owned props만 처리하고, 나머지는 rest props로 전달한다.
2) modifier는 래퍼 없이 "그냥 Properties 테이블"로 전달한다(메타테이블 마킹만 허용).
3) 병합은 string-key와 number-key를 분리해서 처리한다.
4) string-key는 순서 기반(last-write-wins)으로 적용한다.
5) Dev 모드에서는 덮어쓰기 경고/추적을 제공한다.
6) ControlledKeys는 덮어쓰기 금지로 처리한다.
7) modifier에서 이벤트를 string-key로 직접 달지 않는다. 이벤트는 behavior(action)로만 연결한다.
8) behavior 기본형은 reactive scope를 만들지 않는다. 반응형 업데이트가 필요하면 별도 API로 분리한다.
9) action priority 밴드를 표준화한다.
10) scope 내부에서 yield 호출을 금지한다(WaitForChild, task.wait 등).
11) 성능은 인스턴스 수보다 루프/연결/속성 변경 빈도가 중요하다.

## Roblox 제약 기반 규칙
- 이벤트 연결은 리소스이므로 action에서 연결 후 즉시 `cleanup(conn)`으로 정리한다.
- RenderStepped/PreRender/Heartbeat는 컴포넌트별로 만들지 않고, 필요 시 전역 스케줄러로 합친다.
- PreRender 구독은 단일 연결만 유지한다.
- 자주 변하는 UI와 거의 변하지 않는 UI는 LayerCollector 단위로 분리한다.
- 레이아웃 영향 속성(Size, Position, AutomaticSize 등)은 LayoutModifier나 전용 컨테이너에서만 변경한다.
- deep merge/clone은 피하고, 얕은 병합과 구조적 공유를 우선한다.

## Context 표준
- ThemeContext: 색/폰트/라운딩 토큰.
- MotionContext: 애니메이션 on/off, spring 파라미터.
- InputContext: 입력 장치별 포커스/상호작용 정책.

## 제안 API (BakeryVideKit에 추가)
### 1) modifier 표현
modifier는 래퍼를 두지 않는다. 식별이 필요하면 metatable로만 표시한다.

```lua
-- src/Modifier/init.luau (예시)
local Modifier = {}

local MODIFIER_METATABLE = {}

function Modifier.fromProps(props)
	return setmetatable(props, MODIFIER_METATABLE)
end

function Modifier.isModifier(value)
	if type(value) ~= "table" then
		return false
	end
	local metatable = getmetatable(value)
	return metatable == MODIFIER_METATABLE
end

return Modifier
```

주의: modifier 메타테이블에는 `__pairs`/`__index` 같은 동작을 넣지 않는다.
주의: modifier 안에서 이벤트를 string-key로 직접 추가하지 않는다.
주의: modifier 관련 API는 camelCase로 통일한다.

### 2) Props 분리/병합 유틸
`splitProps`는 owned/rest만 분리하고, 숫자 인덱스는 props에 남긴다.
`composeProps`는 props의 숫자 인덱스를 직접 스캔해 string-key와 number-key를 순서대로 병합한다.

```lua
-- src/Props/init.luau (예시)
local Modifier = require("../Modifier")

local Props = {}

local function applyStringKeys(target, source, traceByKey, originByKey, originTag, opts, disallowEventKeys)
	for key, value in source do
		if type(key) ~= "string" then
			continue
		end

		local eventKeySet = opts and opts.eventKeySet
		if disallowEventKeys and eventKeySet and type(value) == "function" and eventKeySet[key] then
			error(("event key is not allowed in modifier: %s"):format(key))
		end

		local controlledKeys = opts and opts.controlledKeys
		if controlledKeys and controlledKeys[key] then
			if target[key] ~= nil and target[key] ~= value then
				error(("controlled prop cannot be overridden: %s"):format(key))
			end
			target[key] = value
			if originByKey then
				originByKey[key] = originTag
			end
			continue
		end

		if target[key] ~= nil and target[key] ~= value and traceByKey then
			local trace = traceByKey[key]
			if not trace then
				trace = { first = originByKey and originByKey[key] or "Unknown", overwrittenBy = {} }
				traceByKey[key] = trace
			end
			table.insert(trace.overwrittenBy, originTag)
		end

		target[key] = value
		if originByKey then
			originByKey[key] = originTag
		end
	end
end

function Props.keySet(ownedKeys)
	local ownedKeySet = {}
	for index = 1, #ownedKeys do
		local key = ownedKeys[index]
		ownedKeySet[key] = true
	end
	return ownedKeySet
end

function Props.splitProps(props, ownedKeySet)
	local owned = {}
	local rest = {}

	for key, value in props do
		if type(key) == "string" then
			if ownedKeySet[key] then
				owned[key] = value
			else
				rest[key] = value
			end
		end
	end

	return owned, rest
end

function Props.composeProps(base, rest, props, opts)
	local out = {}
	local traceByKey = nil
	local originByKey = nil

	if opts and opts.onConflict == "warn" then
		traceByKey = {}
		originByKey = {}
	end

	applyStringKeys(out, base, traceByKey, originByKey, "Base", opts)

	for index = 1, #props do
		local item = props[index]
		if Modifier.isModifier(item) then
			applyStringKeys(out, item, traceByKey, originByKey, ("Modifier#%d"):format(index), opts, true)
		end
	end

	applyStringKeys(out, rest, traceByKey, originByKey, "Rest", opts)

	for index = 1, #props do
		local item = props[index]
		if Modifier.isModifier(item) then
			for childIndex = 1, #item do
				local child = item[childIndex]
				table.insert(out, child)
			end
		else
			table.insert(out, item)
		end
	end

	local hasConflicts = false
	if traceByKey then
		for _ in traceByKey do
			hasConflicts = true
			break
		end
	end

	if hasConflicts then
		if opts and opts.onWarn then
			opts.onWarn(traceByKey, originByKey)
		else
			warn("composeProps conflicts", traceByKey)
		end
	end

	return out
end

return Props
```

옵션(Dev/Prod 공통):
- `onConflict`: `"warn"` 또는 `"silent"`.
- `onWarn(traceByKey, originByKey)`: Dev 경고 훅.
- `controlledKeys`: 덮어쓰기 금지 키 집합.
- `eventKeySet`: modifier 이벤트 금지 검증용 키 집합(Dev에서만 사용).

주의: `splitProps`는 숫자 인덱스를 복사하지 않는다. `composeProps`는 `props` 자체를 스캔한다.
주의: children 배열이 비연속이면 조기 종료될 수 있으므로 Dev 모드에서 연속성 검증을 권장한다.
주의: ownedKeySet은 컴포넌트 외부에서 상수로 생성해 재사용한다.
주의: modifier 중첩은 금지한다. Dev 모드에서 감지되면 에러로 처리한다.
주의: modifier 이벤트 금지는 Dev 모드에서 `eventKeySet`으로 강제한다(함수 값 + 이벤트 키 조합 금지).

### 2.1) composeProps 모드 분리 (Dev/Prod)
- Dev: 덮어쓰기 추적 + 경고(onWarn) + 배열 연속성 검사 + modifier 이벤트 금지 검증.
- Prod: 추적 제거 + 최소 병합.
- `Props.composePropsDev` / `Props.composePropsProd` 이름으로 제공한다.

```lua
local composeProps = Props.composePropsProd
if IS_DEV then
	composeProps = Props.composePropsDev
end
```

### 3) behavior(action) 표준 계약
behavior는 Vide `action`을 감싼 표준 계약을 제공한다. 기본형은 reactive scope를 만들지 않는다.

```lua
-- src/Behaviors/behavior.luau (예시)
local vide = require("../../roblox_packages/vide")
local cleanup = vide.cleanup
local action = vide.action

local function behavior(setup, opts)
	return action(function(instance)
		local result = setup(instance)
		if result and result.destroy then
			cleanup(result.destroy)
		end
	end, opts and opts.priority)
end

return behavior
```

반응형 업데이트가 필요한 behavior는 별도 API로 분리한다.

```lua
-- src/Behaviors/behaviorReactive.luau (예시)
local vide = require("../../roblox_packages/vide")
local effect = vide.effect
local cleanup = vide.cleanup
local action = vide.action

local function behaviorReactive(setup, opts)
	return action(function(instance)
		local result = setup(instance)
		if result and result.update then
			effect(function()
				result.update()
			end)
		end
		if result and result.destroy then
			cleanup(result.destroy)
		end
	end, opts and opts.priority)
end

return behaviorReactive
```

주의: `behaviorReactive`는 안정적인 reactive scope에서만 사용한다.
주의: action은 속성/자식 적용보다 먼저 실행된다. 인스턴스의 최종 스타일을 baseline으로 읽지 않는다.
주의: 반응형 업데이트는 modifier 내부 effect/derive로 먼저 구성하고, behavior는 이벤트 연결만 담당한다.

## 타입 규약
- modifier는 `Types.props` 형태를 유지하되, metatable로만 마킹한다.
- behavior는 `Types.action`을 반환하고, 우선순위는 number로 통일한다.
- Props 유틸은 `Types.child` 정의와 충돌하지 않도록 숫자 인덱스를 그대로 유지한다.
- props는 값 또는 함수일 수 있으므로, 필요한 경우 `vide.read` 같은 해석 함수를 사용한다.

## 표준 사용 패턴
### 1) Hoverable (event 키 직접 설정 대신 action 연결)

```lua
local vide = require("../../roblox_packages/vide")

local Modifier = require("./init")
local behavior = require("../Behaviors/behavior")

local batch = vide.batch
local cleanup = vide.cleanup
local read = vide.read
local source = vide.source
local spring = vide.spring

local function Hoverable(props)
	local hovered = source(false)
	local target = source(read(props.normal))
	local animated = spring(target, props.period or 0.18, props.damping or 1)

	return Modifier.fromProps({
		BackgroundColor3 = animated,

		behavior(function(instance)
			local enter = instance.MouseEnter:Connect(function()
				batch(function()
					hovered(true)
					target(read(props.hover))
				end)
			end)
			cleanup(enter)
			local leave = instance.MouseLeave:Connect(function()
				batch(function()
					hovered(false)
					target(read(props.normal))
				end)
			end)
			cleanup(leave)
		end),
	})
end

return Hoverable
```

### 2) 컴포넌트에서 분리/전달

```lua
local Props = require("../../Props")

local OWNED_KEY_SET = Props.keySet({
	"Text",
	"OnClick",
	"Disabled",
	"Variant",
})

local function Button(props)
	local localProps, restProps = Props.splitProps(props, OWNED_KEY_SET)
	local onConflict = "silent"
	if IS_DEV then
		onConflict = "warn"
	end

	local base = {
		Class = "TextButton",
		Text = localProps.Text or "Button",
		Activated = localProps.OnClick,
	}

	return Frame(Props.composeProps(base, restProps, props, {
		onConflict = onConflict,
		controlledKeys = Props.keySet({ "Class", "Parent" }),
	}))
end
```

## 충돌/우선순위 정책
- 속성(property): 기본은 last-write-wins.
- 충돌 추적: Dev에서는 경고/추적을 남긴다.
- ControlledKeys: 덮어쓰기를 금지한다.
- 우선순위: `base < modifier(순서대로) < rest`.
- 이벤트(event): modifier에서 string-key 금지. 기본은 action 연결 방식.
- children/action: 숫자 인덱스 순서대로 append.
- action 우선순위는 `vide.action`의 priority로 결정한다.

## Action Priority 밴드
- priority는 낮을수록 먼저 실행된다.
- action priority는 action 내부 순서만 제어한다(속성/자식 적용 이후를 보장하지 않는다).
- 0~9: 내부 wiring(타입 가드, 공용 로깅).
- 10~19: 일반 behavior.
- 90~99: late action(동작 간 우선순위 조정).

## Vide 최적화 도구
- `derive()`: 계산 결과를 캐싱해 중복 계산을 줄인다.
- `batch()`: 이벤트 콜백에서 여러 source 업데이트를 묶는다.
- `untrack()`: 의도적으로 의존성을 끊고 값을 읽는다.

## cleanup 규칙
- `RBXScriptSignal:Connect`는 `cleanup(conn)` 형태로 등록한다.
- action 내부에서 생성한 리소스(트윈, task, RunService 연결)는 즉시 정리한다.
- strict 모드에서 재실행되어도 안전하게 동작하도록 idempotent하게 작성한다.
- Disconnectable이 아닌 리소스는 `cleanup(function() ... end)`로 정리한다.

## 검증 체크리스트
- action/behavior에서 생성한 connection 수가 누적되지 않는지 확인한다.
- RunService 연결 수가 전역적으로 제한되는지 확인한다.
- 프레임당 속성 변경 빈도가 과도하지 않은지 확인한다.
- modifier children 배열이 연속인지 확인한다.
- modifier에서 이벤트 string-key가 사용되지 않는지 확인한다.
- scope 내부에서 yield 호출이 없는지 확인한다.
- PreRender 연결 수가 1개인지 확인한다.

## 마이그레이션 순서
1) `Modifier`, `Props`, `behavior` 유틸 추가.
2) 작은 컴포넌트부터 owned/rest 분리 적용.
3) 대표 behavior(Hoverable/Pressable/Focusable) 제공.
4) 기존 `UIComponents`/`InternalChildren`는 숫자 인덱스(children/action)로 통합하고 점진적 제거.
5) Dev 모드에서 충돌/정리 누락 검출을 기본으로 활성화.

## 기대 효과
- props가 깊어지지 않고, 표준 방식으로 기능을 붙일 수 있다.
- 컴포넌트가 단순해지고, 재사용과 확장이 쉬워진다.
- 인스턴스 증가 없이 동작을 부착할 수 있다.
- Roblox 성능 제약과 Vide 스코프 규칙을 동시에 만족한다.
