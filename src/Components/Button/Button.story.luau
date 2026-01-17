local vide = require("../../../roblox_packages/vide")

local DynamicTween = require("../../../roblox_packages/DynamicTween")
local LinearInterpolation = require("../../../roblox_packages/LinearInterpolation")

local theme = require("../../Contexts/Theme")
local Frame = require("../../Components/Frame")
local TextLabel = require("../../Components/TextLabel")
local Button = require("../../Components/Button")
local ScrollingFrame = require("../../Components/ScrollingFrame")
local Padding = require("../../Components/UIComponent/Padding")
local ListLayout = require("../../Components/UIComponent/ListLayout")
local TableUtil = require("../../../roblox_packages/TableUtil")

local BuiltInThemes = {
	Dark = require("../../BuiltInThemes/Dark"),
	Light = require("../../BuiltInThemes/Light"),
	DeepGrey = require("../../BuiltInThemes/DeepGrey"),
}

local create = vide.create
local mount = vide.mount
local source = vide.source
local effect = vide.effect

local function createThemeAnimator(themeName: vide.Source<string>, themeSource)
	local tweenSet = {}

	local function clearTweens()
		for tween in tweenSet do
			tween:Destroy()
		end
		table.clear(tweenSet)
	end

	local newTheme = table.clone(themeSource() :: any)
	local function animate(targetThemeName: string)
		local goalTheme = BuiltInThemes[targetThemeName]
		if not goalTheme then
			return
		end
		
		clearTweens()

		for key, value in goalTheme do
			local lerp = LinearInterpolation.FindFunctionFromValueType(value)
			if not lerp then
				newTheme[key] = value
				continue
			end

			local tween = DynamicTween.new({
				Start = newTheme[key],
				Goal = value,
				Duration = 0.1,
				Callback = function(progress)
					newTheme[key] = progress
					themeSource(table.clone(newTheme))
				end,
			})

			tween:Play()
			tweenSet[tween] = true
		end

		themeSource(newTheme)
	end

	effect(function()
		animate(themeName())
	end)
end

local function App(props)
	local themeName = source("Dark")
	local themeSource = source(table.clone(props.InitialTheme))

	local themeSelectorProps = {
		Size = UDim2.new(0, 150, 1, 0),
		Position = UDim2.new(1, -150, 0, 0),

		ListLayout({
			Padding = 15,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),

		Padding({
			Padding = 2,
		}),
	}
	local function addThemeButton(name: string, layoutOrder: number)
		local buttonProps = {
			Size = UDim2.fromScale(0.5, 0.25),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Text = name,
			OnClick = function()
				themeName(name)
			end,
			LayoutOrder = layoutOrder,

			create("UIAspectRatioConstraint")({
				AspectRatio = 1,
			}),
			Padding({
				Padding = 2,
			}),
		}
		table.insert(themeSelectorProps, Button(buttonProps))
	end

	addThemeButton("Dark", 10)
	addThemeButton("Light", 20)
	addThemeButton("DeepGrey", 30)
	
	local proxyTheme = setmetatable({}, {
        __index = function(_, k)
			return themeSource()[k]
        end,
    })
	
	return theme(proxyTheme, function()
		createThemeAnimator(themeName, themeSource)

		return Frame ({
			Size = UDim2.fromScale(1, 1),
			ScrollingFrame(themeSelectorProps),
		})
	end)
end

return function(target)
	local initialTheme = theme()

	local unmount = mount(function()
		return App({InitialTheme = initialTheme})
	end, target)

	return function()
		unmount()
	end
end
