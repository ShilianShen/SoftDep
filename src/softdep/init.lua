local Access = require("softdep.Access")
local Graph = require("softdep.Graph")
local Node = require("softdep.Node")
local Task = require("softdep.Task")
local types = require("softdep.types")
local check = require("softdep.check")
local MathSet = require("softdep.MathSet")

local softdep = {}

local function deepCopyUnique(value, active)
	if type(value) ~= "table" then
		return value
	end

	active = active or {}

	-- 只用于处理当前递归路径上的循环引用
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

	-- 如果需要保留 metatable
	setmetatable(copy, getmetatable(value))

	return copy
end

local function pass(...) end

-- 类型检查, 补全, 内容检查, 实现
local function makeConfigNodes(configNodes, systemAccess)
	-- 暂存
	local ndata = {}
	local dataSet = {}
	for ntag, node in pairs(configNodes) do
		ndata[ntag] = node.data
		check(2, dataSet[node.data] == nil, "jaiorgoauergargargawgrh.      d")
		configNodes[ntag].data = nil
	end
	dataSet = nil

	-- 补全
	configNodes = deepCopyUnique(configNodes or {})
	for ntag, node in pairs(configNodes) do
		node.data = ndata[ntag] or {}
		node.tasks = node.tasks or {}
		node.atag = node.atag or systemAccess.bot
		node.apis = node.apis or {}
		for ttag, task in pairs(node.tasks) do
			task.func = task.func or pass
			task.auto = task.auto or pass
			task.atag = task.atag or systemAccess.top
			task.parents_c = task.parents_c or {}
			task.parents_d = task.parents_d or {}
		end
		for itag, api in pairs(node.apis) do
			api.func = api.func or pass
			api.ttag = api.ttag or nil
		end
	end

	-- 内容检查nodes
	local atagArr = MathSet.set2arr(MathSet.tab2set(systemAccess.levels))
	local ntagArr = MathSet.set2arr(MathSet.tab2set(configNodes))

	for ntag, node in pairs(configNodes) do
		local ttagArr = MathSet.set2arr(MathSet.tab2set(node.tasks))

		local taskShape = types.shape({
			func = types.func,
			auto = types.func,
			atag = types.one_of(atagArr),
			parents_c = types.array_of(types.one_of(ttagArr)),
			parents_d = types.map_of(types.string, types.one_of(ntagArr)),
		})

		local nodeShape = types.shape({
			data = types.table,
			tasks = types.map_of(types.one_of(ttagArr), taskShape),
			atag = types.one_of(atagArr),
			apis = types.map_of(
				types.string,
				types.shape({
					func = types.func,
					ttag = types.one_of(ttagArr):is_optional(),
				})
			),
		})

		check(2, nodeShape(node))
	end
end

function softdep.newGraph(config)
	check(2, types.configGraph(config))

	local system = {}
	system.access = Access.newAccess(config.access.levels, config.access.leq)
	makeConfigNodes(config.nodes, system.access)
end

return softdep
