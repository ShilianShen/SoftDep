local MathSet = require("softdep.MathSet")
local check = require("softdep.check")
local MathGraph = require("softdep.MathGraph")

local function validate(graph)
	local atagSet = MathSet.tab2set(graph.access.levels)
	for _, edge in pairs(graph.access.lt) do
		local a, b = edge[1], edge[2]
		check(2, a ~= b, "access relation must not be reflexive: " .. a)
		check(2, atagSet[a], "unknown access level in lt: " .. a)
		check(2, atagSet[b], "unknown access level in lt: " .. b)

		local A, B = graph.access.levels[a], graph.access.levels[b]
		check(2, A ~= B, "access relation endpoints must have distinct definitions: " .. a .. " <= " .. b)
		check(
			2,
			(not A.os) or B.os,
			"order-sensitive access level must not be below order-insensitive level: " .. a .. " <= " .. b
		)
	end
	do
		local adjList = MathGraph.edges2AdjList(atagSet, graph.access.lt)
		check(2, MathGraph.isDAG(adjList), "access relations must form a DAG")
	end

	local ntagSet = MathSet.tab2set(graph.nodes)

	for ntag, node in pairs(graph.nodes) do
		check(2, atagSet[node.atag], "unknown access level for node " .. ntag .. ": " .. node.atag)
		check(2, not graph.access.levels[node.atag].os, "node access level must be order-insensitive: " .. node.atag)

		local ttagSet = MathSet.tab2set(node.tasks)
		for ttag, task in pairs(node.tasks) do
			check(2, atagSet[task.atag], "unknown access level for task " .. ntag .. "." .. ttag .. ": " .. task.atag)
			for _, pttag in pairs(task.parents_c) do
				check(2, ttagSet[pttag], "unknown control parent for task " .. ntag .. "." .. ttag .. ": " .. pttag)
			end
			for _, pntag in pairs(task.parents_d) do
				check(2, ntagSet[pntag], "unknown data parent for task " .. ntag .. "." .. ttag .. ": " .. pntag)
			end
		end
		for apiTag, api in pairs(node.apis) do
			check(2, atagSet[api.atag], "unknown access level for API " .. ntag .. "." .. apiTag .. ": " .. api.atag)
			if api.ttag then
				check(2, ttagSet[api.ttag], "unknown task for API " .. ntag .. "." .. apiTag .. ": " .. api.ttag)
			end
		end
	end
    return graph
end

return validate