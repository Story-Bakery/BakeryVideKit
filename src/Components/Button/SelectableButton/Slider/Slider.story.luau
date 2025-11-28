local vide = require("../../../../../roblox_packages/vide")

local MathUtil = require("../../../../../roblox_packages/MathUtil")
local TableUtil = require("../../../../../roblox_packages/TableUtil")

local Frame = require("../../../../Components/Frame")

local RangeSlider = require("./RangeSlider")
local Slider = require("./")

local source = vide.source
local mount = vide.mount
local read = vide.read

local INCREMENT = 0.05

local function IncrementRangeSlider(props)
	local currentValue = source(0.5)

	local function onValueSlide(newValue)
		currentValue(MathUtil.roundToIncrement(newValue, INCREMENT))
	end

	local function onStepClick(step)
		currentValue(function(value)
			return MathUtil.roundToIncrement(value + step, INCREMENT)
		end)
	end

	return RangeSlider(TableUtil.merge(props, {
		Value = currentValue(),
		Min = 0,
		Max = 1,
		OnValueSlide = onValueSlide,

		Text = string.format("%.3f", currentValue()),
		SlideDirection = "X",

		HiddenGauge = false,
		GaugeColorMin = Color3.fromRGB(100, 200, 255),
		GaugeColorMax = Color3.fromRGB(50, 150, 200),
		GaugeStrokeColor = Color3.fromRGB(30, 30, 30),

		ShowStepControls = true,
		OnStepClick = onStepClick,
		StepScale = INCREMENT,
	}))
end

local function App(props)
	local defaultSliderDelta = source(0)
	local rangeSliderValue = source(0)
	local stepSliderValue = source(0)
	local verticalStepRangeSliderValue = source(0)

	local frameProps = {
		Size = UDim2.fromScale(1, 1),
	}
	table.insert(
		frameProps,
		Slider({
			Name = "Slider",
			Size = UDim2.fromOffset(400, 15),
			Position = UDim2.new(0.5, 0, 0, 20),
			AnchorPoint = Vector2.one / 2,
			Text = "Default/" .. string.format("%.3f", defaultSliderDelta()),
			OnSlideMove = function(delta)
				defaultSliderDelta(delta)
			end,
		})
	)

	table.insert(
		frameProps,
		RangeSlider({
			Name = "RangeSlider",
			Size = UDim2.fromOffset(400, 15),
			Position = UDim2.new(0.5, 0, 0, 40),
			AnchorPoint = Vector2.one / 2,
			Text = function()
				return string.format("%.3f", rangeSliderValue())
			end,
			OnValueSlide = function(value)
				rangeSliderValue(value)
			end,
			Min = -11,
			Max = 5,
			Value = rangeSliderValue,
		})
	)

	table.insert(
		frameProps,
		Slider({
			Name = "StepSlider",
			Size = UDim2.fromOffset(400, 15),
			Position = UDim2.new(0.5, 0, 0, 70),
			AnchorPoint = Vector2.one / 2,
			Text = "Step/" .. string.format("%.3f", stepSliderValue()),
			ShowStepControls = true,
			OnSlideMove = function(delta)
				stepSliderValue(function(current)
					return current + delta
				end)
			end,
			OnStepClick = function(delta)
				stepSliderValue(function(current)
					return current + delta
				end)
			end,
		})
	)

	table.insert(
		frameProps,
		RangeSlider({
			Name = "VerticalRangeStepSlider",
			Size = UDim2.fromOffset(45, 125),
			Position = UDim2.new(0.5, 250, 0, 65),
			AnchorPoint = Vector2.one / 2,
			Text = string.format("%.3f", verticalStepRangeSliderValue()),
			ShowStepControls = true,
			SlideDirection = "Y",
			OnValueSlide = function(value)
				verticalStepRangeSliderValue(value)
			end,
			Value = verticalStepRangeSliderValue(),
			Max = 100,
			Min = -100,
			StepScale = 5,
		})
	)

	table.insert(
		frameProps,
		IncrementRangeSlider({
			Name = "IncrementRangeSlider",
			Size = UDim2.fromOffset(400, 15),
			Position = UDim2.new(0.5, 0, 0, 100),
			AnchorPoint = Vector2.one / 2,
		})
	)

	return Frame(frameProps)
end

local function SliderStory(target)
	local unmount = mount(function()
		return App({})
	end, target)

	return function()
		unmount()
	end
end

return SliderStory
