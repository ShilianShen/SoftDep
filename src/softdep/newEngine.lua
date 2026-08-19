local deepCopy = require("src.softdep.deepCopy")

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

local function tick(engine)
	local queue = {}
	for _, task in ipairs(engine.order) do
		if task.dirty then
			for _, subtask in ipairs(task.children) do
				subtask.dirty = true
			end
			table.insert(queue, task)
		end
	end
	for _, task in ipairs(queue) do
		task.func(task.data, task.args)
		task.dirty = false
	end
end

local function newEngine(theory)
	theory = deepCopy(theory)
	local engine = {
		D = theory.D,
		T = theory.T,
	}
	for _, t in ipairs(engine.T) do
		t.args = {}
		t.data = false
		t.children = {}
		t.dirty = true
	end
	for _, e_d in ipairs(theory.E_d) do
		local t = e_d.t
		if e_d.a == 0 then
			t.data = e_d.d
		else
			t.args[e_d.a] = e_d.d
		end
	end
	for _, e_c in ipairs(theory.E_c) do
		local t1 = e_c.t1
		local t2 = e_c.t2
		table.insert(t1.children, t2)
	end
	engine.order = kahn(theory)
	engine.tick = tick
	return engine
end

return newEngine
