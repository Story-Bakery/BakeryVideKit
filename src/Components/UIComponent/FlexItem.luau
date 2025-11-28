--[=[
    @class UIFlexItemWrapper
    @tag vide
]=]

local Types = require("../../Types")
local vide = require("../../../roblox_packages/vide")

local create = vide.create

export type FlexItemProps = Types.props<{
	FlexMode: Enum.UIFlexMode?,
	ItemLineAlignment: Enum.ItemLineAlignment?,
	GrowRatio: number?,
	ShrinkRatio: number?,
}>

local function FlexItem(props: FlexItemProps)
	return create "UIFlexItem"(props)
end

return FlexItem
