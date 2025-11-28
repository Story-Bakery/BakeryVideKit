local vide = require("../../../roblox_packages/vide")
local create = vide.create
local Types = require("../../Types")
local Maid = require("../../../roblox_packages/Maid")
local TableUtil = require("../../../roblox_packages/TableUtil")
local theme = require("../../Contexts/Theme")

export type ButtonIconProps = Types.props<{
	IconColor: Color3,
	IconContent: Content,
	Size: UDim2,
	Position: UDim2,
}>

local function ButtonIcon(props: ButtonIconProps)
	local labelProps = table.clone(props)

	local iconColor = props.IconColor or function()
		return theme().ButtonIcon
	end
	labelProps.IconColor = nil

	local iconContent = props.IconContent
	labelProps.IconContent = nil

	labelProps = TableUtil.merge({
		LayoutOrder = 0,
		BackgroundTransparency = 1,
		ImageColor3 = iconColor,
		ImageContent = iconContent,
		create "UIAspectRatioConstraint" {
			AspectRatio = 1,
			AspectType = Enum.AspectType.FitWithinMaxSize,
		},
	}, labelProps)

	return create "ImageLabel"(labelProps)
end

return ButtonIcon
