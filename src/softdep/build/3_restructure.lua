local MathSet = require("softdep.MathSet")

local function restructure(graph)
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
    return graph
end

return restructure