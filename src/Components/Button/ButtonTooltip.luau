local vide = require("../../../roblox_packages/vide")
local effect = vide.effect
local source = vide.source

local Padding = require("../../Components/UIComponent/Padding")
local SizeConstraint = require("../../Components/UIComponent/SizeConstraint")
local TableUtil = require("../../../roblox_packages/TableUtil")
local TextLabel = require("../../Components/TextLabel")
local Types = require("../../Types")

export type ButtonTooltipProps = Types.props<TextLabel.TextLabelProps & {
	ParentSource: () -> Instance?,
	Visible: boolean | (() -> boolean)?,
}>

local function ButtonTooltip(props: ButtonTooltipProps)
	local function getParent()
		return props.ParentSource()
	end
	local firstAncestorGui = source(nil :: GuiBase2d?)
	local container = source(nil :: LayerCollector?)

	effect(function()
		local parent = getParent()
		if parent == nil then
			firstAncestorGui(nil)
			container(nil)
			return
		end

		firstAncestorGui(
			if parent:IsA("GuiBase2d")
				then parent
				else parent:FindFirstAncestorWhichIsA("GuiBase2d")
		)
		container(parent:FindFirstAncestorWhichIsA("LayerCollector"))

		local conn = parent.AncestryChanged:Connect(function()
			firstAncestorGui(
				if parent:IsA("GuiBase2d")
					then parent
					else parent:FindFirstAncestorWhichIsA("GuiBase2d")
			)
			container(parent:FindFirstAncestorWhichIsA("LayerCollector"))
		end)

		vide.cleanup(function()
			conn:Disconnect()
		end)
	end)

	local firstAncestorAbsPosition = source(Vector2.zero)
	local firstAncestorAbsSize = source(Vector2.zero)
	local containerAbsPosition = source(Vector2.zero)
	effect(function()
		local gui = firstAncestorGui()
		if gui == nil then
			return
		end

		firstAncestorAbsPosition(gui.AbsolutePosition)
		local conn = gui:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
			firstAncestorAbsPosition(gui.AbsolutePosition)
		end)

		firstAncestorAbsSize(gui.AbsoluteSize)
		local conn2 = gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			firstAncestorAbsSize(gui.AbsoluteSize)
		end)

		vide.cleanup(function()
			conn:Disconnect()
			conn2:Disconnect()
		end)
	end)

	effect(function()
		local currentContainer = container()
		if currentContainer == nil then
			return
		end

		print(currentContainer)

		containerAbsPosition(currentContainer.AbsolutePosition)
		local conn = currentContainer
			:GetPropertyChangedSignal("AbsolutePosition")
			:Connect(function()
				containerAbsPosition(currentContainer.AbsolutePosition)
			end)
		vide.cleanup(function()
			conn:Disconnect()
		end)
	end)

	if container() == nil then
		return nil
	end

	local absPosition = firstAncestorAbsPosition() - containerAbsPosition()
	local position = UDim2.fromOffset(absPosition.X, absPosition.Y + firstAncestorAbsSize().Y)

	local textLabelProps = {
		Text = props.Text,
		Size = UDim2.fromOffset(0, 0),
		TextSize = 12,
		Position = position,
		AutomaticSize = Enum.AutomaticSize.XY,
		ZIndex = 2 ^ 31 - 1,
		Parent = container,
	}
	if props.Visible ~= nil then
		textLabelProps.Visible = props.Visible
	end
	local propChildren = {}
	for key, child in textLabelProps do
		if type(key) == "number" then
			table.insert(propChildren, child)
			textLabelProps[key] = nil
		end
	end

	table.insert(
		textLabelProps,
		Padding({
			Padding = 2,
		})
	)
	table.insert(
		textLabelProps,
		SizeConstraint({
			MaxSize = Vector2.new(400, math.huge),
			MinSize = Vector2.new(15, 15),
		})
	)
	for _, child in propChildren do
		table.insert(textLabelProps, child)
	end

	return TextLabel(textLabelProps)
end

return ButtonTooltip
