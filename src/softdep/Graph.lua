local Access = require("softdep.Access")
local check = require("softdep.check")
local types = require("softdep.types")
local MathGraph = require("softdep.MathGraph")
local Graph = {}

function Graph.newGraph(args)
	check(2, types.newGraphArgs(args))

	local graph = {
		nodes = args.nodes,
		ready = false,
		parents_n = args.parents_n,
	}

    graph.children_n = MathGraph.revAdjList(graph.parents_n)

    graph.order = MathGraph.sort(graph.children_n)

	assert(types.graph(graph))

	return graph
end

function Graph.runGraph(graph) end

return Graph
