local check = require("softdep.check")
local Access = require("softdep.Access")
local MathGraph = require("softdep.MathGraph")

local function materialize(graph)
	graph.access = Access.newAccess(graph.access.levels, graph.access.lt)
	for ntag, node in pairs(graph.nodes) do
		node.data = {}
		node.dirty = true
		node.count = 0
		node.children_c = MathGraph.revAdjList(node.parents_c)
		check(2, MathGraph.isDAG(node.children_c, true), "control dependencies must form a DAG in node: " .. ntag)
		node.order = MathGraph.sort(node.children_c, true)
		node.data_a = {}

		for atag, level in pairs(graph.access.levels) do
			node.data_a[atag] = level.func(node.data)
			check(
				2,
				type(node.data_a[atag]) == "table",
				"access function must return a table for node "
					.. ntag
					.. ", level "
					.. atag
					.. "; got "
					.. type(node.data_a[atag])
			)
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
	check(2, MathGraph.isDAG(graph.children_n, false), "node data dependencies must form a DAG")
	graph.order = MathGraph.sort(graph.children_n, false)

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

return materialize