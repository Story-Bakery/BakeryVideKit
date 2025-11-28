--[=[
    @class UIListLayoutWrapper
    @tag vide
]=]

local Types = require("../../Types")
local TableUtil = require("../../../roblox_packages/TableUtil")
local vide = require("../../../roblox_packages/vide")

local create = vide.create

export type ListLayoutProps = Types.props<{
	Padding: number | UDim?,

	FillDirection: Enum.FillDirection?,
	HorizontalAlignment: Enum.HorizontalAlignment?,
	VerticalAlignment: Enum.VerticalAlignment?,
	SortOrder: Enum.SortOrder?,

	VerticalFlex: Enum.UIFlexAlignment?,
	HorizontalFlex: Enum.UIFlexAlignment?,
	ItemLineAlignment: Enum.ItemLineAlignment?,
}>

local function ListLayout(props: ListLayoutProps)
	local ListLayoutProps = TableUtil.merge({
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
	}, props)

	local Padding = props.Padding
	if Padding then
		if typeof(Padding) == "number" then
			ListLayoutProps.Padding = UDim.new(0, Padding)
		end
	end

	return create "UIListLayout"(ListLayoutProps)
end

return ListLayout
