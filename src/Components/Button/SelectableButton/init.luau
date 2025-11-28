local RunService = game:GetService("RunService")

local vide = require("../../../../roblox_packages/vide")

local DynamicTween = require("../../../../roblox_packages/DynamicTween")
local LinearInterpolation = require("../../../../roblox_packages/LinearInterpolation")
local MathUtil = require("../../../../roblox_packages/MathUtil")
local TableUtil = require("../../../../roblox_packages/TableUtil")
local Types = require("../../../Types")
local UserInputManager = require("../../../../roblox_packages/UserInputManager")

local Button = require("../../../Components/Button")
local theme = require("../../../Contexts/Theme")

local effect = vide.effect
local source = vide.source
local read = vide.read

export type SelectableButtonProps =
	Types.props<{

		IsSelected: boolean?,
		OnSelect: (currentSelected: boolean) -> ()?,

		SelectedColor: Color3?,
		TextOnSelectedColor: Color3?,
		HighlightOnSelectedColor: Color3?,

		IconOnSelectedColor: Color3?,
	}>
	& Button.ButtonProps

local function SelectableButton(props: SelectableButtonProps)
	local buttonProps = table.clone(props)

	local isSelected = props.IsSelected
	buttonProps.IsSelected = nil

	local onSelect = props.OnSelect
	buttonProps.OnSelect = nil

	local function getDefaultButtonColor()
		return read(props.ButtonColor) or theme().Button
	end

	local function getDefaultHighlightColor()
		return read(props.HighlightColor) or theme().ButtonHighlight
	end

	local function getSelectedColor()
		return read(props.SelectedColor) or theme().ButtonSelected
	end

	buttonProps.SelectedColor = nil

	local function getTextOnSelectedColor()
		return read(props.TextOnSelectedColor) or theme().ButtonTextOnSelected
	end

	buttonProps.TextOnSelectedColor = nil

	local function getHighlightOnSelectedColor()
		return read(props.HighlightOnSelectedColor) or theme().ButtonHighlightOnSelected
	end

	buttonProps.HighlightOnSelectedColor = nil

	local function getIconOnSelectedColor()
		return read(props.IconOnSelectedColor) or theme().ButtonIconOnSelected
	end
	buttonProps.IconOnSelectedColor = nil

	local buttonColor = source(getDefaultButtonColor())
	local highlightColor = source(getDefaultHighlightColor())

	local selectTweenColorTween: DynamicTween.DynamicTween

	--#region Select Tween
	local function tweenButtonColorOnSelectedChanged(isSelectedValue: boolean)
		if selectTweenColorTween then
			selectTweenColorTween:Destroy()
		end

		local startButtonColor = buttonColor()
		local startHighlightColor = highlightColor()
		local goalButtonColor, goalHighlightColor
		if isSelectedValue then
			goalButtonColor = getSelectedColor()
			goalHighlightColor = getHighlightOnSelectedColor()
		else
			goalButtonColor = getDefaultButtonColor()
			goalHighlightColor = getDefaultHighlightColor()
		end

		selectTweenColorTween = DynamicTween.new({
			Duration = 0.1,
			Callback = function(p)
				buttonColor(LinearInterpolation.Color3(startButtonColor, goalButtonColor, p))

				highlightColor(
					LinearInterpolation.Color3(startHighlightColor, goalHighlightColor, p)
				)
			end,
		})
		selectTweenColorTween:Play()
	end

	effect(function()
		-- theme dependencies
		getDefaultButtonColor()
		getDefaultHighlightColor()
		getSelectedColor()
		getHighlightOnSelectedColor()
		tweenButtonColorOnSelectedChanged(read(isSelected))
	end)

	buttonProps.OnClick = function(inputObject)
		local onClickOnProps = props.OnClick
		if onClickOnProps then
			onClickOnProps(inputObject)
		end

		if onSelect then
			onSelect(read(isSelected))
		end
	end

	local mergedButtonProps = TableUtil.merge(buttonProps, {
		ButtonColor = buttonColor,
		TextColor3 = function()
			return if isSelected then getTextOnSelectedColor() else nil
		end,
		HighlightColor = highlightColor,
		IconColor = function()
			return if isSelected then getIconOnSelectedColor() else nil
		end,
	})

	return Button(mergedButtonProps)
end

return SelectableButton
