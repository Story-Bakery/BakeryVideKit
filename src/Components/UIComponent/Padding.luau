--[=[
    @class UIPaddingWrapper
    @tag vide
]=]

local Types = require("../../Types")
local vide = require("../../../roblox_packages/vide")

local create = vide.create

export type PaddingProps = Types.props<{
	PaddingTop: UDim | number?,
	PaddingBottom: UDim | number?,
	PaddingLeft: UDim | number?,
	PaddingRight: UDim | number?,
	Padding: UDim | number?,
}>

local function Padding(props: PaddingProps)
	local paddingProps = table.clone(props)
	local padding = props.Padding
	if padding then
		paddingProps.Padding = nil

		if typeof(padding) == "number" then
			padding = UDim.new(0, padding)
		end

		paddingProps.PaddingTop = paddingProps.PaddingTop or padding
		paddingProps.PaddingBottom = paddingProps.PaddingBottom or padding
		paddingProps.PaddingLeft = paddingProps.PaddingLeft or padding
		paddingProps.PaddingRight = paddingProps.PaddingRight or padding
	end

	if typeof(paddingProps.PaddingTop) == "number" then
		paddingProps.PaddingTop = UDim.new(0, paddingProps.PaddingTop)
	end
	if typeof(paddingProps.PaddingBottom) == "number" then
		paddingProps.PaddingBottom = UDim.new(0, paddingProps.PaddingBottom)
	end
	if typeof(paddingProps.PaddingLeft) == "number" then
		paddingProps.PaddingLeft = UDim.new(0, paddingProps.PaddingLeft)
	end
	if typeof(paddingProps.PaddingRight) == "number" then
		paddingProps.PaddingRight = UDim.new(0, paddingProps.PaddingRight)
	end

	return create "UIPadding"(paddingProps)
end

return Padding
