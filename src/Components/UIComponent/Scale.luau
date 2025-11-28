--[=[
    @class UIScaleWrapper
    @tag vide
]=]

local Types = require("../../Types")
local vide = require("../../../roblox_packages/vide")

local create = vide.create

export type ScaleProps = Types.props<{
	Scale: number,
}>

local function Scale(props: ScaleProps)
	return create "UIScale"(props)
end

return Scale
