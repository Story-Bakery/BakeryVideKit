local vide = require("../../../roblox_packages/vide")
local create = vide.create
local Types = require("../../Types")
local TableUtil = require("../../../roblox_packages/TableUtil")
local Maid = require("../../../roblox_packages/Maid")
local theme = require("../../Contexts/Theme")
local TextLabel = require("../../Components/TextLabel")

export type ButtonTextLabelProps = TextLabel.TextLabelProps

local function ButtonTextLabel(props: ButtonTextLabelProps)
    local textLabelProps = table.clone(props)
    local automaticSize = props.AutomaticSize or Enum.AutomaticSize.None

    local buttonTextLabelProps = TableUtil.merge({
        TextColor3 = props.TextColor3 or function()
			return theme().ButtonText
		end,
        Size = UDim2.fromScale(0, 1),
        BackgroundTransparency = 1,
        LayoutOrder = 10,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        StrokeEnabled = false,
    }, textLabelProps)

    if automaticSize == Enum.AutomaticSize.None then
        table.insert(buttonTextLabelProps, create "UIFlexItem" {
            FlexMode = Enum.UIFlexMode.Fill,
        })
    end

    return TextLabel(buttonTextLabelProps)
end

return ButtonTextLabel
