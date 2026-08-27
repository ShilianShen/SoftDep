local deepCopy = require("softdep.deepCopy")
local decreaseOnly = require("softdep.decreaseOnly")
local getChildSets = require("softdep.getChildSets")
local kahn = require("softdep.kahn")
local MathSet = require("softdep.MathSet")

local function spread(graph)
	assert(graph.ready)
	for _, ntag in ipairs(graph.order) do
		local node = graph.nodes[ntag]
		node.dirty = node:spread()
		if node.dirty then
			for _, task in ipairs(graph.children_d[ntag]) do
				task.dirty = true
			end
		end
	end
end

local function newModule(graph, ntags)
	assert(graph.ready)
	local module = {}
	module.nodes = MathSet.set2tab(MathSet.arr2set(ntags), graph.nodes)
	module.parents_n = {}

	for ntag, _ in pairs(module.nodes) do
		for ptag, _ in pairs(graph.parents_n[ntag]) do
			if module.nodes[ptag] == nil then
				module.parents_n[ptag] = true
			end
		end
	end
	module.parents_n = MathSet.set2tab(module.parents_n, graph.nodes)

	return module
end

local function run(graph, modules)
	assert(graph.ready)
	if modules ~= nil then
		local clean = true
		for _, pnode in pairs(modules.parents_n) do
			clean = clean and pnode
		end
		assert(clean)
	end

	for _, ntag in ipairs(graph.order) do
		if modules == nil or modules.nodes[ntag] ~= nil then
			local node = graph.nodes[ntag]
			node:run(graph.parents_n[ntag])
			node.dirty = false
		end
	end
end

local function tick(graph, modules)
	assert(graph.ready)
	graph:spread()
	graph:run(modules)
end

local function load(graph)
	graph.ready = false
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
	graph.ready = true
end

local function extend(graph, ntag, node)
	assert(graph.nodes[ntag] == nil)
	graph.nodes[ntag] = node
	graph:load()
end

local function newGraph(nodes)
	local graph = {
		nodes = nodes,
		parents_n = {},
		children_n = {},
		children_d = {},
		order = false,
		run = run,
		spread = spread,
		tick = tick,
		newModule = newModule,
		ready = false,
		load = load,
		extend = extend,
	}
	graph:load()
	return graph
end

return newGraph
