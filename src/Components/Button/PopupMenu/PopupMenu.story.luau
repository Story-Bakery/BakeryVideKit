local vide = require("../../../../roblox_packages/vide")

local UserInputManager = require("../../../../roblox_packages/UserInputManager")

local Components = require("../../../Components")
local PopupMenu = Components.PopupMenu

local function App()
	local function onMenuSelected(selectedName)
		print("선택된 버튼:", selectedName)
	end

	local menuData = {
		{
			Name = "Third button",
			Buttons = {
				{ Name = "ABBBBBBBBBB" },
				{
					Name = "DEEEEEEEEEEEEE",
					Buttons = {
						{ Name = "KO?" },
						{ Type = "Line" },
						{ Type = "Category", Text = "구분" },
						{ Name = "KEOASD" },
					},
				},
			},
		},
		{
			Name = "Button1",
			Text = "첫번째 버튼",
			OnClick = function(inputObject)
				print("Button1 클릭")
			end,
		},
		{
			Name = "Button2",
			Text = "두번째 버튼",
			Buttons = {
				{ Name = "Button3" },
				{
					Name = "Button4",
					Buttons = {
						{ Name = "Button5" },
						{ Type = "Line" },
						{ Type = "Category", Text = "구분" },
						{ Name = "Button6" },
					},
				},
			},
		},
		{
			Name = "Fourth Button",
			Buttons = {
				{ Name = "ABC" },
				{
					Name = "DEF",
					Buttons = {
						{ Name = "GHK" },
						{ Type = "Line" },
						{ Type = "Category", Text = "구분" },
						{ Name = "LMN" },
					},
				},
				{
					Name = "DEF2",
				},
				{
					Name = "DEF3",
				},
				{
					Name = "DEF4",
				},
				{
					Name = "DEF5",
				},
			},
		},
		{
			Name = "FifthButton Button",
			Buttons = {
				{ Name = "DEFFFF" },
				{
					Name = "DEF",
					Buttons = {
						{ Name = "GHK" },
						{ Type = "Line" },
						{ Type = "Category", Text = "구분" },
						{ Name = "LMN" },
					},
				},
				{
					Name = "DEF2",
				},
				{
					Name = "DEF3",
				},
				{
					Name = "DEF4",
				},
				{
					Name = "DEF5",
				},
			},
		},
	}
	

	return PopupMenu({
		Buttons = menuData,
		OnButtonSelected = onMenuSelected,
		Size = UDim2.fromScale(.2, .3),
		Position = UDim2.fromScale(.5, .3),
		ExpandDirection = "Right",
	})
end

return function(target)
	local unmount = vide.mount(target)

	return function()
		unmount()
		UserInputManager.ClearEveryGlobalHosts()
	end
end
