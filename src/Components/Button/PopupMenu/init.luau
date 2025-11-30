local vide = require("../../.././roblox_packages/vide")

local DynamicTween = require("../../.././roblox_packages/DynamicTween")
local LinearInterpolation = require("../../.././roblox_packages/LinearInterpolation")
local MathUtil = require("../../.././roblox_packages/MathUtil")
local TableUtil = require("../../.././roblox_packages/TableUtil")
local Types = require("../.././Types")
local UserInputManager = require("../../.././roblox_packages/UserInputManager")

local Button = require("../.././Components/Button")
local Frame = require("../.././Components/Frame")
local ListLayout = require("../.././Components/UIComponent/ListLayout")
local ScrollingFrame = require("../.././Components/ScrollingFrame")
local SizeConstraint = require("../.././Components/UIComponent/SizeConstraint")
local TextLabel = require("../.././Components/TextLabel")
local theme = require("../.././Contexts/Theme")

local source = vide.source
local create = vide.create

-- 기본 상수값들
local DEFAULT_BUTTON_HEIGHT = 22 -- 각 버튼의 높이
local DEFAULT_LINE_HEIGHT = 3 -- 구분선 높이
local DEFAULT_CATEGORY_HEIGHT = 15 -- 구분 텍스트 높이
local MOUSE_HOVER_DELAY = 0.2 -- 마우스가 머문 시간 (초)

export type PopupMenuButtonProps = {
	Name: string,
	Text: string?,
	Tooltip: string?,
	Icon: string?,
	OnClick: ((inputObject: InputObject) -> ())?,
	Buttons: { PopupMenuButtonProps }?,
	Type: "Button" | "Line" | "Category"?,
}

export type ExpandDirection = "Right" | "Left"
export type ScrollDirection = "Up" | "Down"

export type PopupMenuProps =
	Types.props<{
		Buttons: { PopupMenuButtonProps },
		OnButtonSelected: ((selectedName: string) -> ())?,
		ExpandDirection: ExpandDirection?,
		ScrollDirection: ScrollDirection?,
		Size: UDim2,
	}>
	& Frame.FrameProps

--#1 MenuButton
type MenuButtonProps = {
	OnButtonSelected: ((selectedName: string) -> ())?,
	UpdateOpenPath: (level: number, index: number, buttonSource: () -> GuiBase2d?) -> (),
	Level: number,
	Index: number,
	ExpandDirection: ExpandDirection,
} & PopupMenuButtonProps

local function MenuButton(props: MenuButtonProps)
	local onButtonSelected = props.OnButtonSelected
	local updateOpenPath = props.UpdateOpenPath
	local level = props.Level
	local index = props.Index
	local expandDirection = props.ExpandDirection

	local buttonText = props.Text
	if not buttonText and not props.Icon then
		buttonText = props.Name
	end

	local icon = props.Icon
	local buttonChildren = {}
	if props.Buttons and not icon then
		buttonChildren.ExpandIcon = TextLabel({
			Size = UDim2.fromOffset(DEFAULT_BUTTON_HEIGHT, DEFAULT_BUTTON_HEIGHT),
			BackgroundTransparency = 1,
			Position = if expandDirection == "Right"
				then UDim2.fromScale(1, 0.5)
				else UDim2.fromScale(0, 0.5),
			AnchorPoint = if expandDirection == "Right"
				then Vector2.new(1, 0.5)
				else Vector2.new(0, 0.5),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Center,
			Text = if expandDirection == "Right" then ">" else "<",
		})
	end

	local hoverTimer = source(nil :: thread?)
	local buttonInstance

	local function onMouseEnter(inputObject)
		if props.Buttons then
			hoverTimer(task.delay(MOUSE_HOVER_DELAY, function()
				updateOpenPath(level, index, buttonInstance)
			end))
		else
			updateOpenPath(level, index, buttonInstance)
		end
	end
	local function onMouseLeave(inputObject)
		local timer = hoverTimer()
		if timer then
			task.cancel(timer)
			hoverTimer(nil)
		end
	end
	local function onMenuItemClicked(inputObject)
		if props.OnClick then
			props.OnClick(inputObject)
		end
		if not props.Buttons and onButtonSelected then
			onButtonSelected(props.Name)
		end
		updateOpenPath(level, index, buttonInstance)
	end

	local buttonProps = {
		Text = buttonText,
		Icon = icon,
		Tooltip = props.Tooltip,
		Size = UDim2.new(1, 0, 0, DEFAULT_BUTTON_HEIGHT),
		LayoutOrder = index,
		OnClick = onMenuItemClicked,
		OnEnter = onMouseEnter,
		OnLeave = onMouseLeave,
	}

	if next(buttonChildren) ~= nil then
		buttonProps = TableUtil.merge(buttonProps, buttonChildren)
	end

	buttonInstance = Button(buttonProps)
	return buttonInstance
end

--------------------------------------------------------------------------------
--#1 MenuLevel
-- 각 메뉴 레벨은 스크롤 가능한 ScrollingFrame 내부에 렌더링되며,
-- 레벨 1은 즉시 표시되고, 레벨 2 이상은 열릴 때 0.5초, 닫힐 때 0.2초 트윈 애니메이션을 적용합니다.
-- 메뉴 높이는 PopupMenu의 Size.Y에서 메뉴 레벨 컨테이너의 AbsolutePosition.Y를 뺀 값으로 동적으로 계산됩니다.
-- 메뉴 레벨의 위치는 부모 버튼(메뉴를 연 버튼)의 AbsolutePosition.Y에 맞춰 설정됩니다.
--------------------------------------------------------------------------------
export type MenuLevelProps = Types.props<{
	Level: number,
	Items: { any },
	ExpandDirection: ExpandDirection?,
	ScrollDirection: ScrollDirection?,
	UpdateOpenPath: (level: number, index: number, buttonSource: () -> GuiBase2d?) -> (),
	OnButtonSelected: ((selectedName: string) -> ())?,
	ParentFrameSource: () -> Frame?,
	MenuFrameSource: () -> Frame?,
}>

local function MenuLevel(props: MenuLevelProps)
	local level = props.Level
	local items = props.Items
	local expandDirection = props.ExpandDirection or "Right"
	local scrollDirection = props.ScrollDirection or "Up"
	local updateOpenPath = props.UpdateOpenPath
	local onButtonSelected = props.OnButtonSelected

	local parentFrameSource = props.ParentFrameSource
	local menuFrameSource = props.MenuFrameSource
	local parentFrame: Frame = parentFrameSource()
	local menuFrame: Frame = menuFrameSource()

	if parentFrame == nil or menuFrame == nil then
		return
	end

	-- PopupMenu의 Size.Y에서 이 MenuLevel 컨테이너의 AbsolutePosition.Y를 뺀 값으로 계산합니다.
	local frameSource = source(nil :: Frame?)

	local position = source(UDim2.new())
	local maxSize = source(Vector2.zero)

	vide.effect(function()
		local currentFrame = frameSource()
		if currentFrame == nil then
			return
		end

		local function update()
			local parentRelativePosition = parentFrame.AbsolutePosition.Y
				- menuFrame.AbsolutePosition.Y

			local nextPosition = UDim2.fromOffset(0, parentRelativePosition)

			if level == 1 then
				nextPosition = UDim2.fromScale(0, 0)
			end

			local nextMaxSize = Vector2.new(
				parentFrame.AbsoluteSize.X * 2,
				parentFrame.AbsoluteSize.Y
					- (currentFrame.AbsolutePosition.Y - parentFrame.AbsolutePosition.Y)
			)

			position(nextPosition)
			maxSize(nextMaxSize)
		end

		update()
		local conn1 = currentFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(update)
		local conn2 = currentFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
		local conn3 = parentFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(update)
		local conn4 = parentFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
		vide.cleanup(function()
			conn1:Disconnect()
			conn2:Disconnect()
			conn3:Disconnect()
			conn4:Disconnect()
		end)
	end)

	local menuItems = {}
	for i, item in ipairs(items) do
		if item.Type == "Line" then
			menuItems[i] = Frame(TableUtil.merge({}, {
				Size = UDim2.new(1, 0, 0, DEFAULT_LINE_HEIGHT),
				BackgroundColor3 = function()
					return theme().PopupMenuItemLine
				end,
				LayoutOrder = i,
			}))
		elseif item.Type == "Category" then
			menuItems[i] = TextLabel({
				Text = item.Text or "",
				Size = UDim2.new(1, 0, 0, DEFAULT_CATEGORY_HEIGHT),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				LayoutOrder = i,
			})
		else -- "Button" (기본값)
			menuItems[i] = MenuButton(TableUtil.merge(item, {
				OnButtonSelected = onButtonSelected,
				UpdateOpenPath = updateOpenPath,
				ExpandDirection = expandDirection,
				Level = level,
				Index = i,
			}))
		end
	end

	-- 전체 높이가 parentSize.Y를 초과하면 스크롤 가능하도록 합니다.
	local scrollingFrameChildren = {
		ListLayout({
			FillDirection = Enum.FillDirection.Vertical,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Padding = 0,
		}),
	}
	scrollingFrameChildren = TableUtil.merge(scrollingFrameChildren, menuItems)

	local scrollingFrameProps = TableUtil.merge({}, {
		BackgroundTransparency = 1,
		ScrollBarThickness = 2,
		Size = UDim2.new(1, 1, 0, 0),
		Position = function()
			return position()
		end,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		AutomaticSize = Enum.AutomaticSize.XY,
		CanvasSize = UDim2.new(),
		Transparency = 1,
	})
	scrollingFrameProps = TableUtil.merge(scrollingFrameProps, scrollingFrameChildren)

	local scrollingFrame = ScrollingFrame(scrollingFrameProps)

	local levelFrameProps = {
		ref = function(frame)
			frameSource(frame)
		end,
		AnchorPoint = Vector2.new(0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 1),
		AutomaticSize = Enum.AutomaticSize.XY,
		ClipsDescendants = true,
		LayoutOrder = if expandDirection == "Right" then level else -level,
	}
	local levelChildren = {
		ScrollingFrame = scrollingFrame,
		SizeConstraint = SizeConstraint({
			MaxSize = function()
				return maxSize()
			end,
		}),
	}

	levelFrameProps = TableUtil.merge(levelFrameProps, levelChildren)

	return create "Frame"(levelFrameProps)
end

--------------------------------------------------------------------------------
--#1 PopupMenu
-- 전체 PopupMenu는 props.Size에 맞게 렌더링되며,
-- 각 레벨은 수평으로 배치되고, expandDirection에 따라 좌/우로 펼쳐집니다.
-- openPath에는 각 레벨의 선택된 버튼 정보({ index, buttonRef })가 저장되며,
-- 메뉴 레벨은 해당 부모 버튼의 AbsolutePosition.Y에 맞춰 바로 옆에 위치합니다.
-- 메뉴 닫힘 시에는 해당 레벨의 width가 빠르게 0으로 트윈됩니다.
--------------------------------------------------------------------------------
local function PopupMenu(props: PopupMenuProps, propsRef)
	local frameProps = table.clone(props)
	local buttons = props.Buttons or {}
	frameProps.Buttons = nil
	local onButtonSelected = props.OnButtonSelected
	frameProps.OnButtonSelected = nil
	local expandDirection = props.ExpandDirection or "Right"
	frameProps.ExpandDirection = nil
	local scrollDirection = props.ScrollDirection or "Up"
	frameProps.ScrollDirection = nil
	local size = props.Size
	frameProps.Size = size

	local menuFrameSource = source(nil :: Frame?)

	local openPath = source({})
	-- maxLevel: 이전에 열렸던 최대 레벨 (닫힐 때 트윈 적용)
	local maxLevel = source(1)

	local function updateOpenPath(level: number, index: number, frameSource: () -> GuiBase2d?)
		local currentPath = openPath()
		local newPath = {}
		for i = 1, level - 1 do
			newPath[i] = currentPath[i]
		end
		newPath[level] = { Index = index, FrameSource = frameSource }
		openPath(newPath)
		maxLevel(level + 1)
	end

	local currentPath = openPath()
	local maxOpenLevel = maxLevel()

	local menuLevels = {}
	local currentItems = buttons
	local level = 1
	while currentItems and #currentItems > 0 and level <= maxOpenLevel do
		local parentFrameSource = if level > 1 and currentPath[level - 1]
			then currentPath[level - 1].FrameSource
			else menuFrameSource

		menuLevels[#menuLevels + 1] = MenuLevel({
			Level = level,
			Items = currentItems,
			ExpandDirection = expandDirection,
			ScrollDirection = scrollDirection,
			ParentFrameSource = parentFrameSource,
			MenuFrameSource = menuFrameSource,
			UpdateOpenPath = updateOpenPath,
			OnButtonSelected = onButtonSelected,
		})
		local selectedEntry = currentPath[level]
		if
			selectedEntry
			and currentItems[selectedEntry.Index]
			and currentItems[selectedEntry.Index].Buttons
		then
			currentItems = currentItems[selectedEntry.Index].Buttons
			level = level + 1
		else
			break
		end
	end

	local popupProps = TableUtil.merge({
		ref = function(frame)
			if typeof(propsRef) == "function" then
				propsRef(frame)
			elseif typeof(propsRef) == "table" then
				propsRef.current = frame
			end
			menuFrameSource(frame)
		end,
		Size = size,
	}, frameProps)

	local popupChildren = {
		ListLayout = ListLayout({
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = (expandDirection == "Left") and Enum.HorizontalAlignment.Right
				or Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Padding = 2,
		}),
	}

	popupChildren = TableUtil.merge(popupChildren, menuLevels)
	popupProps = TableUtil.merge(popupProps, popupChildren)

	return Frame(popupProps)
end

return PopupMenu
