local deepCopy = require("src.lua.deepCopy")
local decreaseOnly = require("src.lua.decreaseOnly")
local getChildSets = require("src.lua.getChildSets")
local kahn = require("src.lua.kahn")
local MathSet = require("src.lua.MathSet")

local function tick(graph, modules)
	for _, ntag in ipairs(graph.order) do
		local node = graph.nodes[ntag]
		node:tick(graph.parents_n[ntag])
	end
end

local function newGraph(nodes)
	local graph = setmetatable({
		nodes = nodes,
		parents_n = {},
		children_n = {},
		order = false,
		tick = tick,
	}, decreaseOnly)

	local parentSets = {}
	for ntag, node in pairs(graph.nodes) do
		parentSets[ntag] = {}
		for ttag, _ in pairs(node.parents_d) do
			for _, ptag in pairs(node.parents_d[ttag]) do
				parentSets[ntag][ptag] = true
			end
		end
	end
	local childSets = getChildSets(parentSets)

	graph.order = kahn(parentSets, childSets)

	for ntag, _ in pairs(graph.nodes) do
		graph.parents_n[ntag] = MathSet.set2tab(parentSets[ntag], graph.nodes)
		graph.children_n[ntag] = MathSet.set2tab(childSets[ntag], graph.nodes)
	end
	return graph
end

return newGraph
