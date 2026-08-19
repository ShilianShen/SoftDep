local function kahn(G)
	local infos = {}
	local stack = {}
	local count = 0
	local order = {}

	for _, task in ipairs(G.T) do
		infos[task] = { children = {}, indegree = 0 }
		count = count + 1
	end

	for _, e_c in ipairs(G.E_c) do
		local task1 = e_c.t1
		local task2 = e_c.t2
		table.insert(infos[task1].children, task2)
		infos[task2].indegree = infos[task2].indegree + 1
	end

	for _, task in ipairs(G.T) do
		if infos[task].indegree == 0 then
			table.insert(stack, task)
		end
	end

	for _ = 1, count do
		local task = table.remove(stack)
		for _, subtask in ipairs(infos[task].children) do
			infos[subtask].indegree = infos[subtask].indegree - 1
			if infos[subtask].indegree == 0 then
				table.insert(stack, subtask)
			end
		end
		table.insert(order, task)
	end

	return order
end

local function newEngineGraph(theoryGraph)
	local engineGraph = {}
    engineGraph.tasks = theoryGraph.tasks
    engineGraph.order = kahn(theoryGraph)
	return engineGraph
end

return newEngineGraph
