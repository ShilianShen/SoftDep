local types = require("softdep.types")
local check = require("softdep.check")
local MathSet = require("softdep.MathSet")
local Config = {}

function MathSet.tab2arr(tab)
	local arr = {}
	for k, _ in pairs(tab) do
		table.insert(arr, k)
	end
	return arr
end

local configShape = types.shape({
	access = types.shape({
		levels = types.map_of(
			types.string,
			types.shape({
				func = types.func,
				os = types.boolean,
			})
		),
		leq = types.array_of(types.array_of(types.string, { length = types.literal(2) })),
	}),
	nodes = types
		.map_of(
			types.string,
			types.shape({
				data = types.table:is_optional(),
				tasks = types
					.map_of(
						types.string,
						types.shape({
							func = types.func:is_optional(),
							auto = types.func:is_optional(),
							atag = types.string:is_optional(),
							parents_c = types.array_of(types.string):is_optional(),
							parents_d = types.map_of(types.string, types.string):is_optional(),
						})
					)
					:is_optional(),
				atag = types.string:is_optional(),
				apis = types
					.map_of(
						types.string,
						types.shape({
							func = types.func:is_optional(),
							ttag = types.string:is_optional(),
						})
					)
					:is_optional(),
			})
		)
		:is_optional(),
	default = types.shape({
		nodeAtag = types.string,
		taskAtag = types.string,
	}),
})

local completedConfigShape = types.shape({
	access = types.any,
	nodes = types.map_of(
		types.string,
		types.shape({
			data = types.table,
			tasks = types.map_of(
				types.string,
				types.shape({
					func = types.func,
					auto = types.func,
					atag = types.string,
					parents_c = types.array_of(types.string),
					parents_d = types.map_of(types.string, types.string),
				})
			),
			atag = types.string,
			apis = types.map_of(
				types.string,
				types.shape({
					func = types.func:is_optional(),
					ttag = types.string:is_optional(),
				})
			),
		})
	),
	default = types.any,
})

local comprehendedConfigShape = function(config)
	local atagArr = MathSet.tab2arr(config.access.levels)
	local ntagArr = MathSet.tab2arr(config.nodes)

	do
		local accessShape = types.shape({
			levels = types.map_of(
				types.string,
				types.shape({
					func = types.func,
					os = types.boolean,
				})
			),
			leq = types.array_of(types.array_of(types.one_of(atagArr), { length = types.literal(2) })),
		})
		local ok, err = accessShape(config.access)
		if not ok then
			return ok, err
		end
	end

	for ntag, node in pairs(config.nodes) do
		local ttagArr = MathSet.tab2arr(node.tasks)
		local nodeShape = types.shape({
			data = types.table,
			tasks = types.map_of(
				types.one_of(ttagArr),
				types.shape({
					func = types.func,
					auto = types.func,
					atag = types.one_of(atagArr),
					parents_c = types.array_of(types.one_of(ttagArr)),
					parents_d = types.map_of(types.string, types.one_of(ntagArr)),
				})
			),
			atag = types.one_of(atagArr),
			apis = types.map_of(
				types.string,
				types.shape({
					func = types.func:is_optional(),
					ttag = types.one_of(ttagArr):is_optional(),
				})
			),
		})
		local ok, err = nodeShape(node)
		if not ok then
			return ok, err
		end
	end

	do
		local defaultShape = types.shape({
			nodeAtag = types.one_of(atagArr),
			taskAtag = types.one_of(atagArr),
		})
		local ok, err = defaultShape(config.default)
		if not ok then
			return ok, err
		end
	end
	return true
end

local function deepCopyUnique(value, active)
	if type(value) ~= "table" then
		return value
	end

	active = active or {}

	if active[value] then
		return active[value]
	end

	local copy = {}
	active[value] = copy

	for k, v in pairs(value) do
		local newKey = deepCopyUnique(k, active)
		local newValue = deepCopyUnique(v, active)
		copy[newKey] = newValue
	end

	active[value] = nil

	setmetatable(copy, getmetatable(value))

	return copy
end

local function pass(...) end

local function copyConfigNodes(configNodes)
	local dataSet = {}
	for ntag, node in pairs(configNodes or {}) do
		if node.data ~= nil then
			check(2, dataSet[node.data] == nil, ("node '%s' shares its data table with another node"):format(ntag))
			dataSet[node.data] = true
		end
	end

	local ndata = {}
	for ntag, node in pairs(configNodes or {}) do
		ndata[ntag] = node.data
		node.data = nil
	end

	local orignal = configNodes
	configNodes = deepCopyUnique(orignal)

	for ntag, node in pairs(configNodes or {}) do
		node.data = ndata[ntag]
		orignal[ntag].data = ndata[ntag]
	end

	return configNodes
end

local function completeConfig(config)
	config.nodes = config.nodes or {}
	for _, node in pairs(config.nodes) do
		node.data = node.data or {}
		node.tasks = node.tasks or {}
		node.atag = node.atag or config.default.nodeAtag
		node.apis = node.apis or {}
		for _, task in pairs(node.tasks) do
			task.func = task.func or pass
			task.auto = task.auto or pass
			task.atag = task.atag or config.default.taskAtag
			task.parents_c = task.parents_c or {}
			task.parents_d = task.parents_d or {}
		end
		for _, api in pairs(node.apis) do
			api.func = api.func or pass
		end
	end
end

function Config.newConfig(config)
	check(2, configShape(config))
	config.nodes = copyConfigNodes(config.nodes)
	completeConfig(config)
	check(2, completedConfigShape(config))
	check(2, comprehendedConfigShape(config))
	return config
end

return Config
