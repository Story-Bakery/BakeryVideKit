local vide = require("../../../roblox_packages/vide")
local UILabs = require("../../../roblox_packages/ui-labs")

local Components = require("../../Components")
local CullingListFrame = require(script.Parent)

local Frame = Components.Frame
local Button = Components.Button

local source = vide.source

local function withChildren(target: { [any]: any }, children)
	if children == nil then
		return target
	end

	if type(children) == "table" then
		for key, child in children do
			if type(key) == "number" then
				table.insert(target, child)
			else
				target[key] = child
			end
		end
	else
		table.insert(target, children)
	end

	return target
end

local function createElement(params)
	local elementProps = withChildren({
		Size = params.Size,
		LayoutOrder = params.LayoutOrder,
		AutomaticSize = params.AutomaticSize,
		Position = params.Position,
		AnchorPoint = params.AnchorPoint,
	}, params.Children)

	return {
		Key = params.Key,
		Order = params.Order,
		Element = function()
			return Frame(elementProps)
		end,
	}
end

return UILabs.CreateVideStory({
	vide = vide,
}, function()
	local cursorIndex = source(1)

	local cullingElements = {}
	for index = 1, 25 do
		local order = source(index)
		local function setOrder(nextValue)
			order(nextValue)
		end
		local hue = (index % 25) / 25

		table.insert(cullingElements, createElement({
			Key = index,
			Order = order,
			Size = UDim2.new(0, 100 + (index % 3) * 10, 1, 0),
			Children = {
				Button({
					ButtonColor = Color3.fromHSV(hue, .2, 1),
					HighlightColor = Color3.fromHSV((hue + .5) % 1, .2, 1),
					TextColor3 = Color3.fromHSV((hue + .5) % 1, 1, 1),
					Text = `[{index}] {string.format("%.3f", order())}`,
					Size = UDim2.fromScale(1, 1),
					OnMouseButton1Click = function()
						setOrder(function(old)
							return old + 1
						end)
					end,
					OnMouseButton2Click = function()
						setOrder(function(old)
							return old - 1
						end)
					end,
				}),
			},
		}))
	end

	return Frame({
		CullingListFrame = CullingListFrame({
			CursorIndex = cursorIndex(),
			OnCursorChange = function(nextValue)
				cursorIndex(nextValue)
			end,
			Elements = cullingElements,
			SortOrder = "Order",
			ScrollingDirection = "X",
			ReversesAlignment = true,
		}),
	})
end)
