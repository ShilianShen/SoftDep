local deepCopy = require("src.lua.deepCopy")
local decreaseOnly = require("src.lua.decreaseOnly")
local getChildSets = require("src.lua.getChildSets")
local kahn = require("src.lua.kahn")
local MathSet = require("src.lua.MathSet")

local function spread(graph, modules)
	for _, ntag in ipairs(graph.order) do
		local node = graph.nodes[ntag]
		if node:spread() then
			for _, task in ipairs(graph.children_d[ntag]) do
				task.dirty = true
			end
		end
	end
end

local function run(graph, modules)
	for _, ntag in ipairs(graph.order) do
		local node = graph.nodes[ntag]
		node:run(graph.parents_n[ntag])
	end
end

local function tick(graph, modules)
	graph:spread()
	graph:run()
end

local function newGraph(nodes)
	local graph = setmetatable({
		nodes = nodes,
		parents_n = {},
		children_n = {},
		children_d = {},
		order = false,
		run = run,
		spread = spread,
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

	for ntag, _ in pairs(graph.nodes) do
		graph.children_d[ntag] = {}
	end
	for _, node in pairs(graph.nodes) do
		for ttag, task in pairs(node.tasks) do
			for _, dtag in pairs(node.parents_d[ttag]) do
				table.insert(graph.children_d[dtag], task)
			end
		end
	end

	graph.order = kahn(parentSets_n, childSets_n)

	for ntag, _ in pairs(graph.nodes) do
		graph.parents_n[ntag] = MathSet.set2tab(parentSets_n[ntag], graph.nodes)
		graph.children_n[ntag] = MathSet.set2tab(childSets_n[ntag], graph.nodes)
	end
	return graph
end

return newGraph
