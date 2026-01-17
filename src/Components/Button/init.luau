--[=[
	@class Button
	@tag vide

	Button 컴포넌트 (vide 기반)
]=]

local vide = require("../../../roblox_packages/vide")
local Types = require("../../Types")
local TableUtil = require("../../../roblox_packages/TableUtil")
local DynamicTween = require("../../../roblox_packages/DynamicTween")
local LinearInterpolation = require("../../../roblox_packages/LinearInterpolation")

local area = require("../../Contexts/Area")
local theme = require("../../Contexts/Theme")

local Frame = require("../../Components/Frame")
local Padding = require("../../Components/UIComponent/Padding")
local ListLayout = require("../../Components/UIComponent/ListLayout")
local Scale = require("../../Components/UIComponent/Scale")

local ButtonIcon = require("./ButtonIcon")
local ButtonTextLabel = require("./ButtonTextLabel")
local ButtonTooltip = require("./ButtonTooltip")

local create = vide.create
local effect = vide.effect
local source = vide.source
local read = vide.read

export type ButtonProps = Types.props<{
	ButtonColor: Color3?,
	HighlightColor: Color3?,
	ClickEffectColor: Color3?,
	AutoScaleEnabled: boolean?,

	IconProps: ButtonIcon.ButtonIconProps?,
	Icon: string?, --@Deprecated
	IconContent: Content?,
	IconColor: Color3?,

	TextProps: ButtonTextLabel.ButtonTextLabelProps?,
	Text: string?,
	TextColor3: Color3?,
	TextHighlight: Color3?,
	TextSize: number?,
	TextTransparency: number?,
	TextXAlignment: Enum.TextXAlignment?,
	TextYAlignment: Enum.TextYAlignment?,
	TextScaled: boolean?,
	FontFace: Font?,

	OnClick: (inputObject: InputObject) -> ()?,
	OnEnter: () -> ()?,
	OnLeave: () -> ()?,
	OnMouseButton1Click: (inputObject: InputObject) -> ()?,
	OnMouseButton2Click: (inputObject: InputObject) -> ()?,
	OnMouseButton3Click: (inputObject: InputObject) -> ()?,
	OnTouch: (inputObject: InputObject) -> ()?,

	UIComponents: { any }?,
	InternalChildren: { any }?,

	TooltipText: string?,
}> & Frame.FrameProps



type ColorSource = (Color3?) -> Color3?

local ICON_PROP_KEYS = { "IconProps", "Icon", "IconContent", "IconColor" }
local TEXT_PROP_KEYS = {
	"TextProps",
	"Text",
	"TextColor3",
	"TextHighlight",
	"TextSize",
	"TextTransparency",
	"TextXAlignment",
	"TextYAlignment",
	"TextScaled",
	"FontFace",
}
local COLOR_PROP_KEYS = { "ButtonColor", "HighlightColor", "ClickEffectColor" }
local CHILD_COLLECTION_KEYS = { "InternalChildren", "UIComponents" }
local TOOLTIP_PROP_KEYS = { "TooltipText" }
local SCALE_PROP_KEYS = { "AutoScaleEnabled" }
local CALLBACK_PROP_KEYS = {
	"OnEnter",
	"OnLeave",
	"OnClick",
	"OnMouseButton1Click",
	"OnMouseButton2Click",
	"OnMouseButton3Click",
	"OnTouch",
}

local function discardProps(target, keys)
	for _, key in keys do
		target[key] = nil
	end
end

local function createIconChild(props: ButtonProps)
	if props.Icon == nil and props.IconProps == nil then
		return nil
	end

	return ButtonIcon(TableUtil.merge({
		IconContent = props.IconContent,
		IconColor = props.IconColor,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.fromScale(0, 0.5),
		AnchorPoint = Vector2.new(0, 0.5),
		LayoutOrder = 100,
	}, props.IconProps or {}))
end

local function createTextChild(props: ButtonProps, isHighlight)
	if props.Text == nil and props.TextProps == nil then
		return nil
	end

	return ButtonTextLabel(TableUtil.merge({
		Text = props.Text,
		TextColor3 = function()
			local theme = theme()
			local defaultColor = read(props.TextColor3) or theme.ButtonText
			local highlightColor = read(props.TextHighlight) or read(props.TextColor3) or theme.TextHighlight or defaultColor

			if isHighlight() then
				return highlightColor
			end

			return defaultColor
		end,
		LayoutOrder = 200,
		AutomaticSize = props.AutomaticSize,
		TextSize = props.TextSize,
		TextTransparency = props.TextTransparency,
		TextXAlignment = props.TextXAlignment,
		TextYAlignment = props.TextYAlignment,
		TextScaled = props.TextScaled,
		FontFace = props.FontFace,
	}, props.TextProps or {}))
end

type TooltipController = {
	Node: any,
	onEnter: () -> (),
	onLeave: () -> (),
}

local function createTooltipController(tooltipText: string?, parentInstance: Instance?)
	if tooltipText == nil then
		return nil
	end

	local showTooltip = source(false)
	local tooltipHovered = source(false)

	local function onMouseEnterTooltip()
		tooltipHovered(true)
		task.delay(1, function()
			if tooltipHovered() then
				showTooltip(true)
			end
		end)
	end

	local function onMouseLeaveTooltip()
		tooltipHovered(false)
		showTooltip(false)
	end

	local tooltipProps = {} :: ButtonTooltip.ButtonTooltipProps
	tooltipProps.Text = tooltipText
	tooltipProps.ParentSource = function()
		return parentInstance
	end
	tooltipProps.Visible = showTooltip()

	return {
		Node = ButtonTooltip(tooltipProps),
		onEnter = onMouseEnterTooltip,
		onLeave = onMouseLeaveTooltip,
	}
end

type HighlightAnimatorParams = {
	ButtonColor: () -> Color3,
	HighlightColor: () -> Color3,
	BackgroundColor: ColorSource,
}

local function createHighlightAnimator(params: HighlightAnimatorParams)
	local colorTween: DynamicTween.DynamicTween
	local state = source("Default")
	local buttonColor = source(params.ButtonColor())
	local highlightColor = source(params.HighlightColor())

	effect(function()
		buttonColor(params.ButtonColor())
		highlightColor(params.HighlightColor())

		if colorTween and colorTween.IsPlaying then
			return
		end

		local initialColor = if state() == "Default" then buttonColor() else highlightColor()

		params.BackgroundColor(initialColor)
	end)

	local function tweenTo(nextState: "Default" | "Highlight")
		if colorTween then
			colorTween:Destroy()
		end

		local startColor = params.BackgroundColor()
		local goalColor = if nextState == "Highlight" then highlightColor() else buttonColor()

		colorTween = area().Timer:CreateDynamicTween({
			Duration = 0.1,
			Callback = function(progress)
				params.BackgroundColor(LinearInterpolation.Color3(startColor, goalColor, progress))
			end,
		})
		colorTween:Play()
		state(nextState)
	end

	return {
		enter = function()
			tweenTo("Highlight")
		end,
		leave = function()
			tweenTo("Default")
		end,
	}
end

local SCALE_TARGETS = table.freeze({
	Default = 1,
	Hover = 1.05,
	Pressed = 0.95,
})

local function createScaleAnimator(isEnabled: boolean?)
	local scaleValue = source(SCALE_TARGETS.Default)

	if isEnabled == false then
		local function noop() end

		return {
			Scale = scaleValue,
			enterHover = noop,
			leaveHover = noop,
			pressBegin = noop,
			pressEnd = noop,
		}
	end

	local tween: DynamicTween.DynamicTween
	local isHovered = false
	local isPressed = false

	local function tweenTo(target: number)
		if tween then
			tween:Destroy()
		end

		local startValue = scaleValue()

		tween = DynamicTween.new({
			Start = startValue,
			Goal = target,
			Duration = 0.2,
			Callback = function(value)
				scaleValue(value)
			end,
		})
		tween:Play()
	end

	local function updateScale()
		local target = SCALE_TARGETS.Default
		if isPressed then
			target = SCALE_TARGETS.Pressed
		elseif isHovered then
			target = SCALE_TARGETS.Hover
		end

		tweenTo(target)
	end

	return {
		Scale = scaleValue,
		enterHover = function()
			isHovered = true
			updateScale()
		end,
		leaveHover = function()
			isHovered = false
			updateScale()
		end,
		pressBegin = function()
			isPressed = true
			updateScale()
		end,
		pressEnd = function()
			isPressed = false
			updateScale()
		end,
	}
end

local function extractContainerProps(frameProps)
	local containerProps = {
		Name = frameProps.Name,
		Parent = frameProps.Parent,
		Size = frameProps.Size or UDim2.fromScale(1, 1),
		Position = frameProps.Position,
		AnchorPoint = frameProps.AnchorPoint,
		AutomaticSize = frameProps.AutomaticSize,
		LayoutOrder = frameProps.LayoutOrder,
		SizeConstraint = frameProps.SizeConstraint,
		Visible = frameProps.Visible,
		ZIndex = frameProps.ZIndex,
	}

	frameProps.Name = nil
	frameProps.Parent = nil
	frameProps.Size = nil
	frameProps.Position = nil
	frameProps.AnchorPoint = nil
	frameProps.LayoutOrder = nil
	frameProps.SizeConstraint = nil

	return containerProps
end

local function applyFrameDefaults(frameProps, backgroundColor)
	return TableUtil.merge(
		{
			Class = "ImageButton",
			Size = UDim2.new(1, 0, 1, 0),
		},
		frameProps,
		{
			BackgroundColor3 = backgroundColor,
		}
	)
end

local function insertChildIfPresent(target, child)
	if child == nil then
		return
	end

	table.insert(target, child)
end

local function createInternalChildren(props: ButtonProps, isHighlight, tooltipController: TooltipController?)
	local internalChildren = {}

	local iconChild = createIconChild(props)
	if iconChild then
		table.insert(internalChildren, iconChild)
	end

	local textChild = createTextChild(props, isHighlight)
	if textChild then
		table.insert(internalChildren, textChild)
	end

	if tooltipController then
		table.insert(internalChildren, tooltipController.Node)
	end

	table.insert(
		internalChildren,
		ListLayout({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = 2,
		})
	)
	table.insert(
		internalChildren,
		Padding({
			Padding = 1,
		})
	)

	insertChildIfPresent(internalChildren, props.InternalChildren)
	insertChildIfPresent(internalChildren, props.UIComponents)

	return internalChildren
end

local function addInternalChildren(frameProps, internalChildren)
	local internalChildrenFrameProps = TableUtil.merge({
		Size = UDim2.fromScale(1, 1),
		Transparency = 1,
	}, internalChildren)
	table.insert(frameProps, create("Frame")(internalChildrenFrameProps))
end

local function seperateChildrenIntoFolder(frameProps)
	local children = { table.unpack(frameProps) }

	local propChildrenFrameProps = TableUtil.merge({
		Size = UDim2.fromScale(1, 1),
		Transparency = 1,
		BorderSizePixel = 0,
	}, children)
	table.insert(frameProps, create("Frame")(propChildrenFrameProps))
end

type ClickEffectController = {
	Folder: any,
	play: (Vector3) -> (),
}

type ClickEffectControllerParams = {
	ClickEffectColor: () -> Color3,
	ClickEffectImage: () -> string?,
	ClickEffectTransparency: () -> number,
}

local function createClickEffectController(params: ClickEffectControllerParams): ClickEffectController
	local container = create("ScrollingFrame")({
		Transparency = 1,
		ClipsDescendants = true,
		ScrollingEnabled = false,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
	})

	local folder = create("Folder")({
		Name = "ScrollingFolder",
		container,
	})

	local function play(position: Vector3)
		local clickEffect = Instance.new("ImageLabel")
		clickEffect.BackgroundTransparency = 1
		clickEffect.Size = UDim2.new(0, 0, 0, 0)
		clickEffect.AnchorPoint = Vector2.new(0.5, 0.5)
		clickEffect.Image = params.ClickEffectImage()
		clickEffect.ImageColor3 = params.ClickEffectColor()
		clickEffect.ImageTransparency = params.ClickEffectTransparency()
		clickEffect.ScaleType = Enum.ScaleType.Fit
		clickEffect.Parent = container

		local buttonPos = container.AbsolutePosition
		local buttonSize = container.AbsoluteSize

		local largestSize = math.max(buttonSize.X, buttonSize.Y) * math.pi / 2 / area().ResolutionScale

		clickEffect.Position = UDim2.fromOffset(
			(position.X - buttonPos.X) / area().ResolutionScale,
			(position.Y - buttonPos.Y) / area().ResolutionScale
		)

		area().Timer
			:CreateDynamicTweenFromInstance(clickEffect, {
				Duration = 0.5,
				EasingStyle = "Sine",
			}, {
				Size = UDim2.fromOffset(largestSize, largestSize),
				ImageTransparency = 1,
			})
			:Play()

		task.delay(0.5, function()
			clickEffect:Destroy()
		end)
	end

	return {
		Folder = folder,
		play = play,
	}
end

local function createMouseEnterHandler(params)
	return function()
		if params.MouseEnterCallback then
			params.MouseEnterCallback()
		end

		if params.OnEnter then
			task.spawn(params.OnEnter)
		end

		if params.TooltipController then
			params.TooltipController.onEnter()
		end

		params.IsHighlight(true)
		params.HighlightAnimator.enter()
		params.ScaleAnimator.enterHover()
	end
end

local function createMouseLeaveHandler(params)
	return function()
		if params.MouseLeaveCallback then
			params.MouseLeaveCallback()
		end

		if params.OnLeave then
			task.spawn(params.OnLeave)
		end

		if params.TooltipController then
			params.TooltipController.onLeave()
		end

		params.IsHighlight(false)
		params.HighlightAnimator.leave()
		params.ScaleAnimator.leaveHover()
	end
end

local function createInputBeganHandler(params)
	return function(inputObject)
		if params.InputBeganCallback then
			params.InputBeganCallback(inputObject)
		end

		local userInputType = inputObject.UserInputType
		local isClick = userInputType == Enum.UserInputType.MouseButton1
			or userInputType == Enum.UserInputType.MouseButton2
			or userInputType == Enum.UserInputType.MouseButton3
			or userInputType == Enum.UserInputType.Touch

		local userInputManager = params.UserInputManager

		-- 로블록스 버튼의 InputBegan 은 아래에 가려진 프레임들의 InputBegan 가 발동되지 않게 함
		-- 그렇다고 버튼으로 안하면 아래에 있는 프레임도 터치 감지돼서 여러 버튼이 동시 발동될 위험이 있음
		-- 그래서 버튼 내부에서 터치를 감지하여 처리해줌, 좋은 방법은 아니지만 이거 말곤 방법 없는 듯
		local isPressedStateChanged = userInputManager:_setInputKeyPressed(userInputType, true)
		if isPressedStateChanged then
			inputObject:GetPropertyChangedSignal("UserInputState"):Once(function()
				userInputManager:_setInputKeyPressed(inputObject.UserInputType, false)
			end)
		end

		if not isClick then
			return
		end

		params.ScaleAnimator.pressBegin()

		if params.OnClick then
			task.defer(params.OnClick, inputObject)
		end

		task.defer(params.PlayClickEffect, inputObject.Position)

		if userInputType == Enum.UserInputType.MouseButton1 then
			if params.OnMouseButton1Click then
				task.defer(params.OnMouseButton1Click, inputObject)
			end
		elseif userInputType == Enum.UserInputType.MouseButton2 then
			if params.OnMouseButton2Click then
				task.defer(params.OnMouseButton2Click, inputObject)
			end
		elseif userInputType == Enum.UserInputType.MouseButton3 then
			if params.OnMouseButton3Click then
				task.defer(params.OnMouseButton3Click, inputObject)
			end
		elseif userInputType == Enum.UserInputType.Touch then
			if params.OnTouch then
				task.defer(params.OnTouch, inputObject)
			end
		end

		inputObject:GetPropertyChangedSignal("UserInputState"):Once(function()
			params.ScaleAnimator.pressEnd()
		end)
	end
end

local function Button(props: ButtonProps, forwardRef)
	local frameProps = table.clone(props)

	local function getButtonColor()
		return read(props.ButtonColor) or theme().Button
	end
	local function getHighlightColor()
		return read(props.HighlightColor) or theme().ButtonHighlight
	end
	local function getClickEffectColor()
		return read(props.ClickEffectColor) or theme().ButtonClickEffect
	end
	local function getClickEffectImage()
		return theme().ButtonClickEffectImage
	end
	local function getClickEffectTransparency()
		return theme().ButtonClickEffectTransparency
	end

	local backgroundColor = source(getButtonColor())
	local isHighlight = source(false)
	local autoScaleEnabledValue = read(props.AutoScaleEnabled)
	local isAutoScaleEnabled = if autoScaleEnabledValue == nil then true else autoScaleEnabledValue
	local scaleAnimator = createScaleAnimator(isAutoScaleEnabled)

	discardProps(frameProps, COLOR_PROP_KEYS)
	discardProps(frameProps, ICON_PROP_KEYS)
	discardProps(frameProps, TEXT_PROP_KEYS)
	discardProps(frameProps, CHILD_COLLECTION_KEYS)
	discardProps(frameProps, TOOLTIP_PROP_KEYS)
	discardProps(frameProps, SCALE_PROP_KEYS)

	local highlightAnimator = createHighlightAnimator({
		ButtonColor = getButtonColor,
		HighlightColor = getHighlightColor,
		BackgroundColor = backgroundColor,
	})

	local clickEffectController = createClickEffectController({
		ClickEffectColor = getClickEffectColor,
		ClickEffectImage = getClickEffectImage,
		ClickEffectTransparency = getClickEffectTransparency,
	})

	local tooltipController = createTooltipController(props.TooltipText, clickEffectController.Folder)
	local internalChildren = createInternalChildren(props, isHighlight, tooltipController)

	frameProps = applyFrameDefaults(frameProps, backgroundColor)
	if isAutoScaleEnabled then
		table.insert(
			frameProps,
			Scale({
				Scale = scaleAnimator.Scale,
			})
		)
	end

	addInternalChildren(frameProps, internalChildren)
	table.insert(frameProps, clickEffectController.Folder)
	seperateChildrenIntoFolder(frameProps)

	local onEnter = props.OnEnter
	local onLeave = props.OnLeave
	local onClick = props.OnClick
	local onMouseButton1Click = props.OnMouseButton1Click
	local onMouseButton2Click = props.OnMouseButton2Click
	local onMouseButton3Click = props.OnMouseButton3Click
	local onTouch = props.OnTouch

	discardProps(frameProps, CALLBACK_PROP_KEYS)

	local mouseEnterCallback = (props :: any).MouseEnter
	local mouseLeaveCallback = (props :: any).MouseLeave
	local inputBeganCallback = (props :: any).InputBegan

	frameProps.MouseEnter = createMouseEnterHandler({
		MouseEnterCallback = mouseEnterCallback,
		OnEnter = onEnter,
		TooltipController = tooltipController,
		IsHighlight = isHighlight,
		HighlightAnimator = highlightAnimator,
		ScaleAnimator = scaleAnimator,
	})

	frameProps.MouseLeave = createMouseLeaveHandler({
		MouseLeaveCallback = mouseLeaveCallback,
		OnLeave = onLeave,
		TooltipController = tooltipController,
		IsHighlight = isHighlight,
		HighlightAnimator = highlightAnimator,
		ScaleAnimator = scaleAnimator,
	})

	frameProps.InputBegan = createInputBeganHandler({
		InputBeganCallback = inputBeganCallback,
		UserInputManager = area().UserInputManager,
		OnClick = onClick,
		OnMouseButton1Click = onMouseButton1Click,
		OnMouseButton2Click = onMouseButton2Click,
		OnMouseButton3Click = onMouseButton3Click,
		OnTouch = onTouch,
		PlayClickEffect = clickEffectController.play,
		ScaleAnimator = scaleAnimator,
	})

	local containerProps = extractContainerProps(frameProps)

	frameProps.Size = UDim2.fromScale(1, 1)
	frameProps.Position = UDim2.fromScale(0.5, 0.5)
	frameProps.AnchorPoint = Vector2.new(0.5, 0.5)

	if containerProps.Name then
		frameProps.Name = `${containerProps.Name}_Button`
	end

	if forwardRef and frameProps.ref == nil then
		frameProps.ref = forwardRef
	end

	local buttonInstance = Frame(frameProps)

	local containerFrameProps = TableUtil.merge({
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, containerProps, { buttonInstance })

	return create("Frame")(containerFrameProps)
end

return Button
