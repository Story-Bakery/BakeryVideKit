--[=[
    @class UICornerWrapper
    @tag vide
]=]

local Types = require("../../Types")
local vide = require("../../../roblox_packages/vide")

local create = vide.create

export type CornerProps = Types.props<{
	ConrerRadius: UDim,
}>

local function Corner(props: CornerProps)
	return create "UICorner"(props)
end

return Corner
