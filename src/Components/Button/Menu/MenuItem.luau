local TableUtil = require("../../../../roblox_packages/TableUtil")

local Types = require("../../../Types")
local SelectableButton = require("../../../Components/Button/SelectableButton")
local theme = require("../../../Contexts/Theme")

export type MenuItemProps = Types.props<SelectableButton.SelectableButtonProps>

local function MenuItem(props)
	local buttonProps = TableUtil.merge({}, {
		ButtonColor = function()
			return theme().MenuItem
		end,
		TextColor3 = function()
			return theme().MenuItemText
		end,
		SelectedColor = function()
			return theme().MenuItemSelected
		end,
		TextOnSelectedColor = function()
			return theme().MenuItemTextOnSelected
		end,
		HighlightColor = function()
			return theme().MenuItemHighlight
		end,
		HighlightOnSelectedColor = function()
			return theme().MenuItemHighlightOnSelected
		end,
		ClickEffectColor = function()
			return theme().MenuItemClickEffect
		end,
		IconColor = function()
			return theme().MenuItemIcon
		end,
		IconOnSelectedColor = function()
			return theme().MenuIconOnSelected
		end,
	})

	local item = props.Item

	buttonProps.Icon = item.Icon
	buttonProps.IsSelected = props.SelectedItem == item.Name
	buttonProps.Size = UDim2.fromOffset(16, 16)

	buttonProps.TextProps = {
		Text = item.Text or item.Name,
		TextTruncate = Enum.TextTruncate.None,
		Size = UDim2.new(0, 0, 1, 0),
	}

	buttonProps.AutomaticSize = Enum.AutomaticSize.X

	buttonProps.LayoutOrder = props.LayoutOrder
	buttonProps.OnSelect = props.OnSelect

	buttonProps.CornerRadius = props.CornerRaidus or 0.2
	
	buttonProps.UIComponents = nil

	return SelectableButton(buttonProps)
end

return MenuItem
