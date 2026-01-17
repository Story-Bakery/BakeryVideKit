local vide = require("../../../roblox_packages/vide")

local Frame = require("../../Components/Frame")
local Gradient = require("../../Components/UIComponent/Gradient")
local TableUtil = require("../../../roblox_packages/TableUtil")
local Types = require("../../Types")
local VideKitUtils = require("../../Utils")

local create = vide.create
local read = vide.read
local derive = vide.derive
local effect = vide.effect

export type CircularFrameProps =
	Types.props<{
		StartProgress: number,
		EndProgress: number,

		UIComponents: any,
	}>
	& Frame.FrameProps

local OFFSET = 0.001

local CIRCLUAR_TRANSPARENCY_SEQUENCE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(0.5 + OFFSET, 1),
	NumberSequenceKeypoint.new(1, 1),
})

local REVERSED_TRANSPARENCY_SEQUENCE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5 - OFFSET, 1),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(1, 0),
})

local followCloningInstance
local UNFOLLOWING_PROPERTY_SET = {
	Parent = true,
	AbsolutePosition = true,
	AbsoluteSize = true,
	AbsoluteRotation = true,
}
function followCloningInstance(original: Instance)
	local cloned = original:Clone()

	original.Changed:Connect(function(property)
		pcall(function()
			if UNFOLLOWING_PROPERTY_SET[property] then
				return
			end
			cloned[property] = original[property]
		end)
	end)

	local clonedChildrenByOriginalChild = {}
	original.ChildAdded:Connect(function(child)
		local clonedChild = followCloningInstance(child)
		clonedChildrenByOriginalChild[child] = clonedChild
		clonedChild.Parent = cloned
	end)

	original.ChildRemoved:Connect(function(child)
		local clonedChild = clonedChildrenByOriginalChild[child]
		if clonedChild then
			clonedChild:Destroy()
			clonedChildrenByOriginalChild[child] = nil
		end
	end)

	return cloned
end

local function createPropChildrenContainer(positionX: number, childFolder: Instance)
	local clonedFolder = followCloningInstance(childFolder)
	clonedFolder.Visible = true

	-- followCloningInstance 는 자기 참조를 하는 시그널이 있어서
	-- 메모리 누수 방지를 위해 제거 시그널 연결
	clonedFolder.AncestryChanged:Connect(function(a0: Instance, a1: Instance?)
		if not a1 then
			clonedFolder:Destroy()
		end
	end)

	return create "Frame" {
		Size = UDim2.fromScale(2, 1),
		Position = UDim2.fromScale(positionX, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		clonedFolder,
	}
end

local function createGradient(
	offsetX: number,
	rotationFn: () -> number,
	transparencySequence: NumberSequence
)
	return Gradient({
		Transparency = transparencySequence,
		Offset = Vector2.new(offsetX, 0),
		Rotation = function()
			return rotationFn() * 360
		end,
	})
end

local function computeAngles(startProgress: number, endProgress: number)
	local delta = endProgress - startProgress

	local startProgressDecimal = startProgress % 1
	local endProgressDecimal = endProgress % 1

	local gradientAngleR1 = 0
	local gradientAngleR1_1 = 0
	local gradientAngleR2 = 0

	local gradientAngleL1 = 0
	local gradientAngleL1_1 = 0
	local gradientAngleL2 = 0

	local canvasGroupR1Visible = true
	local canvasGroupR2Visible = false
	local canvasGroupL1Visible = true
	local canvasGroupL2Visible = false

	if 1 <= delta then
		gradientAngleR1 = 0
		gradientAngleR1_1 = 0.5
		gradientAngleL1 = 0.5
		gradientAngleL1_1 = 1
	elseif delta <= 0 then
		gradientAngleR1 = 0.5
		gradientAngleR1_1 = 0.5
		gradientAngleL1 = 1
		gradientAngleL1_1 = 1
	elseif 1 <= startProgressDecimal + delta then
		if delta <= 0.5 then
			if startProgressDecimal <= 0.5 then
				-- Case1
				gradientAngleR1 = math.clamp(startProgressDecimal, 0, 0.5)
				gradientAngleR1_1 = 0.5
				gradientAngleL1 = 0.5
				gradientAngleL1_1 = math.clamp(endProgressDecimal, 0.5, 1)
			else
				-- Case2
				gradientAngleR1 = 0
				gradientAngleR1_1 = math.clamp(endProgressDecimal, 0, 0.5)
				gradientAngleL1 = math.clamp(startProgressDecimal, 0.5, 1)
				gradientAngleL1_1 = 1
			end
		else
			if startProgressDecimal <= 0.5 then
				-- Case3
				gradientAngleR1 = math.clamp(startProgressDecimal, 0, 0.5)
				gradientAngleR1_1 = 0.5
				gradientAngleL1 = math.clamp(startProgressDecimal, 0.5, 1)
				gradientAngleL1_1 = 1
				gradientAngleR2 = endProgressDecimal
				canvasGroupR2Visible = true
			else
				-- Case4
				gradientAngleR1 = 0
				gradientAngleR1_1 = math.clamp(endProgressDecimal, 0, 0.5)
				gradientAngleL1 = math.clamp(startProgressDecimal, 0.5, 1)
				gradientAngleL1_1 = 1
				gradientAngleL2 = endProgressDecimal
				canvasGroupL2Visible = true
			end
		end
	else
		-- Case0
		gradientAngleR1 = math.clamp(startProgressDecimal, 0, 0.5)
		gradientAngleR1_1 = math.clamp(endProgressDecimal, 0, 0.5)
		gradientAngleL1 = math.clamp(startProgressDecimal, 0.5, 1)
		gradientAngleL1_1 = math.clamp(endProgressDecimal, 0.5, 1)
	end

	return {
		gradientAngleR1 = gradientAngleR1,
		gradientAngleR1_1 = gradientAngleR1_1,
		gradientAngleR2 = gradientAngleR2,
		gradientAngleL1 = gradientAngleL1,
		gradientAngleL1_1 = gradientAngleL1_1,
		gradientAngleL2 = gradientAngleL2,
		canvasGroupR1Visible = canvasGroupR1Visible,
		canvasGroupR2Visible = canvasGroupR2Visible,
		canvasGroupL1Visible = canvasGroupL1Visible,
		canvasGroupL2Visible = canvasGroupL2Visible,
	}
end

local function CircularFrame(props: CircularFrameProps)
	local frameProps = table.clone(props)

	local propChildren = VideKitUtils.extractChildren(frameProps)

	local childFolder = create "Frame" {
		Name = "CircularFrameChildren",

		Size = UDim2.fromScale(1, 1),
		Visible = false,
		propChildren,
	}
	table.insert(frameProps, childFolder)

	frameProps.Class = frameProps.Class or "CanvasGroup"

	local function getStartProgress()
		local value = read(props.StartProgress)
		if value == nil then
			return 0
		end
		return value
	end

	local function getEndProgress()
		local value = read(props.EndProgress)
		if value == nil then
			return 1
		end
		return value
	end

	frameProps.StartProgress = nil
	frameProps.EndProgress = nil

	-- 한 번 계산된 각도 스냅샷을 모든 Gradient / Visible이 공유
	local anglesSignal = derive(function()
		local startProgress = getStartProgress()
		local endProgress = getEndProgress()
		return computeAngles(startProgress, endProgress)
	end)

	local function angles()
		return anglesSignal()
	end

	-- Right1 내부 StartProgressCanvas (React 구조 그대로)
	local startProgressCanvasRight1 = create "CanvasGroup" {
		Size = UDim2.fromScale(1, 1),
		Transparency = 1,

		createGradient(-0.5, function()
			return angles().gradientAngleR1_1
		end, CIRCLUAR_TRANSPARENCY_SEQUENCE),

		createPropChildrenContainer(-1, childFolder),
	}

	-- Right1 CanvasGroup (자식 순서: REVERSED → StartProgressCanvas, React와 동일)
	table.insert(
		frameProps,
		create "CanvasGroup" {
			Visible = function()
				return angles().canvasGroupR1Visible
			end,
			Size = UDim2.fromScale(0.5, 1),
			Position = UDim2.fromScale(0.5, 0),
			Transparency = 1,

			-- React와 같은 순서: REVERSED 먼저
			createGradient(-0.5, function()
				return angles().gradientAngleR1
			end, REVERSED_TRANSPARENCY_SEQUENCE),

			startProgressCanvasRight1,
		}
	)

	-- Right2
	table.insert(
		frameProps,
		create "CanvasGroup" {
			Visible = function()
				return angles().canvasGroupR2Visible
			end,
			Size = UDim2.fromScale(0.5, 1),
			Position = UDim2.fromScale(0.5, 0),
			Transparency = 1,

			createGradient(-0.5, function()
				return angles().gradientAngleR2
			end, CIRCLUAR_TRANSPARENCY_SEQUENCE),

			createPropChildrenContainer(-1, childFolder),
		}
	)

	-- Left1 내부 StartProgressCanvas
	local startProgressCanvasLeft1 = create "CanvasGroup" {
		Size = UDim2.fromScale(1, 1),
		Transparency = 1,

		createGradient(0.5, function()
			return angles().gradientAngleL1_1
		end, CIRCLUAR_TRANSPARENCY_SEQUENCE),

		createPropChildrenContainer(0, childFolder),
	}

	-- Left1 (React와 동일 구조/순서)
	table.insert(
		frameProps,
		create "CanvasGroup" {
			Visible = function()
				return angles().canvasGroupL1Visible
			end,
			Size = UDim2.fromScale(0.5, 1),
			Position = UDim2.fromScale(0, 0),
			Transparency = 1,

			createGradient(0.5, function()
				return angles().gradientAngleL1
			end, REVERSED_TRANSPARENCY_SEQUENCE),

			startProgressCanvasLeft1,
		}
	)

	-- Left2
	table.insert(
		frameProps,
		create "CanvasGroup" {
			Visible = function()
				return angles().canvasGroupL2Visible
			end,
			Size = UDim2.fromScale(0.5, 1),
			Position = UDim2.fromScale(0, 0),
			Transparency = 1,

			createGradient(0.5, function()
				return angles().gradientAngleL2
			end, CIRCLUAR_TRANSPARENCY_SEQUENCE),

			createPropChildrenContainer(0, childFolder),
		}
	)

	-- UIComponents는 마지막에 그대로 붙여줌
	table.insert(frameProps, props.UIComponents)
	frameProps.UIComponents = nil

	return Frame(frameProps)
end

return CircularFrame
