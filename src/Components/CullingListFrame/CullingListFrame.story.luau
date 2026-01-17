local vide = require("../../../roblox_packages/vide")
local UILabs = require("../../../roblox_packages/ui-labs")
local DynamicTween = require("../../../roblox_packages/DynamicTween")

local Components = require("../../Components")

local Frame = Components.Frame
local Button = Components.Button
local TextLabel = Components.TextLabel
local TextBox = Components.TextBox
local CullingListFrame = require(script.Parent)

local effect = vide.effect
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
		ZIndex = params.ZIndex,
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
	local cursorIndex = source(555)

	local randomSize = source(0)
	effect(function()
		local tween = DynamicTween.new({
			Reverses = true,
			RepeatCount = -1,
			Duration = 0.5,
			Callback = function(progress)
				randomSize(progress)
			end,
		})

		tween:Play()

		return function()
			tween:Destroy()
		end
	end)

	local layoutOrder = 0
	local function nextLayoutOrder()
		layoutOrder += 1
		return layoutOrder
	end

	local cullingElements = {}

	table.insert(cullingElements, createElement({
		Key = "AD",
		Size = UDim2.new(1, 0, 0, 15),
		LayoutOrder = nextLayoutOrder(),
		Children = {
			TextLabel({
				Text = "Hello",
				Size = UDim2.fromScale(.5, 1),
			}),
		},
	}))

	table.insert(cullingElements, createElement({
		Key = "HelloWorld",
		Size = UDim2.new(1, 0, 0, 35),
		LayoutOrder = nextLayoutOrder(),
		Children = {
			Button({
				Text = "Hello World",
				Size = UDim2.fromScale(.5, .5),
				Position = UDim2.fromScale(.5, .5),
				AnchorPoint = Vector2.new(.5, .5),
			}),
		},
	}))

	table.insert(cullingElements, createElement({
		Key = "1",
		Size = UDim2.new(.5, 0, 0, 35),
		LayoutOrder = nextLayoutOrder(),
		Children = {
			Button({
				Text = "1",
				Size = UDim2.fromScale(1, 1),
			}),
		},
	}))

	table.insert(cullingElements, createElement({
		Key = "2",
		Size = UDim2.new(.5, 0, 0, 35),
		LayoutOrder = nextLayoutOrder(),
		Children = {
			Button({
				Text = "2",
				Size = UDim2.fromScale(.5, 1),
			}),
		},
	}))

	table.insert(cullingElements, createElement({
		Key = "3",
		Size = UDim2.new(.5, 0, 0, 55),
		LayoutOrder = nextLayoutOrder(),
		Children = {
			Button({
				Text = "3",
				Size = UDim2.fromScale(.5, 1),
			}),
		},
	}))

	table.insert(cullingElements, createElement({
		Key = "TextBox",
		Size = UDim2.new(1, 0, 0, 55),
		LayoutOrder = nextLayoutOrder(),
		AutomaticSize = Enum.AutomaticSize.Y,
		Children = {
			TextBox({
				Size = UDim2.fromScale(1, 1),
				LayoutOrder = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Text = "Here",
				MultiLine = true,
			}),
		},
	}))

	table.insert(cullingElements, createElement({
		Key = "4",
		Size = UDim2.new(.5, 0, 0, 35),
		LayoutOrder = nextLayoutOrder(),
		Children = {
			Button({
				Text = "4",
				Size = UDim2.fromScale(.5, 1),
			}),
		},
	}))

	table.insert(cullingElements, createElement({
		Key = "5",
		Size = UDim2.new(.5, 0, 0, 35),
		LayoutOrder = nextLayoutOrder(),
		Children = {
			Button({
				Text = "5",
				Size = UDim2.fromScale(.5, 1),
			}),
		},
	}))

	table.insert(cullingElements, createElement({
		Key = "6",
		Size = UDim2.new(.5, 0, 0, 35),
		LayoutOrder = nextLayoutOrder(),
		Children = {
			Button({
				Text = "6",
				Size = UDim2.fromScale(.5, 1),
			}),
		},
	}))

	table.insert(cullingElements, createElement({
		Key = "Sizer",
		Size = function()
			return UDim2.new(.5, 0, 0, randomSize() * 455)
		end,
		LayoutOrder = nextLayoutOrder(),
		Children = {
			Button({
				Text = "Sizer",
				Size = UDim2.fromScale(.5, 1),
			}),
		},
	}))

	table.insert(cullingElements, createElement({
		Key = "4-2",
		Size = UDim2.new(.5, 0, 0, 35),
		LayoutOrder = nextLayoutOrder(),
		Children = {
			Button({
				Text = "4",
				Size = UDim2.fromScale(.5, 1),
			}),
		},
	}))

	table.insert(cullingElements, createElement({
		Key = "5-2",
		Size = UDim2.new(.5, 0, 0, 35),
		LayoutOrder = nextLayoutOrder(),
		Children = {
			Button({
				Text = "5",
				Size = UDim2.fromScale(.5, 1),
			}),
		},
	}))

	table.insert(cullingElements, createElement({
		Key = "6-2",
		Size = UDim2.new(.5, 0, 0, 35),
		LayoutOrder = nextLayoutOrder(),
		Children = {
			Button({
				Text = "6",
				Size = UDim2.fromScale(.5, 1),
			}),
		},
	}))

	for i = 1, 1000 do
		local order = nextLayoutOrder()
		local hue = (i % 36) / 36

		table.insert(cullingElements, createElement({
			Key = order,
			Size = UDim2.new(1, 0, 0, 35),
			LayoutOrder = order,
			Children = {
				Button({
					Text = tostring(order),
					Size = UDim2.fromScale(1, 1),
					ButtonColor = Color3.fromHSV(hue, .2, 1),
					HighlightColor = Color3.fromHSV((hue + .5) % 1, .2, 1),
					TextColor3 = Color3.fromHSV((hue + .5) % 1, 1, 1),
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
		}),
	})
end)
