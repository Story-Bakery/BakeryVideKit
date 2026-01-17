--[=[
    @class TextLabel
    @tag vide

    텍스트 렌더링을 위한 기본 컴포넌트. 테마 색상과 기본 폰트/Truncate 를 적용합니다.
]=]

local vide = require("../../../roblox_packages/vide")
local Types = require("../../Types")
local TableUtil = require("../../../roblox_packages/TableUtil")
local theme = require("../../Contexts/Theme")
local Frame = require("../../Components/Frame")

export type TextLabelProps = Types.props<{
	
	Text: string?,
	TextColor3: Color3?,
	TextTransparency: number?,
	TextTruncate: Enum.TextTruncate?,
	TextScaled: boolean?,
	TextSize: number?,
	
	RichText: boolean?,
	TextWrapped: boolean?,
	
	LineHeight: number?,
	MaxVisibleGraphemes: number?,
	
	TextDirection: Enum.TextDirection?,
	TextXAlignment: Enum.TextXAlignment?,
	TextYAlignment: Enum.TextYAlignment?,
	
	FontFace: Font?,
	
}> & Frame.FrameProps

local function TextLabel(props: TextLabelProps)
    local frameProps = TableUtil.merge({
        Class = "TextLabel",
        RichText = true,
        TextTruncate = props.TextTruncate or Enum.TextTruncate.AtEnd,
        FontFace = Font.fromEnum(Enum.Font.SourceSans),
        TextSize = 14,
    }, props)

    frameProps.TextColor3 = props.TextColor3 or function()
		return theme().Text
	end

    return Frame(frameProps)
end

return TextLabel
