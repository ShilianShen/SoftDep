local Access = require("softdep.Access")
local types = require("softdep.types")
local check = require("softdep.check")
local MathSet = require("softdep.MathSet")
local parse = require("softdep.parse")
local softdep = {}

local function spreadGraph(graph)
	for _, ntag in ipairs(graph.order) do
		local node = graph.nodes[ntag]

		for _, ttag in ipairs(node.order) do
			local task = node.tasks[ttag]

			if not task.dirty and task.auto(node.data) then
				task.dirty = true
			end

			if task.dirty then
				for cttag, _ in pairs(node.children_c[ttag]) do
					node.tasks[cttag].dirty = true
				end
				-- if graph.access.join(node.atag, task.atag) ~= graph.access.poset[node.atag] then
				-- 	node.dirty = true
				-- end
				node.dirty = true
			end
		end

		if node.dirty then
			for cntag, _ in pairs(graph.children_d[ntag]) do
				local cnode = graph.nodes[cntag]
				for cttag, _ in pairs(graph.children_d[ntag][cntag]) do
					local ctask = cnode.tasks[cttag]
					ctask.dirty = true
				end
			end
		end
	end
end

local function updateGraph(graph)
	for _, ntag in ipairs(graph.order) do
		local node = graph.nodes[ntag]

		for _, ttag in ipairs(node.order) do
			local task = node.tasks[ttag]

			if task.dirty then
				local parents_d = {}
				for pdtag, pntag in pairs(graph.parents_d[ntag][ttag]) do
					local pnode = graph.nodes[pntag]
					parents_d[pdtag] = pnode.data_a[pnode.atag]
				end

				task.func(node.data_a[task.atag], parents_d)
				task.dirty = false
			end
		end

		node.dirty = false
	end
end

local function runGraph(graph)
	spreadGraph(graph)
	updateGraph(graph)
end

local nodeMetatable = {
	__call = function(api, ...)
		if api.func then
			api.func(api._node.data, ...)
		end
		if api.ttag then
			api._node.tasks[api.ttag].dirty = true
		end
	end,
}

function softdep.newGraph(config)
	local graph = parse(config)

	graph.spread = spreadGraph
	graph.update = updateGraph
	graph.run = runGraph

	for _, node in pairs(graph.nodes) do
		for _, api in pairs(node.apis) do
			api._node = node
			setmetatable(api, nodeMetatable)
		end
	end

	return graph
end

return softdep
