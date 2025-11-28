local Types = require("./Types")


local Utils = {}

--[[
	props 에서 자식 컴포넌트들을 추출하여 별도의 배열로 반환합니다.
	props 에서 자식 컴포넌트들은 제외됩니다. 
]]
function Utils.extractChildren(props): { Types.child }
	local propChildren: { [string]: any } = { table.unpack(props) }
	for i, _ in propChildren do
		props[i] = nil
	end

	return propChildren
end

return Utils