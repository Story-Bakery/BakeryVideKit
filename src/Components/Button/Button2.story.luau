
local vide = require("../../../roblox_packages/vide")
local mount = vide.mount
local source = vide.source

local DynamicTimer = require("../../../roblox_packages/DynamicTimer")
local DynamicTween = require("../../../roblox_packages/DynamicTween")
local LinearInterpolation = require("../../../roblox_packages/LinearInterpolation")
local UserInputManager = require("../../../roblox_packages/UserInputManager")

local theme = require("../../Contexts/Theme")
local Button = require("../../Components/Button")

local function BeatButton(props)
	local theme = theme()
	
	local progressFromClick = source(0)
	local clickTween: DynamicTween.DynamicTween

	local function startUpdatingProgressOnClick()
		if clickTween then
			clickTween:Destroy()
		end

		clickTween = DynamicTimer.GlobalTimer:CreateDynamicTween({
			Start = 1,
			Goal = 0,
			Duration = 0.5,
			Callback = function(value)
				progressFromClick(value)
			end,
		})

		clickTween:Play()
	end
	
	return Button({
		Icon = "rbxassetid://11722865980",
		Text = "Click Me",
		TextSize = 100,
		TextColor3 = LinearInterpolation.Color3(
			theme.ButtonText,
			Color3.fromRGB(255, 0, 0),
			progressFromClick()
		),
		ClickEffectColor = LinearInterpolation.Color3(
			theme.ButtonClickEffect,
			Color3.fromRGB(255, 0, 0),
			progressFromClick()
		),
		HighlightColor = LinearInterpolation.Color3(
			theme.ButtonHighlight,
			Color3.fromRGB(255, 0, 212),
			progressFromClick()
		),
		
		OnClick = startUpdatingProgressOnClick,
	})
end

return function(target)
	local unmount = mount(function()
		return BeatButton({})
	end, target)

	return function()
		unmount()
		UserInputManager.ClearEveryGlobalHosts()
	end
end
