local deepCopy = require("src.softdep.deepCopy")

local function get_E_d(nodes)
	local E_d = {}
	for _, node in pairs(nodes) do
		for _, task in pairs(node.tasks) do
			for atag, antag in pairs(task.args) do
				local anode = nodes[antag]
				table.insert(E_d, { n = anode, d = anode.data, t = task, a = atag })
			end
		end
	end
	return E_d
end

local function get_E_c(nodes, E_d)
	local E_c = {}
	for _, node in pairs(nodes) do
		for _, task in pairs(node.tasks) do
			for _, pttag in ipairs(task.parents) do
				local ptask = node.tasks[pttag]
				table.insert(E_c, { t1 = ptask, t2 = task })
			end
		end
	end
	for _, e_d in ipairs(E_d) do
		local node = e_d.n
		for _, task in pairs(node.tasks) do
			if task.access == "writable" then
				table.insert(E_c, { t1 = task, t2 = e_d.t })
			end
		end
	end
	return E_c
end

local function get_access(nodes, E_d)
	local access = {}
	for _, node in pairs(nodes) do
		local data = node.data
		access[data] = {}
		for _, task in pairs(node.tasks) do
			access[data][task] = task.access
		end
	end
	for _, e_d in ipairs(E_d) do
		local node = e_d.n
		local data = e_d.d
		for _, task in pairs(node.tasks) do
			access[data][task] = node.access
		end
	end
	return access
end

local function clean(G, nodes)
	for _, node in pairs(nodes) do
		for _, task in pairs(node.tasks) do
			table.insert(G.E_d, { n = node, d = node.data, t = task, a = 0 })
			task.args = nil
			task.parents = nil
			task.access = nil
		end
	end
	for _, e_d in ipairs(G.E_d) do
		e_d.n = nil
	end
end

local function newTheory(nodes)
	nodes = deepCopy(nodes)
	local G = { D = {}, T = {} }

	for _, node in pairs(nodes) do
		table.insert(G.D, node.data)
		for _, task in pairs(node.tasks) do
			table.insert(G.T, task)
		end
	end

	G.E_d = get_E_d(nodes)
	G.E_c = get_E_c(nodes, G.E_d)
	G.access = get_access(nodes, G.E_d)

	clean(G, nodes)

	return G
end

return newTheory
