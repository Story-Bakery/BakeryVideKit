--[=[
    @class Frame
    @tag vide

    Roblox Frame 기반의 래퍼 컴포넌트입니다. 테마 색상과 공통 Corner/Stroke를 적용하고,
    전달된 children 을 숫자 인덱스 순서로 병합해 반환합니다.
]=]

local TableUtil = require("../../../roblox_packages/TableUtil")
local Theme = require("../../Contexts/Theme")
local theme = require("../../Contexts/Theme")
local vide = require("../../../roblox_packages/vide")
local Types = require("../../Types")

local create = vide.create
local read = vide.read
local derive = vide.derive

export type FrameProps = Types.props<{
	Class: string?,

	CornerRadius: number | UDim?,

	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,

	BackgroundColor3: Color3?,
	BackgroundTransparency: number?,

	LayoutOrder: number?,
	ZIndex: number?,

	Rotation: number?,

	StrokeColor: Color3?,
	StrokeEnabled: boolean?,
	StrokeThickness: number?,
	StrokeTransparency: number?,

	AutomaticSize: Enum.AutomaticSize?,

	SizeConstraint: Enum.SizeConstraint?,
	Visible: boolean?,
}>

local function createUICorner(cornerRadius: number | UDim?)
	if cornerRadius == nil then
		return create "UICorner" { CornerRadius = UDim.new(0, 2) }
	end

	local r: UDim
	if typeof(cornerRadius) == "number" then
		if cornerRadius >= 0 and cornerRadius <= 1 then
			r = UDim.new(cornerRadius, 0)
		else
			r = UDim.new(0, cornerRadius)
		end
	else
		r = cornerRadius
	end
	return create "UICorner" { CornerRadius = r }
end

local function Frame(props: FrameProps): GuiBase2d
	local class = props.Class or "Frame"

	local frameProps = table.clone(props)
	frameProps.Class = nil
	frameProps.BorderSizePixel = 0
	frameProps.BackgroundColor3 = props.BackgroundColor3
		or function()
			return theme().Background
		end
	frameProps.Size = frameProps.Size or UDim2.fromScale(1, 1)

	local function getStrokeTransparency()
		local strokeEnabled = read(props.StrokeEnabled)
		local transparency = read(props.StrokeTransparency)
		if strokeEnabled == nil or strokeEnabled == true then
			return transparency or 0
		end

		return 1
	end

	table.insert(
		frameProps,
		create "UIStroke" {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = function()
				return read(props.StrokeColor) or theme().Stroke
			end,
			Thickness = function()
				return read(props.StrokeThickness) or 1
			end,
			Transparency = getStrokeTransparency,
		}
	)

	frameProps.StrokeEnabled = nil
	frameProps.StrokeColor = nil
	frameProps.StrokeThickness = nil
	frameProps.StrokeTransparency = nil

	-- Corner
	local cornerRadius = read(props.CornerRadius)
	if cornerRadius ~= nil and cornerRadius ~= 0 then
		table.insert(frameProps, createUICorner(cornerRadius))
	end
	frameProps.CornerRadius = nil

	return create(class)(frameProps)
end

return Frame
