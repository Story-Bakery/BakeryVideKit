--[=[
    @class ImageLabel
    @tag vide

    Frame 기반으로 이미지를 렌더링하는 래퍼입니다. Frame 기본 props 를 유지하면서
    Roblox ImageLabel 속성을 안전하게 전달합니다.
]=]

local Frame = require("../../Components/Frame")
local Props = require("../../Props")
local Types = require("../../Types")
local vide = require("../../../roblox_packages/vide")

local read = vide.read
local derive = vide.derive

--[=[
	@interface ImageLabelProps
	@within ImageLabel

	ImageLabel 고유 속성입니다.

	.ImageContent Content? -- 표시할 이미지 콘텐츠.
	.ImageTransparency number? -- 이미지 투명도.
	.ImageColor3 Color3? -- 이미지 색상 틴트.
	.ImageRectSize Vector2? -- 스프라이트 시트 크기.
	.ImageRectOffset Vector2? -- 스프라이트 시트 오프셋.
	.ScaleType Enum.ScaleType? -- 스케일 방식.
	.SliceCenter Rect? -- 9슬라이스 중앙 영역.
	.SliceScale number? -- 9슬라이스 스케일.
]=]
export type ImageLabelProps =
	Types.props<{

		ImageContent: Content?,
		ImageUri: string?,

		ImageTransparency: number?,
		ImageColor3: Color3?,
		ImageRectSize: Vector2?,
		ImageRectOffset: Vector2?,
		ScaleType: Enum.ScaleType?,
		SliceCenter: Rect?,
		SliceScale: number?,
	}>
	& Frame.FrameProps

local OWNED_KEY_SET = Props.keySet({
	"Class",
	"ImageContent",
	"ImageUri",
})

local function ImageLabel(props: ImageLabelProps)
	if (props :: any).Image then
		error("Image prop is deprecated, use ImageContent/ImageUri instead.")
	end

	local localProps, restProps = Props.splitProps(props, OWNED_KEY_SET)
	local imageProps = {}

	for key, value in restProps do
		imageProps[key] = value
	end

	imageProps.Class = localProps.Class or "ImageLabel"

	local imageContent = localProps.ImageContent
	if localProps.ImageUri then
		imageContent = localProps.ImageContent
			or derive(function()
				return Content.fromUri(read(localProps.ImageUri))
			end)
	end

	if imageContent ~= nil then
		imageProps.ImageContent = imageContent
	end

	for index = 1, #props do
		imageProps[index] = props[index]
	end

	return Frame(imageProps)
end

return ImageLabel
