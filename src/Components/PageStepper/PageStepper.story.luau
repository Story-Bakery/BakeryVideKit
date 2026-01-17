local vide = require("../../../roblox_packages/vide")
local source = vide.source
local mount = vide.mount

local Components = require("../../Components")
local MathUtil = require("../../../roblox_packages/MathUtil")

local function App()
	local currentPage = source(1)

	return Components.PageStepper({
		Size = UDim2.fromScale(1, 1),
		CurrentPage = currentPage(),
		OnChangingPage = function(delta)
			currentPage(function(value)
				return MathUtil.wrap(value + delta, 0, 3)
			end)
		end,
		Pages = {
			Components.TextLabel({
				Text = "1",
				BackgroundColor3 = Color3.fromRGB(55, 0, 0),
			}),
			Components.TextLabel({
				Text = "2",
				BackgroundColor3 = Color3.fromRGB(0, 55, 0),
			}),
			Components.TextLabel({
				Text = "3",
				BackgroundColor3 = Color3.fromRGB(0, 0, 55),
			}),
		},
	})
end

return function(target)
	local unmount = mount(function()
		return App()
	end, target)

	return function()
		unmount()
	end
end
