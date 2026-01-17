local Types = require("./Types")
local Utils = require("./Utils")
local Modifier = require("./Modifier")
local Props = require("./Props")
local behavior = require("./Behaviors/behavior")
local behaviorReactive = require("./Behaviors/behaviorReactive")

local videKit = {}

export type props<Props = { [string]: any }> = Types.props<Props>

videKit.extractChildren = Utils.extractChildren
videKit.Modifier = Modifier
videKit.Props = Props
videKit.behavior = behavior
videKit.behaviorReactive = behaviorReactive

return videKit
