local vide = require("../../roblox_packages/vide")

local cleanup = vide.cleanup
local action = vide.action


local function behavior(setup, opts)
	return action(function(instance)
		local result = setup(instance)
		if result and result.destroy then
			cleanup(result.destroy)
		end
	end, opts and opts.priority)
end

return behavior
