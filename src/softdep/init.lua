local Access = require("softdep.Access")
local Graph = require("softdep.Graph")
local Node = require("softdep.Node")
local Task = require("softdep.Task")

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

local function pass() end

function softdep.newGraph(config)
	config = deepCopy(config)

	config.nodes = config.nodes or {}
	for ntag, nargs in pairs(config.nodes) do
		nargs.tasks = nargs.tasks or {}
		for ttag, targs in pairs(nargs.tasks) do
			targs.func = targs.func or pass
            targs.auto = targs.auto or pass
            targs.access = targs.access or "todo"
            
		end
	end
	local graph = {}
	return graph
end

local ccconfig = {
	access = {},
	nodes = {
		node1 = {
			data = {},
			tasks = {
				func = function() end,
				auto = function() end,
				access = "a",
			},
			access = "none",
			apis = {
				func = function() end,
				ttag = "aaa",
			},
		},
		node2 = {},
		node3 = {},
	},
}

return softdep
