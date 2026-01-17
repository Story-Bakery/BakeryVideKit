--[=[
    @class Frame
    @tag vide

    Roblox Frame 기반의 래퍼 컴포넌트입니다. 테마 색상과 공통 Corner/Stroke를 적용하고,
    전달된 children 을 숫자 인덱스 순서로 병합해 반환합니다.
]=]

local theme = require("../../Contexts/Theme")
local Props = require("../../Props")
local vide = require("../../../roblox_packages/vide")
local Types = require("../../Types")

local create = vide.create
local read = vide.read

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

local OWNED_KEY_SET = Props.keySet({
	"Class",
	"CornerRadius",
	"StrokeColor",
	"StrokeEnabled",
	"StrokeThickness",
	"StrokeTransparency",
})

local CONTROLLED_KEYS = Props.keySet({
	"BorderSizePixel",
})

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
	local localProps, restProps = Props.splitProps(props, OWNED_KEY_SET)
	local class = localProps.Class or "Frame"

	local base = {
		BorderSizePixel = 0,
		BackgroundColor3 = props.BackgroundColor3 or function()
			return theme().Background
		end,
		Size = props.Size or UDim2.fromScale(1, 1),
	}

	local function getStrokeTransparency()
		local strokeEnabled = read(localProps.StrokeEnabled)
		local transparency = read(localProps.StrokeTransparency)
		if strokeEnabled == nil or strokeEnabled == true then
			return transparency or 0
		end

		return 1
	end

	local propsWithChildren = {}
	for index = 1, #props do
		propsWithChildren[index] = props[index]
	end

	table.insert(
		propsWithChildren,
		create "UIStroke" {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = function()
				return read(localProps.StrokeColor) or theme().Stroke
			end,
			Thickness = function()
				return read(localProps.StrokeThickness) or 1
			end,
			Transparency = getStrokeTransparency,
		}
	)

	local cornerRadius = read(localProps.CornerRadius)
	if cornerRadius ~= nil and cornerRadius ~= 0 then
		table.insert(propsWithChildren, createUICorner(cornerRadius))
	end

	return create(class)(Props.composeProps(base, restProps, propsWithChildren, {
		controlledKeys = CONTROLLED_KEYS,
	}))
end

return Frame
