local Types = require("./Types")
local Utils = require("./Utils")

local videKit = {}

export type props<Props = { [string]: any }> = Types.props<Props>

videKit.extractChildren = Utils.extractChildren

return videKit
