local TableUtil = require("../../../roblox_packages/TableUtil")
local Types = require("../../Types")
local area = require("../../Contexts/Area")
local theme = require("../../Contexts/Theme")
local vide = require("../../../roblox_packages/vide")

local Frame = require("../../Components/Frame")

export type ScrollingFrameProps =
	Types.props<{

		--roblox scrolling frame props
		AutomaticCanvasSize: Enum.AutomaticSize?,
		CanvasSize: UDim2?,
		CanvasPosition: Vector2?,

		ScrollingEnabled: boolean?,

		ScrollBarThickness: number?,
		ScrollBarImageColor3: Color3?,
		ScrollBarImageTransparency: number?,
		ScrollingDirection: Enum.ScrollingDirection?,

		TopImage: string?,
		MidImage: string?,
		BottomImage: string?,

		HorizontalScrollBarInset: Enum.ScrollBarInset?,
		VerticalScrollBarInset: Enum.ScrollBarInset?,

		VerticalScrollBarPosition: Enum.VerticalScrollBarPosition?,

		ElasticBehavior: Enum.ElasticBehavior?,
	}>
	& Frame.FrameProps

local function ScrollingFrame(props: ScrollingFrameProps)
	local scrollBarImageColor = props.ScrollBarImageColor3
		or function()
			return theme().ScrollBar
		end

	local labelProps = TableUtil.merge({
		Class = "ScrollingFrame",

		MidImage = "rbxassetid://1195495135",
		BottomImage = "rbxassetid://1195495135",
		TopImage = "rbxassetid://1195495135",
		ScrollBarThickness = function()
			return math.max(4 / area().resolutionScale, 1)
		end,

		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,

		ScrollBarImageColor3 = scrollBarImageColor,
	}, props)

	return Frame(labelProps)
end

return ScrollingFrame
