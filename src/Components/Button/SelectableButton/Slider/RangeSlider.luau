local vide = require("../../../../../roblox_packages/vide")

local Types = require("../../../../Types")
local DynamicTween = require("../../../../../roblox_packages/DynamicTween")
local MathUtil = require("../../../../../roblox_packages/MathUtil")
local TableUtil = require("../../../../../roblox_packages/TableUtil")
local UserInputManager = require("../../../../../roblox_packages/UserInputManager")

local Frame = require("../../../../Components/Frame")
local Gradient = require("../../../../Components/UIComponent/Gradient")
local area = require("../../../../Contexts/Area")
local theme = require("../../../../Contexts/Theme")

local Slider = require(script.Parent)

local create = vide.create
local source = vide.source
local read = vide.read

export type RangeSliderProps =
	Types.props<{
		Value: number,
		Min: number,
		Max: number,
		HiddenGauge: boolean?,

		GaugeColor: Color3?,
		GaugeColorMin: Color3?,
		GaugeColorMax: Color3?,

		GaugeStrokeColor: Color3?,

		OnValueSlide: (value: number) -> ()?,
	}>
	& Slider.SliderProps

local function RangeSlider(props: RangeSliderProps)
	local sliderProps = table.clone(props)

	local value = props.Value or 1

	sliderProps.Value = nil
	local min = props.Min or 0
	sliderProps.Min = nil
	local max = props.Max or 1
	sliderProps.Max = nil

	local onValueSlide = props.OnValueSlide
	sliderProps.OnValueSlide = nil

	-- clear excessDeltaTotal
	local totalDeltaValue = source(0)
	local excessDeltaTotal = source(0)
	local wasSlowMode = source(false)
	local fakeValueWhileSliding = source(0)

	sliderProps.OnSlideStart = function()
		if props.OnSlideStart then
			props.OnSlideStart()
		end

		totalDeltaValue(0)
		excessDeltaTotal(0)
		fakeValueWhileSliding(read(value))
		wasSlowMode(false)
	end

	sliderProps.OnSlideMove = function(delta)
		if props.OnSlideMove then
			props.OnSlideMove(delta)
		end

		if not onValueSlide then
			return
		end

		local deltaValue = delta * (max - min)
		local newValue = fakeValueWhileSliding() + deltaValue
		totalDeltaValue(totalDeltaValue() + deltaValue)

		local isSlowMode = area().UserInputManager:IsInputKeyPressed(
			Enum.KeyCode.LeftShift,
			Enum.KeyCode.RightShift
		)
		if isSlowMode ~= wasSlowMode() then
			if isSlowMode then
				newValue -= totalDeltaValue() * 0.9
				totalDeltaValue(totalDeltaValue() * 0.1)
			else
				totalDeltaValue(totalDeltaValue() * 10)
				newValue += totalDeltaValue() * 0.9
			end

			wasSlowMode(isSlowMode)
		end

		if newValue < min then
			fakeValueWhileSliding(min)
			onValueSlide(min)
			if excessDeltaTotal() <= -delta then
				excessDeltaTotal(0)
			else
				excessDeltaTotal(excessDeltaTotal() + delta)
			end
		elseif max < newValue then
			fakeValueWhileSliding(max)
			onValueSlide(max)
			if excessDeltaTotal() <= -delta then
				excessDeltaTotal(0)
			else
				excessDeltaTotal(excessDeltaTotal() + delta)
			end
		elseif not MathUtil.fuzzyEqual(excessDeltaTotal(), 0, 0.0001) then
			if excessDeltaTotal() <= -delta then
				excessDeltaTotal(0)
			else
				excessDeltaTotal(excessDeltaTotal() + delta)
			end
		else
			fakeValueWhileSliding(newValue)
			onValueSlide(newValue)
		end
	end

	sliderProps.Text = props.Text or string.format("%.3f", props.Value)

	local hiddenGauge = props.HiddenGauge
	sliderProps.HiddenGauge = nil

	local slideDirection = props.SlideDirection or "X"
	sliderProps.SlideDirection = nil

	if not hiddenGauge then
		local gauge = vide.derive(function()
			return math.clamp((read(value) - read(min)) / (read(max) - read(min)), 0, 1)
		end)

		local function getGaugeColorMin()
			return read(props.GaugeColor) or read(props.GaugeColorMin) or theme().SliderGaugeMin
		end

		local function getGaugeColorMax()
			return read(props.GaugeColor) or read(props.GaugeColorMax) or theme().SliderGaugeMax
		end

		local gaugeFrame = Frame {
			Name = "GaugeFrame",
			Size = function()
				print(gauge())
				return if read(slideDirection) == "X"
					then UDim2.fromScale(gauge(), 1)
					else UDim2.fromScale(1, gauge())
			end,
			Position = function()
				return if read(slideDirection) == "X"
					then UDim2.fromScale(0, 0)
					else UDim2.fromScale(0, 1)
			end,
			AnchorPoint = function()
				return if read(slideDirection) == "X" then Vector2.new(0, 0) else Vector2.new(0, 1)
			end,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			StrokeColor = function()
				return read(props.GaugeStrokeColor) or theme().SliderGaugeStroke
			end,
		}

		local container = create "Folder" {
			gaugeFrame,

			Gradient({
				Color = function()
					return ColorSequence.new(getGaugeColorMin(), getGaugeColorMax())
				end,
			}),
		}

		table.insert(sliderProps, container)
	end
	sliderProps.GaugeColor = nil
	sliderProps.GaugeColorMin = nil
	sliderProps.GaugeColorMax = nil
	sliderProps.GaugeStrokeColor = nil

	if props.ShowStepControls then
		local propsOnStepClick = props.OnStepClick
		sliderProps.OnStepClick = function(delta)
			if propsOnStepClick then
				propsOnStepClick(delta)
			end

			if onValueSlide then
				onValueSlide(math.clamp(value + delta, min, max))
			end
		end
	end

	return Slider(sliderProps)
end

return RangeSlider
