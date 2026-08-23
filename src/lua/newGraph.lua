local deepCopy = require("src.lua.deepCopy")
local decreaseOnly = require("src.lua.decreaseOnly")
local getChildSets = require("src.lua.getChildSets")
local kahn = require("src.lua.kahn")
local MathSet = require("src.lua.MathSet")

local function tick(graph, modules)
	for _, ntag in ipairs(graph.order) do
		local node = graph.nodes[ntag]
		node:tick(graph.parents_n[ntag])
		if node.dirty then
			-- todo
			node.dirty = false
		end
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

	local parentSets_n = {}
	for ntag, node in pairs(graph.nodes) do
		parentSets_n[ntag] = {}
		for ttag, _ in pairs(node.parents_d) do
			for _, ptag in pairs(node.parents_d[ttag]) do
				parentSets_n[ntag][ptag] = true
			end
		end
	end
	local childSets_n = getChildSets(parentSets_n)

	local children_d -- todo
	graph.order = kahn(parentSets_n, childSets_n)

	for ntag, _ in pairs(graph.nodes) do
		graph.parents_n[ntag] = MathSet.set2tab(parentSets_n[ntag], graph.nodes)
		graph.children_n[ntag] = MathSet.set2tab(childSets_n[ntag], graph.nodes)
	end
	return graph
end

return newGraph
