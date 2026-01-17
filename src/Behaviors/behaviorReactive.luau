local vide = require("../../roblox_packages/vide")

local action = vide.action
local cleanup = vide.cleanup
local effect = vide.effect


local function behaviorReactive(setup, opts)
	return action(function(instance)
		local result = setup(instance)
		if result and result.update then
			effect(function()
				result.update()
			end)
		end
		if result and result.destroy then
			cleanup(result.destroy)
		end
	end, opts and opts.priority)
end

return behaviorReactive
