--[=[
    @class UIGradientWrapper
    @tag vide
]=]

local Types = require("../../Types")
local vide = require("../../../roblox_packages/vide")

local create = vide.create

export type GradientProps = Types.props<{
	Enabled: boolean?,
	Rotation: number?,
	Color: ColorSequence?,
	Transparency: NumberSequence?,
	Offset: Vector2?,
}>

local function Gradient(props: GradientProps)
	return create "UIGradient"(props)
end

return Gradient
