local vide = require("../../../roblox_packages/vide")
local create = vide.create
local effect = vide.effect
local source = vide.source

local Types = require("../../Types")
local TableUtil = require("../../../roblox_packages/TableUtil")

export type LayerCollectorPortalProps = Types.props<{
	Position: UDim2?,
	Size: UDim2?,
	ZIndex: number?,
}>

local function LayerCollectorPortal(props: LayerCollectorPortalProps)
	local instanceToFindAncestor = source(nil :: Instance?)
	local gui2d = source(nil :: GuiBase2d?)
	local layerCollector = source(nil :: LayerCollector?)

	effect(function()
		local target = instanceToFindAncestor()
		if target == nil then
			layerCollector(nil)
			gui2d(nil)
			return
		end

		layerCollector(target:FindFirstAncestorWhichIsA("LayerCollector"))
		gui2d(target:FindFirstAncestorWhichIsA("GuiBase2d"))
	end)

	local size = source(UDim2.new())
	local position = source(UDim2.new())
	local propSize = props.Size or UDim2.new()
	local propPosition = props.Position or UDim2.new()

	effect(function()
		local currentLayerCollector = layerCollector()
		local currentGui = gui2d()

		if currentLayerCollector == nil or currentGui == nil then
			size(UDim2.new())
			position(UDim2.new())
			return
		end

		local function update()
			local currentSize = currentGui.AbsoluteSize
			local currentPosition = currentGui.AbsolutePosition
				- currentLayerCollector.AbsolutePosition
			size(
				UDim2.fromOffset(
					currentSize.X * propSize.X.Scale + propSize.X.Offset,
					currentSize.Y * propSize.Y.Scale + propSize.Y.Offset
				)
			)
			position(
				UDim2.fromOffset(
					currentPosition.X + currentSize.X * propPosition.X.Scale + propPosition.X.Offset,
					currentPosition.Y + currentSize.Y * propPosition.Y.Scale + propPosition.Y.Offset
				)
			)
		end

		update()
		local conn1 = currentGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
		local conn2 = currentGui:GetPropertyChangedSignal("AbsolutePosition"):Connect(update)

		vide.cleanup(function()
			conn1:Disconnect()
			conn2:Disconnect()
		end)
	end)

	local portalFrameProps = {
		Name = "LayerCollectorPortal",
		Transparency = 1,
		Size = function()
			return size()
		end,
		Position = function()
			return position()
		end,
		ZIndex = props.ZIndex,
		Parent = function()
			return layerCollector()
		end,
	}
	local propChildren = {}
	for key, child in pairs(props) do
		if type(key) == "number" then
			propChildren[key] = child
		end
	end
	portalFrameProps = TableUtil.merge(portalFrameProps, propChildren)

	return create "Folder" {
		ref = function(inst)
			instanceToFindAncestor(inst)
		end,
		Name = "LayerCollectorPortal",
		PortalFrame = create "Frame"(portalFrameProps),
	}
end

return LayerCollectorPortal
