--[=[
    @class TextBox
    @tag vide
]=]

local TableUtil = require("../../../roblox_packages/TableUtil")
local TextLabel = require("../../Components/TextLabel")
local Types = require("../../Types")
local theme = require("../../Contexts/Theme")
local vide = require("../../../roblox_packages/vide")

export type TextBoxProps =
	Types.props<{

		ClearTextOnFocus: boolean?,
		MultiLine: boolean?,
		TextEditable: boolean?,

		CursorPosition: number?,
		SelectionStart: number?,

		PlaceholderText: string?,
		PlaceholderColor3: Color3?,

		OnFocused: () -> ()?,
		OnFocusLost: (isEnterPressed: boolean, input: InputObject, rbx: TextBox) -> ()?,

		OnTextChanged: (newText: string) -> ()?,
		OnCursorPositionChanged: (newCursorPosition: number) -> ()?,
		OnSelectionStartChanged: (newSelectionStart: number) -> ()?,
	}>
	& TextLabel.TextLabelProps

local function TextBox(props: TextBoxProps)
	local ref = { current = nil }
	local textLabelProps = TableUtil.merge({
		Class = "TextBox",
		ClearTextOnFocus = false,
		Text = "",
		PlaceholderColor3 = props.PlaceholderColor3 or function()
			return theme().PlaceholderText
		end,
	}, props)

	-- 이벤트 바인딩
	if props.OnFocused then
		textLabelProps.Focused = function()
			props.OnFocused()
		end
	end

	if props.OnFocusLost then
		textLabelProps.FocusLost = function(rbx, isEnterPressed, input)
			props.OnFocusLost(isEnterPressed, input, rbx)
		end
	end

	local function observe(propName: string, cb)
		if not cb then
			return
		end
		vide.effect(function()
			local tb = ref.current
			if not tb then
				return
			end
			local cn = tb:GetPropertyChangedSignal(propName):Connect(function()
				cb((tb :: any)[propName])
			end)
			vide.cleanup(function()
				cn:Disconnect()
			end)
		end)
	end

	observe("Text", props.OnTextChanged)
	observe("CursorPosition", props.OnCursorPositionChanged)
	observe("SelectionStart", props.OnSelectionStartChanged)

	-- ref 지정
	textLabelProps[1] = vide.action(function(inst)
		ref.current = inst
	end)

	return TextLabel(textLabelProps)
end

return TextBox
