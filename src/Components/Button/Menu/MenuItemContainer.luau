local vide = require("../../../../roblox_packages/vide")

local Types = require("../../../Types")

local area = require("../../../Contexts/Area")
local DynamicTimer = require("../../../../roblox_packages/DynamicTimer")
local Frame = require("../../../Components/Frame")
local ListLayout = require("../../../Components/UIComponent/ListLayout")
local Padding = require("../../../Components/UIComponent/Padding")
local ScrollingFrame = require("../../../Components/ScrollingFrame")
local SizeConstraint = require("../../../Components/UIComponent/SizeConstraint")
local TableUtil = require("../../../../roblox_packages/TableUtil")
local TextLabel = require("../../../Components/TextLabel")
local UserInputManager = require("../../../../roblox_packages/UserInputManager")

local MenuItem = require(script.Parent.MenuItem)

local effect = vide.effect
local source = vide.source

local function createItemComponents(items, selectedItem, onItemSelect)
	local itemComponents = {}
	for j, item in items do
		local itemProps = table.clone(item)

		local itemName = item.Name
		itemProps.Name = nil

		itemComponents[itemName] = MenuItem(TableUtil.merge({
			Item = item,
			SelectedItem = selectedItem,
			LayoutOrder = j,
			OnSelect = function()
				onItemSelect(item.Name)
			end,
		}, itemProps))
	end
	return itemComponents
end

export type MenuItemContainerProps = Types.props<{
	IsOpen: boolean,
	Items: any,
	SelectedItem: any,
	OnItemSelect: () -> (),
}>

local function MenuItemContainer(props: MenuItemContainerProps)
	local frameProps = table.clone(props)

	local items = props.Items
	frameProps.Items = nil

	local selectedItem = props.SelectedItem
	frameProps.SelectedItem = nil

	local onItemSelect = props.OnItemSelect
	frameProps.OnItemSelect = nil

	local isCategory = false
	if items[1] and items[1].Category then
		isCategory = true
	end

	local containerChildren = {}
	containerChildren.SizeConstraint = SizeConstraint({
		MaxSize = Vector2.new(250, 250),
		MinSize = Vector2.new(0, 0),
	})

	local containerSize = source(UDim2.new())
	local lastContainerConn: RBXScriptConnection?
	local function containerRefCallback(newContainer: Frame?)
		if lastContainerConn then
			lastContainerConn:Disconnect()
			lastContainerConn = nil
		end

		if newContainer == nil then
			return
		end

		lastContainerConn = newContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			local absSize = newContainer.AbsoluteSize
			containerSize(UDim2.fromOffset(absSize.X, absSize.Y))
		end)

		local absSize = newContainer.AbsoluteSize
		containerSize(UDim2.fromOffset(absSize.X, absSize.Y))
	end

	if isCategory then
		containerChildren.CategoryListLayout = ListLayout({
			Padding = 5,
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Top,
		})

		for i, categoryInfo in items do
			local category = categoryInfo.Text or categoryInfo.Category
			local itemComponents =
				createItemComponents(categoryInfo.Items, selectedItem, onItemSelect)

			local categoryFrameProps = {
				Size = UDim2.fromScale(0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				LayoutOrder = i,
			}
			categoryFrameProps.CategoryName = TextLabel({
				Size = UDim2.fromOffset(16, 16),
				Text = category .. "\t",
				LayoutOrder = 0,
				AutomaticSize = Enum.AutomaticSize.X,
				StrokeEnabled = false,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			categoryFrameProps.ItemComponents = itemComponents
			categoryFrameProps.Padding = Padding({
				Padding = 5,
			})
			categoryFrameProps.ItemListLayout = ListLayout({
				Padding = 5,
				FillDirection = Enum.FillDirection.Vertical,
				VerticalAlignment = Enum.VerticalAlignment.Top,
			})
			containerChildren[`Category/{category}`] = Frame(categoryFrameProps)
		end
	else
		containerChildren.ItemListLayout = ListLayout({
			Padding = 5,
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalFlex = Enum.UIFlexAlignment.Fill,
			VerticalFlex = Enum.UIFlexAlignment.None,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
		})

		local itemComponents = createItemComponents(items, selectedItem, onItemSelect)
		containerChildren.ItemComponents = itemComponents
	end

	containerChildren.Padding = Padding({
		Padding = 5,
	})

	local isOpen = props.IsOpen
	frameProps.IsOpen = nil

	local openProgress = source(0)

	local lastSizeTween

	effect(function()
		if lastSizeTween then
			lastSizeTween:Destroy()
		end

		lastSizeTween = area().Timer:CreateDynamicTween({
			Start = openProgress(),
			Goal = if isOpen then 1 else 0,
			Duration = 0.2,
			Callback = function(value)
				openProgress(value)
			end,
			StepEvent = "RenderStepped",
		})
		lastSizeTween:Play()
	end)

	local scrollingFrameProps = TableUtil.merge({
		Size = (containerSize() + UDim2.fromOffset(15, 5)):Lerp(UDim2.new(), 1 - openProgress()),
		CanvasSize = (containerSize() + UDim2.fromOffset(5, 10)):Lerp(
			UDim2.new(),
			1 - openProgress()
		),
		Visible = 0 < openProgress(),
		CornerRadius = UDim.new(0, 2),
		ClipsDescendants = true,

		ScrollBarThickness = 2,
		ScrollingDirection = Enum.ScrollingDirection.XY,
	}, frameProps)
	scrollingFrameProps.ContainerChildren = containerChildren

	local containerToGetSizeProps = {
		ref = containerRefCallback,
		Transparency = 0,
		AutomaticSize = Enum.AutomaticSize.XY,
		Visible = false,
	}
	containerToGetSizeProps = TableUtil.merge(containerToGetSizeProps, containerChildren)

	return {
		ScrollingFrame = ScrollingFrame(scrollingFrameProps),
		ContainerToGetSize = Frame(containerToGetSizeProps),
	}
end

return MenuItemContainer
