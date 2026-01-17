--!nolint UnknownGlobal
local RunService = game:GetService("RunService")
local PluginGuiService = game:GetService("PluginGuiService")

local vide = require("../../../roblox_packages/vide")
local UserInputManager = require("../../../roblox_packages/UserInputManager")
local ExtendedTranslator = require("../../../roblox_packages/ExtendedTranslator")
local DynamicTimer = require("../../../roblox_packages/DynamicTimer")
local UILabs = require("../../../roblox_packages/ui-labs")

local defaultUserInputManager = UserInputManager.GlobalUserInputManager
if RunService:IsStudio() and UILabs.Environment.IsStory() then
	pcall(function()
		for i, pluginGui in PluginGuiService:GetChildren() do
			pcall(function()
				for j, frame in pluginGui:GetChildren() do
					if frame:IsA("GuiObject") then
						defaultUserInputManager:AddHost(frame)
					end
				end
			end)
		end
	end)
	local janitor = UILabs.Environment.GetJanitor()
	if janitor then
		janitor:Add(function()
			defaultUserInputManager:Destroy()
			UserInputManager.ClearEveryGlobalHosts()
		end)
	end
end

local area = vide.context({
	ResolutionScale = 1 :: number,
	UserInputManager = defaultUserInputManager :: UserInputManager.UserInputManager,
	Translator = ExtendedTranslator.new({
		LocalizationTables = {},
	}),
	Timer = DynamicTimer.UITimer,
})


return area
