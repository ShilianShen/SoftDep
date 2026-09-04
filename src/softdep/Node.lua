local Access = require("softdep.Access")
local check = require("softdep.check")
local types = require("softdep.types")
local MathGraph = require("softdep.MathGraph")
local Node = {}

function Node.new(args)
	check(2, types.newNodeArgs(args))
	check(2, Access.levels[args.access], "no2")
	check(2, not Access.levels[args.access].os, "no222")

	for _, api in pairs(args.apis) do
		check(2, args.tasks[api.ttag], "no24243")
	end

	local node = {
		data = args.data,
		tasks = args.tasks,
		access = args.access,
		apis = args.apis,
		dirty = true,
		parents_d = args.parents_d,
		parents_c = args.parents_c,
	}

	node.data_a = {}
	for atag, level in pairs(Access.levels) do
		node.data_a[atag] = level.func(node.data)
	end

	node.children_c = MathGraph.revAdjList(args.parents_c)
	node.order = MathGraph.sort(node.children_c)

	assert(types.node(node), "nou8258979")

	return node
end

function Node.run(node) end

return Node
