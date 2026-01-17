--[[
    CircularFrame 컴포넌트의 게이지 데모 스토리입니다.
]]

local RunService = game:GetService("RunService")

local vide = require("../../../roblox_packages/vide")
local effect = vide.effect
local source = vide.source

local Components = require("../../Components")
local UserInputManager = require("../../../roblox_packages/UserInputManager")

local Frame = Components.Frame
local CircularFrame = Components.CircularFrame
local AspectRatioConstraint = Components.AspectRatioConstraint
local ImageLabel = Components.ImageLabel
local Slider = Components.Slider

local controls = {
	AutoProgress = true,
}

local function story(props)
	local rotation = source(0)
	local startProgress = source(0.95)
	local endProgress = source(1.9)

	effect(function()
		local conn = RunService.RenderStepped:Connect(function(dt)
			if not props.controls.AutoProgress() then
				return
			end

			startProgress(startProgress() + dt * 0.6)
			endProgress(endProgress() + dt * 0.6)
		end)

		vide.cleanup(function()
			conn:Disconnect()
		end)
	end)

	vide.cleanup(function()
		UserInputManager.ClearEveryGlobalHosts()
	end)

	local frameProps = {
		CircularFrame({
			Name = "CircularFrame",
			Size = UDim2.fromScale(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.one / 2,

			Rotation = rotation,
			StartProgress = startProgress,
			EndProgress = endProgress,

			UIComponents = {
				AspectRatioConstraint({
					AspectRatio = 1,
				}),
			},

			ImageLabel({
				ImageContent = Content.fromAssetId(11813117028),
			}),
		}),
		Slider({
			Name = "StartProgress",
			Size = UDim2.fromOffset(200, 15),
			Position = UDim2.new(1, -250, 0, 50),
			Text = function()
				return string.format("%.3f", startProgress())
			end,
			OnSlideMove = function(delta)
				startProgress(startProgress() + delta)
			end,
		}),
		Slider({
			Name = "EndProgress",
			Size = UDim2.fromOffset(200, 15),
			Position = UDim2.new(1, -250, 0, 80),
			Text = function()
				return string.format("%.3f", endProgress())
			end,
			OnSlideMove = function(delta)
				endProgress(endProgress() + delta)
			end,
		}),
	}

	return Frame(frameProps)
end

return {
	vide = vide,
	controls = controls,
	story = story,
}
