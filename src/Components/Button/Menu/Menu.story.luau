local vide = require("../../../../roblox_packages/vide")
local mount = vide.mount
local source = vide.source

local UserInputManager = require("../../../../roblox_packages/UserInputManager")
local Components = require("../../../Components")
local Frame = Components.Frame

local function app()
	local function createDefaultItems()
		return {
			{
				Category = "Word",
				Items = {
					{Name = "ABC"},
					{Name = "CAB"},
					{Name = "CAD"},
					{Name = "DA"},
					{Name = "ADS"},
				}
			},
			{
				Category = "Number",
				Items = {
					{
						IconContent = Content.fromAssetId(5816944720),
						Name = "One"
					},
					{
						IconContent = Content.fromAssetId(114647089904837),
						Name = "Two"
					},
					{
						IconContent = Content.fromAssetId(17341357210),
						Name = "Three"
					},
					{
						IconContent = Content.fromAssetId(72589386380625),
						Name = "Four"
					},
					{
						IconContent = Content.fromAssetId(184767240),
						Name = "Five"
					},
				},
			},
			{
				Category = "Animal",
				Items = {
					{Name = "Cat"},
					{Name = "Dog"},
					{Name = "Monkey"},
					{Name = "Human"},
					{Name = "Whale"},
					{Name = "Bear"},
					{Name = "Lion"},
					{Name = "Elephant"},
					{Name = "Pig"},
					{Name = "Mouse"},
					{Name = "Deer"},
					{Name = "Fox"},
					{Name = "Wolf"},
					{Name = "Bull"},
					{Name = "Horse"},
					{Name = "Sheep"},
					{Name = "Chicken"},
				}
			},
			{
				Category = "Flower",
				Items = {
					{Name = "Rose"},
					{Name = "Sunflower"},
					{Name = "Tulip"},
					{Name = "Daisy"},
					{Name = "Orchid"},
					{Name = "Lily"},
					{Name = "Carnation"},
				}
			},
			{
				Category = "Flower2",
				Items = {
					{Name = "Rose2"},
					{Name = "Sunflower2"},
					{Name = "Tulip2"},
					{Name = "Daisy2"},
					{Name = "Orchid2"},
					{Name = "Lily2"},
					{Name = "Carnation2"},
				}
			},
		}
	end
	local items = source(createDefaultItems())
	
	local selectedItem = source("Four")
	
	local frameProps = {
		Size = UDim2.fromScale(1, 1),
	}
	frameProps.Menu = Components.Menu {
		Size = UDim2.fromOffset(200, 25),
		Items = items(),
		SelectedItem = selectedItem(),
		OnItemSelect = function(nextItem)
			print(nextItem)
			selectedItem(nextItem)
		end,
	}

	return Frame(frameProps)
end

return function(target)
	local unmount = mount(function()
		return app()
	end, target)

	return function()
		unmount()
		UserInputManager.ClearEveryGlobalHosts()
	end
end
