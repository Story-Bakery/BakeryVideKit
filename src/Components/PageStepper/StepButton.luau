local Types = require("../../Types")
local Button = require("../../Components/Button")
local AspectRatioConstraint = require("../../Components/UIComponent/AspectRatioConstraint")
local Padding = require("../../Components/UIComponent/Padding")
local TableUtil = require("../../../roblox_packages/TableUtil")

export type StepButtonProps = Types.props<Button.ButtonProps>



local stepFont = Font.fromName("Zekton")
stepFont.Bold = true
stepFont.Weight = Enum.FontWeight.Light

local function StepButton(props: StepButtonProps)
	local buttonProps = table.clone(props) :: Button.ButtonProps
	
	buttonProps.Size = buttonProps.Size or UDim2.fromScale(.05, .15)
	local textProps = TableUtil.merge({
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.None,
		FontFace = stepFont,
	}, props.TextProps)
	table.insert(textProps, Padding({
		Padding = UDim.new(.2, 0),
	}))
	buttonProps.TextProps = textProps
	buttonProps.CornerRadius = .2
	buttonProps.UIComponents = {
		AspectRatioConstraint = AspectRatioConstraint({
			AspectRatio = .2,
		}),
	}
	
	return Button(buttonProps)
end


return StepButton
