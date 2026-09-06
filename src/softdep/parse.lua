local types = require("softdep.types")
local MathSet = require("softdep.MathSet")
local check = require("softdep.check")
local Access = require("softdep.Access")
local MathGraph = require("softdep.MathGraph")

local function pass(...) end

local firstTypeCheck = types.shape({
	access = types.shape({
		levels = types.map_of(types.string, types.shape({ func = types.func, os = types.boolean })),
		leq = types.array_of(types.array_of(types.string, { length = types.literal(2) })),
	}),
	nodes = types.opt_map_of(
		types.string,
		types.shape({
			atag = types.string:is_optional(),
			tasks = types.opt_map_of(
				types.string,
				types.shape({
					func = types.func:is_optional(),
					auto = types.func:is_optional(),
					atag = types.string:is_optional(),
					parents_c = types.array_of(types.string):is_optional(),
					parents_d = types.map_of(types.string, types.string):is_optional(),
				})
			),
			apis = types.opt_map_of(
				types.string,
				types.shape({
					func = types.func:is_optional(),
					ttag = types.string:is_optional(),
				})
			),
		})
	),
	default = types.shape({
		nodeAtag = types.string,
		taskAtag = types.string,
	}),
})

local finalTypeCheck = types.shape({
	access = types.any,
	nodes = types.map_of(
		types.string,
		types.shape({
			atag = types.string,
			tasks = types.map_of(
				types.string,
				types.shape({
					func = types.func,
					auto = types.func,
					atag = types.string,

					dirty = types.boolean,
					count = types.integer,
				})
			),
			apis = types.map_of(
				types.string,
				types.shape({
					func = types.func:is_optional(),
					ttag = types.string:is_optional(),
				})
			),

			parents_c = types.stringAdjList,

			data = types.table,
			dirty = types.boolean,
			count = types.integer,
			children_c = types.stringAdjList,
			order = types.array_of(types.string),
			data_a = types.map_of(types.string, types.table),
		})
	),

	parents_d = types.map_of(types.string, types.map_of(types.string, types.map_of(types.string, types.string))),

	order = types.array_of(types.string),
	parents_n = types.stringAdjList,
	children_n = types.stringAdjList,
	children_d = types.map_of(types.string, types.map_of(types.string, types.stringSet)),
})

local function deepCopyAsTree(graph)
	if type(graph) ~= "table" then
		return graph
	end

	local result = {}

	for k, v in pairs(graph) do
		result[deepCopyAsTree(k)] = deepCopyAsTree(v)
	end

	return result
end

local function complete(graph)
	graph.nodes = graph.nodes or {}
	for _, node in pairs(graph.nodes) do
		node.atag = node.atag or graph.default.nodeAtag
		node.tasks = node.tasks or {}
		node.apis = node.apis or {}
		for _, task in pairs(node.tasks) do
			task.func = task.func or pass
			task.auto = task.auto or pass
			task.atag = task.atag or graph.default.taskAtag
			task.parents_c = task.parents_c or {}
			task.parents_d = task.parents_d or {}
		end
	end
	graph.default = nil
end

local function contentCheck(graph)
	local atagSet = MathSet.tab2set(graph.access.levels)
	for _, edge in pairs(graph.access.leq) do
		local a, b = edge[1], edge[2]
		check(2, a ~= b)
		check(2, atagSet[a])
		check(2, atagSet[b])

		local A, B = graph.access.levels[a], graph.access.levels[b]
		check(2, A ~= B)
		check(2, (not A.os) or B.os)
	end

	local ntagSet = MathSet.tab2set(graph.nodes)

	for _, node in pairs(graph.nodes) do
		check(2, atagSet[node.atag])
		local ttagSet = MathSet.tab2set(node.tasks)
		for _, task in pairs(node.tasks) do
			check(2, atagSet[task.atag])
			for _, pttag in pairs(task.parents_c) do
				check(2, ttagSet[pttag])
			end
			for _, pntag in pairs(task.parents_d) do
				check(2, ntagSet[pntag])
			end
		end
		for _, api in pairs(node.apis) do
			if api.ttag then
				check(2, ttagSet[api.ttag])
			end
		end
	end
end

local function recombinate(graph)
	graph.parents_d = {}
	for ntag, node in pairs(graph.nodes) do
		node.parents_c = {}
		node.parents_d = {}
		for ttag, task in pairs(node.tasks) do
			node.parents_c[ttag] = MathSet.arr2set(task.parents_c)
			node.parents_d[ttag] = task.parents_d
			task.parents_c = nil
			task.parents_d = nil
		end
		graph.parents_d[ntag] = node.parents_d
		node.parents_d = nil
	end
end

local function make(graph)
	graph.access = Access.newAccess(graph.access.levels, graph.access.leq)
	for _, node in pairs(graph.nodes) do
		node.data = {}
		node.dirty = true
		node.count = 0
		node.children_c = MathGraph.revAdjList(node.parents_c)
		node.order = MathGraph.sort(node.children_c)
		node.data_a = {}

		for atag, level in pairs(graph.access.levels) do
			node.data_a[atag] = level.func(node.data)
		end

		for _, task in pairs(node.tasks) do
			task.dirty = true
			task.count = 0
		end
	end

	graph.parents_n = {}
	for ntag, _ in pairs(graph.parents_d) do
		graph.parents_n[ntag] = {}
	end
	for ntag, _ in pairs(graph.parents_d) do
		for ttag, _ in pairs(graph.parents_d[ntag]) do
			for _, pntag in pairs(graph.parents_d[ntag][ttag]) do
				graph.parents_n[ntag][pntag] = true
			end
		end
	end
	graph.children_n = MathGraph.revAdjList(graph.parents_n)
	graph.order = MathGraph.sort(graph.children_n)

	graph.children_d = {}
	for ntag, _ in pairs(graph.children_n) do
		graph.children_d[ntag] = {}
		for cntag, _ in pairs(graph.children_n[ntag]) do
			graph.children_d[ntag][cntag] = {}
		end
	end
	for ntag, _ in pairs(graph.parents_d) do
		for ttag, _ in pairs(graph.parents_d[ntag]) do
			for _, pntag in pairs(graph.parents_d[ntag][ttag]) do
				graph.children_d[pntag][ntag][ttag] = true
			end
		end
	end
end

local function parse(graph)
	check(2, firstTypeCheck(graph))
	do
		graph = deepCopyAsTree(graph)
		complete(graph)
		contentCheck(graph)
		recombinate(graph)
		make(graph)
	end
	check(2, finalTypeCheck(graph))
	return graph
end

return parse
