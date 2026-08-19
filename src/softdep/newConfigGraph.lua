local function deepCopy(value, seen)
	if type(value) ~= "table" then
		return value
	end

	seen = seen or {}
	if seen[value] then
		return seen[value]
	end

	local copy = {}
	seen[value] = copy

	for key, item in pairs(value) do
		copy[deepCopy(key, seen)] = deepCopy(item, seen)
	end

	return copy
end

local function pass() end

local function newConfigGraph(nodes)
	local configGraph = deepCopy(nodes)
	for _, node in pairs(configGraph) do
		node.data = node.data or {}
		node.tasks = node.tasks or {}
		node.access = node.access or "none"
		for _, task in pairs(node.tasks) do
			task.func = task.func or pass
			task.args = task.args or {}
            task.parents = task.parents or {}
            task.access = task.access or "writable"
		end
	end
	return configGraph
end

return newConfigGraph
