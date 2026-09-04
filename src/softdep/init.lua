local Access = require("softdep.Access")
local Graph = require("softdep.Graph")
local Node = require("softdep.Node")
local Task = require("softdep.Task")
local types = require("softdep.types")
local check = require("softdep.check")

local softdep = {}

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

local function pass(...) end

-- 类型检查, 补全, 内容检查, 实现
local function makeConfig(config)
	check(2, types.configGraph(config))

	local system = {}
	system.access = Access.newAccess(config.access.levels, config.access.leq)

	config.nodes = config.nodes or {}
	for ntag, node in pairs(config.nodes) do
		node.tasks = node.tasks or {}
		for ttag, task in pairs(node.tasks) do
			task.func = task.func or pass
			task.auto = task.auto or pass
			
		end
	end
end

return softdep
