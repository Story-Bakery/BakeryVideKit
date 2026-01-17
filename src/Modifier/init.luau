local Modifier = {}

local MODIFIER_METATABLE = {}

function Modifier.fromProps(props)
	return setmetatable(props, MODIFIER_METATABLE)
end

function Modifier.isModifier(value)
	if type(value) ~= "table" then
		return false
	end
	return getmetatable(value) == MODIFIER_METATABLE
end

return Modifier
