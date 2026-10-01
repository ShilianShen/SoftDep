local bind = require("softdep.bind")
local types = require("softdep.types")
local check = require("softdep.check")
local build = require("softdep.build")
local softdep = {}

local function deepCopyAsTree(graph)
	if type(graph) ~= "table" then
		return graph
	end

	local result = {}

	for k, v in pairs(graph) do
		result[deepCopyAsTree(k)] = deepCopyAsTree(v)
	end

	return result
end

local firstTypeCheck = types.shape({
	access = types.shape({
		levels = types.map_of(types.string, types.shape({ func = types.func, os = types.boolean })),
		lt = types.array_of(types.array_of(types.string, { length = types.literal(2) })),
	}),
	nodes = types.opt_map_of(
		types.string,
		types.shape({
			atag = types.string:is_optional(),
			tasks = types.opt_map_of(
				types.string,
				types.shape({
					func = types.func:is_optional(),
					auto = types.func:is_optional(),
					atag = types.string:is_optional(),
					parents_c = types.array_of(types.string):is_optional(),
					parents_d = types.map_of(types.string, types.string):is_optional(),
				})
			),
			apis = types.opt_map_of(
				types.string,
				types.shape({
					func = types.func:is_optional(),
					ttag = types.string:is_optional(),
					atag = types.string:is_optional(),
				})
			),
		})
	),
	default = types.shape({
		nodeAtag = types.string,
		taskAtag = types.string,
		apiAtag = types.string,
	}),
})

local finalTypeCheck = types.shape({
	access = types.any,
	nodes = types.map_of(
		types.string,
		types.shape({
			atag = types.string,
			tasks = types.map_of(
				types.string,
				types.shape({
					func = types.func,
					auto = types.func,
					atag = types.string,

					dirty = types.boolean,
					count = types.integer,
				})
			),
			apis = types.map_of(
				types.string,
				types.shape({
					func = types.func:is_optional(),
					ttag = types.string:is_optional(),
					atag = types.string,
				})
			),

			parents_c = types.stringAdjList,

			data = types.table,
			dirty = types.boolean,
			count = types.integer,
			children_c = types.stringAdjList,
			order = types.array_of(types.string),
			data_a = types.map_of(types.string, types.table),
		})
	),

	parents_d = types.map_of(types.string, types.map_of(types.string, types.map_of(types.string, types.string))),

	order = types.array_of(types.string),
	parents_n = types.stringAdjList,
	children_n = types.stringAdjList,
	children_d = types.map_of(types.string, types.map_of(types.string, types.stringSet)),
})

function softdep.newGraph(config)
	check(2, firstTypeCheck(config))

	config = deepCopyAsTree(config)
	local graph = build(config)

	check(2, finalTypeCheck(graph))
	bind(graph)
	return graph
end

return softdep
