--[=[
    @class UIGridLayoutWrapper
    @tag vide
]=]

local Types = require("../../Types")
local vide = require("../../../roblox_packages/vide")

local create = vide.create

export type GridLayoutProps = Types.props<{
	SortOrder: Enum.SortOrder?,

	CellSize: UDim2?,
	CellPadding: UDim2?,

	FillDirection: Enum.FillDirection?,
	HorizontalAlignment: Enum.HorizontalAlignment?,
	VerticalAlignment: Enum.VerticalAlignment?,

	FillDirectionMaxCells: number?,

	StartCorner: Enum.StartCorner?,
}>

local function UIGridLayout(props: GridLayoutProps)
	return create "UIGridLayout"(props)
end

return UIGridLayout
