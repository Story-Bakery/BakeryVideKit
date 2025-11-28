--[=[
	@class Slider
	@tag vide

	SelectableButton 기반 슬라이더 컴포넌트입니다. 마우스나 터치 드래그를 delta 값으로 변환해 상위로 전달합니다.
]=]

local RunService = game:GetService("RunService")

local vide = require("../../../../../roblox_packages/vide")
local source = vide.source

local Types = require("../../../../Types")
local TableUtil = require("../../../../../roblox_packages/TableUtil")
local UserInputManager = require("../../../../../roblox_packages/UserInputManager")

local Button = require("../../../../Components/Button")
local Frame = require("../../../../Components/Frame")
local ListLayout = require("../../../../Components/UIComponent/ListLayout")
local SelectableButton = require("../../../../Components/Button/SelectableButton")
local area = require("../../../../Contexts/Area")
local theme = require("../../../../Contexts/Theme")

export type SliderProps =
	Types.props<{
		OnSlideStart: () -> ()?,
		OnSlideEnd: () -> ()?,
		OnSlideMove: (delta: number) -> ()?,

		MouseIconPriority: number?,

		ShowStepControls: boolean?,
		OnStepClick: (step: number) -> ()?,
		StepScale: number?,

		SlideDirection: "X" | "Y"?,
	}>
	& SelectableButton.SelectableButtonProps

local function Slider(props: SliderProps)
	local buttonProps = table.clone(props)

	local userInputManager = area().UserInputManager
	local sliderButton
	local isDragging = false

	local mouseIconPriority = props.MouseIconPriority or 0
	buttonProps.MouseIconPriority = nil

	local showStepControls = props.ShowStepControls or false
	buttonProps.ShowStepControls = nil

	local onStepClick = props.OnStepClick
	buttonProps.OnStepClick = nil

	buttonProps.IsSelected = if props.IsSelected ~= nil then props.IsSelected else false

	local slideDirection = props.SlideDirection or "X"
	buttonProps.SlideDirection = nil

	local function getMouseProgress(instance: GuiObject): number
		local absoluteSize = instance.AbsoluteSize
		local mousePosition = userInputManager:GetMousePosition()

		if slideDirection == "Y" then
			if absoluteSize.Y == 0 then
				return 0
			end

			return -mousePosition.Y / absoluteSize.Y
		end

		if absoluteSize.X == 0 then
			return 0
		end

		return mousePosition.X / absoluteSize.X
	end
	local mouseIconId = if slideDirection == "Y"
		then UserInputManager.Enums.MouseIcons.SizeNS
		else UserInputManager.Enums.MouseIcons.SizeEW

	-- Slide 관련 콜백들은 내부에서 처리하므로 props에서 제거합니다.
	buttonProps.OnSlideStart = nil
	buttonProps.OnSlideEnd = nil
	buttonProps.OnSlideMove = nil

	buttonProps.OnSelect = function()
		if isDragging then
			return
		end

		isDragging = true

		if props.OnSlideStart then
			props.OnSlideStart()
		end

		local lastMouseProgress = getMouseProgress(sliderButton)
		local contextMouseIcon =
			userInputManager:GetMouse():AddContextMouseIcon(mouseIconId, mouseIconPriority)

		local function finishDrag()
			if not isDragging then
				return
			end

			isDragging = false

			if props.OnSlideEnd then
				props.OnSlideEnd()
			end

			if contextMouseIcon then
				contextMouseIcon:Destroy()
			end
		end

		while
			userInputManager:IsInputKeyPressed(
				Enum.UserInputType.MouseButton1,
				Enum.UserInputType.Touch
			)
		do
			local currentMouseProgress = getMouseProgress(sliderButton)
			local delta = currentMouseProgress - lastMouseProgress

			if
				userInputManager:IsInputKeyPressed(Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift)
			then
				delta *= 0.1
			end

			if props.OnSlideMove then
				props.OnSlideMove(delta)
			end

			lastMouseProgress = currentMouseProgress
			RunService.RenderStepped:Wait()
		end

		finishDrag()
	end

	buttonProps.SelectedColor = buttonProps.SelectedColor
		or function()
			return theme().SliderSelected
		end
	buttonProps.HighlightOnSelectedColor = buttonProps.HighlightOnSelectedColor
		or function()
			return theme().SliderHighlightOnSelected
		end

	local stepScale = props.StepScale or 1
	buttonProps.StepScale = nil

	if showStepControls then
		local containerProps = {
			BackgroundTransparency = 1,
			Size = props.Size,
			Position = props.Position,
			AnchorPoint = props.AnchorPoint,
			LayoutOrder = props.LayoutOrder,

			ListLayout({
				FillDirection = if slideDirection == "X"
					then Enum.FillDirection.Horizontal
					else Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			Button({
				Name = "DecreaseButton",

				Text = if slideDirection == "X" then "<" else "v",
				Size = if slideDirection == "X"
					then UDim2.new(0, 30, 1, 0)
					else UDim2.new(1, 0, 0, 30),
				LayoutOrder = if slideDirection == "X" then 1 else 3,
				OnClick = function()
					if onStepClick then
						onStepClick(-stepScale)
					end
				end,
			}),
			SelectableButton(TableUtil.merge(buttonProps, {
				Name = "SliderButton",

				Size = if slideDirection == "X"
					then UDim2.new(1, -60, 1, 0)
					else UDim2.new(1, 0, 1, -60),
				AnchorPoint = Vector2.zero,
				LayoutOrder = 2,
			})),

			Button({
				Name = "IncreaseButton",

				Text = if slideDirection == "X" then ">" else "^",
				Size = if slideDirection == "X"
					then UDim2.new(0, 30, 1, 0)
					else UDim2.new(1, 0, 0, 30),
				LayoutOrder = if slideDirection == "X" then 3 else 1,
				OnClick = function()
					if onStepClick then
						onStepClick(stepScale)
					end
				end,
			}),
		}

		sliderButton = Frame(containerProps)
	else
		sliderButton = SelectableButton(buttonProps)
	end

	return sliderButton
end

return Slider
