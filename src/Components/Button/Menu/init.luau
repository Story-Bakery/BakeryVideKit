local vide = require("../../../../roblox_packages/vide")
local create = vide.create

local TableUtil = require("../../../../roblox_packages/TableUtil")
local Types = require("../../../Types")
local UserInputManager = require("../../../../roblox_packages/UserInputManager")

local Button = require("../../../Components/Button")
local SelectableButton = require("../../../Components/Button/SelectableButton")
local TextLabel = require("../../../Components/TextLabel")
local theme = require("../../../Contexts/Theme")

local MenuItemContainer = require(script.MenuItemContainer)

local EMPTY_TABLE = {}

export type MenuItemProps = {
	Name: string,
	Text: string?,
	IconContent: Content?,
}

export type Items =
	{ MenuItemProps }
	| {
		{
			Category: string,
			Text: string?,
			Items: { MenuItemProps },
		}
	}

export type MenuProps =
	Types.props<{
		OnItemSelect: (itemName: string) -> ()?,
		ExpandDirection: "Left" | "Right"?,

		Items: Items?,

		SelectedItem: string?,
	}>
	& SelectableButton.SelectableButtonProps

local function findItemIconFromItems(itemName: string, items: Items): string?
	local firstElement = items[1]
	if not firstElement then
		return nil
	end

	local isCategory = firstElement.Items ~= nil
	if isCategory then
		for i, category in items :: any do
			for j, item in category.Items do
				if item.Name == itemName then
					return item.IconContent
				end
			end
		end
	else
		for i, item in items :: any do
			if item.Name == itemName then
				return item.IconContent
			end
		end
	end

	return nil
end

local function Menu(props: MenuProps)
	local buttonProps = table.clone(props)
	local propChildren = {}
	for key, child in buttonProps do
		if type(key) == "number" then
			propChildren[key] = child
			buttonProps[key] = nil
		end
	end

	local isOpenMenu = props.IsSelected
	local menuTextFont = if isOpenMenu
		then Font.fromEnum(Enum.Font.SourceSansBold)
		else Font.fromEnum(Enum.Font.SourceSans)
	buttonProps.FontFace = menuTextFont

	-- render items
	local onItemSelect = props.OnItemSelect
	buttonProps.OnItemSelect = nil

	local items = props.Items or EMPTY_TABLE
	buttonProps.Items = nil

	local selectedItem = props.SelectedItem
	buttonProps.SelectedItem = nil
	local selectedIcon = findItemIconFromItems(selectedItem, items)

	local expandDirection = props.ExpandDirection or "Right"
	buttonProps.ExpandDirection = nil

	local itemContainer = MenuItemContainer({
		Position = if expandDirection == "Left"
			then UDim2.new(1, 0, 1, 2)
			else UDim2.new(0, 0, 1, 2),
		AnchorPoint = if expandDirection == "Left" then Vector2.new(1, 0) else Vector2.new(0, 0),
		IsOpen = isOpenMenu,
		Items = items,
		SelectedItem = selectedItem,
		OnItemSelect = onItemSelect,
		ZIndex = 500,
	})

	local menuOpenLabelProps = {
		Text = "v",
		FontFace = menuTextFont,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.new(1, -2, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		StrokeThickness = 0,
		BackgroundTransparency = 1,
		LayoutOrder = 300,

		create("UIAspectRatioConstraint")({
			AspectRatio = 1,
			AspectType = Enum.AspectType.FitWithinMaxSize,
		}),
		create("UISizeConstraint")({
			MaxSize = Vector2.new(32, 32),
		}),
	}
	local internalChildren = {
		create("Folder")({
			TextLabel(menuOpenLabelProps),
		}),
	}

	local mergedButtonProps = TableUtil.merge(
		{
			ButtonColor = function()
				return theme().Menu
			end,
			TextColor3 = function()
				return theme().MenuText
			end,
			SelectedColor = function()
				return theme().MenuSelected
			end,
			TextOnSelectedColor = function()
				return theme().MenuTextOnSelected
			end,
			HighlightColor = function()
				return theme().MenuHighlight
			end,
			HighlightOnSelectedColor = function()
				return theme().MenuHighlightOnSelected
			end,
			ClickEffectColor = function()
				return theme().MenuClickEffect
			end,
			IconColor = function()
				return theme().MenuIcon
			end,
			IconOnSelectedColor = function()
				return theme().MenuIconOnSelected
			end,

			IsSelected = isOpenMenu,

			TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = Enum.AutomaticSize.X,
		},
		buttonProps,
		{
			Text = selectedItem,
			Icon = selectedIcon,
			IconProps = {},
			InternalChildren = internalChildren,
		}
	)

	local buttonChildren = TableUtil.merge({}, propChildren)
	local itemContainerFolderProps = TableUtil.merge({}, itemContainer)
	buttonChildren.ItemContainerFolder = create("Folder")(itemContainerFolderProps)
	mergedButtonProps = TableUtil.merge(mergedButtonProps, buttonChildren)

	return SelectableButton(mergedButtonProps)
end

return Menu
