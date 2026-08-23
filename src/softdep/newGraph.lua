local deepCopy = require("src.softdep.deepCopy")
local decreaseOnly = require("src.softdep.decreaseOnly")
local getChildren = require("src.softdep.getChildren")
local kahn = require("src.softdep.kahn")

local function set2arr(set)
	local arr = {}
	for k, _ in pairs(set) do
		table.insert(arr, k)
	end
	return arr
end

local function tick(graph, modules)
	for _, ntag in ipairs(graph.order) do
		local node = graph.N[ntag]
		node:tick(graph.parents_n[ntag])
	end
end

local function newGraph(nodes)
	local graph = setmetatable({
		N = nodes,
		parents_n = {},
		children_n = false,
		order = false,
		tick = tick,
	}, decreaseOnly)

	for ntag, node in pairs(graph.N) do
		local set = {}
		for ttag, _ in pairs(node.parents_d) do
			for _, ptag in pairs(node.parents_d[ttag]) do
				set[ptag] = true
			end
		end
		graph.parents_n[ntag] = set2arr(set)
	end

	graph.children_n = getChildren(graph.parents_n)
	graph.order = kahn(graph.parents_n, graph.children_n)
	return graph
end

return newGraph
