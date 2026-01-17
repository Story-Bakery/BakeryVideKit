local Modifier = require("../Modifier")


local Props = {}

local function applyStringKeys(target, source, traceByKey, originByKey, originTag, opts, disallowEventKeys)
	if source == nil then
		return
	end

	for key, value in source do
		if type(key) ~= "string" then
			continue
		end

		local eventKeySet = opts and opts.eventKeySet
		if disallowEventKeys and eventKeySet and type(value) == "function" and eventKeySet[key] then
			error(("event key is not allowed in modifier: %s"):format(key))
		end

		local controlledKeys = opts and opts.controlledKeys
		if controlledKeys and controlledKeys[key] then
			if target[key] ~= nil and target[key] ~= value then
				error(("controlled prop cannot be overridden: %s"):format(key))
			end
			target[key] = value
			if originByKey then
				originByKey[key] = originTag
			end
			continue
		end

		if traceByKey and target[key] ~= nil and target[key] ~= value then
			local trace = traceByKey[key]
			if not trace then
				trace = {
					first = originByKey and originByKey[key] or "Unknown",
					overwrittenBy = {},
				}
				traceByKey[key] = trace
			end
			table.insert(trace.overwrittenBy, originTag)
		end

		target[key] = value
		if originByKey then
			originByKey[key] = originTag
		end
	end
end

local function checkArrayContinuity(label, array)
	if array == nil then
		return
	end

	local maxIndex = 0
	local count = 0
	for key in array do
		if type(key) == "number" then
			count += 1
			if key > maxIndex then
				maxIndex = key
			end
		end
	end

	if count ~= maxIndex then
		warn(("%s array has holes (count=%d, max=%d)"):format(label, count, maxIndex))
	end
end

local function appendModifierChildren(out, modifier, checkNested)
	for index = 1, #modifier do
		local child = modifier[index]
		if checkNested and Modifier.isModifier(child) then
			error("nested modifier is not allowed")
		end
		table.insert(out, child)
	end
end

local function buildConflictWarning(traceByKey, originByKey, opts)
	if not traceByKey then
		return
	end

	local hasConflicts = false
	for _ in traceByKey do
		hasConflicts = true
		break
	end

	if not hasConflicts then
		return
	end

	if opts and opts.onWarn then
		opts.onWarn(traceByKey, originByKey)
	else
		warn("composeProps conflicts", traceByKey)
	end
end

function Props.keySet(keys)
	local keySet = {}
	for index = 1, #keys do
		local key = keys[index]
		keySet[key] = true
	end
	return keySet
end

function Props.splitProps(props, ownedKeySet)
	local owned = {}
	local rest = {}

	if ownedKeySet == nil then
		ownedKeySet = {}
	end

	for key, value in props do
		if type(key) == "string" then
			if ownedKeySet[key] then
				owned[key] = value
			else
				rest[key] = value
			end
		end
	end

	return owned, rest
end

function Props.composePropsDev(base, rest, props, opts)
	local out = {}
	local traceByKey = {}
	local originByKey = {}
	local onConflict = "warn"

	if opts and opts.onConflict then
		onConflict = opts.onConflict
	end

	checkArrayContinuity("props", props)

	applyStringKeys(out, base, traceByKey, originByKey, "Base", opts)

	for index = 1, #props do
		local item = props[index]
		if Modifier.isModifier(item) then
			checkArrayContinuity(("modifier #%d"):format(index), item)
			applyStringKeys(out, item, traceByKey, originByKey, ("Modifier#%d"):format(index), opts, true)
		end
	end

	applyStringKeys(out, rest, traceByKey, originByKey, "Rest", opts)

	for index = 1, #props do
		local item = props[index]
		if Modifier.isModifier(item) then
			appendModifierChildren(out, item, true)
		else
			table.insert(out, item)
		end
	end

	if onConflict == "warn" then
		buildConflictWarning(traceByKey, originByKey, opts)
	end

	return out
end

function Props.composePropsProd(base, rest, props, opts)
	local out = {}

	applyStringKeys(out, base, nil, nil, "Base", opts)

	for index = 1, #props do
		local item = props[index]
		if Modifier.isModifier(item) then
			applyStringKeys(out, item, nil, nil, ("Modifier#%d"):format(index), opts)
		end
	end

	applyStringKeys(out, rest, nil, nil, "Rest", opts)

	for index = 1, #props do
		local item = props[index]
		if Modifier.isModifier(item) then
			appendModifierChildren(out, item, false)
		else
			table.insert(out, item)
		end
	end

	return out
end

function Props.composeProps(base, rest, props, opts)
	local wantsWarnings = opts and opts.onConflict == "warn"
	local wantsChecks = opts and opts.eventKeySet ~= nil
	local wantsHook = opts and opts.onWarn ~= nil

	if wantsWarnings or wantsChecks or wantsHook then
		return Props.composePropsDev(base, rest, props, opts)
	end

	return Props.composePropsProd(base, rest, props, opts)
end

return Props
