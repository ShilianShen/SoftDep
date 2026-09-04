local types = require("softdep.tableshape").types

types.set = types.map_of(types.any, types.literal(true))
types.adjList = types.map_of(types.any, types.set)

types.stringSet = types.map_of(types.string, types.literal(true))
types.stringArray = types.array_of(types.string)
types.stringAdjList = types.map_of(types.string, types.stringSet)

types.parentSets = types.map_of(types.string, types.stringSet)
types.childSets = types.map_of(types.string, types.stringSet)

types.accessLevels = types.map_of(
	types.string,
	types.shape({
		func = types.func,
		os = types.boolean,
	})
)
types.accessLeq = types.array_of(types.array_of(types.string))

types.newTaskArgs = types.shape({
	func = types.func,
	auto = types.func,
	access = types.string,
})
types.task = types.shape({
	func = types.func,
	auto = types.func,
	dirty = types.boolean,
	count = types.integer,
	access = types.string,
})

types.newNodeArgs = types.shape({
	data = types.table,
	tasks = types.map_of(types.string, types.task),
	access = types.string,
	apis = types.map_of(
		types.string,
		types.shape({
			func = types.func:is_optional(),
			ttag = types.string:is_optional(),
		})
	),
	parents_c = types.stringAdjList,
})
types.node = types.shape({
	data = types.table,
	tasks = types.map_of(types.string, types.task),
	access = types.string,
	apis = types.map_of(
		types.string,
		types.shape({
			func = types.func:is_optional(),
			ttag = types.string:is_optional(),
		})
	),
	data_a = types.map_of(types.string, types.table),
	order = types.array_of(types.string),
	dirty = types.boolean,
	parents_c = types.stringAdjList,
	children_c = types.stringAdjList,
})

types.newGraphArgs = types.shape({
	nodes = types.map_of(types.string, types.node),
	parents_n = types.stringAdjList,
})
types.newGraphArgs = types.shape({
	nodes = types.map_of(types.string, types.node),
	ready = types.boolean,
	order = types.array_of(types.string),
	children_n = types.stringAdjList,
	parents_n = types.stringAdjList,
})

------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------

types.configAccess = types.shape({
	levels = types.map_of(
		types.string,
		types.shape({
			func = types.func,
			os = types.boolean,
		})
	),
	leq = types.array_of(types.string),
})
types.configTask = types.shape({
	func = types.func:is_optional(),
	auto = types.func:is_optional(),
	atag = types.string:is_optional(),
	parents_c = types.array_of(types.string):is_optional(),
	parents_d = types.map_of(types.string, types.string):is_optional(),
})
types.configNode = types.shape({
	data = types.table:is_optional(),
	tasks = types.map_of(types.string, types.configTask):is_optional(),
	atag = types.string:is_optional(),
	apis = types
		.map_of(
			types.string,
			types.shape({
				func = types.func,
				ttag = types.string,
			})
		)
		:is_optional(),
})
types.configGraph = types.shape({
	access = types.configAccess,
	nodes = types.map_of(types.string, types.configNode):is_optional(),
})

------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------

types.systemAccess = types.any
types.systemTask = types.shape({
	func = types.func,
	auto = types.func,
	access = types.string,
	dirty = types.boolean,
	count = types.integer,
})
types.systemNode = types.shape({
	data = types.table,
	tasks = types.map_of(types.string, types.systemTask),
	access = types.string,
	apis = types.map_of(
		types.string,
		types.shape({
			func = types.func,
			ttag = types.string,
		})
	),
	data_a = types.any,
	parents_c = types.array_of(types.string),
	order = types.any,
	children_c = types.any,
	dirty = types.boolean,
})
types.systemGraph = types.shape({
	nodes = types.map_of(types.string, types.configNode),
	parents_d = types.map_of(types.string, types.string),
	children_d = types.any,
	parents_n = types.any,
	children_n = types.any,
	order = types.any,
	ready = types.boolean,
})

return types
