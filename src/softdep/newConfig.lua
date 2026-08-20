local deepCopy = require("src.softdep.deepCopy")

local function pass() end

local function newConfig(N)
	N = deepCopy(N)
	local config = {}
	for ntag, node in pairs(N or {}) do
		config[ntag] = {
			data = node.data or {},
			access = node.access or "none",
			tasks = {},
		}
		for ttag, task in pairs(node.tasks or {}) do
			config[ntag].tasks[ttag] = {
				func = task.func or pass,
				access = task.access or "writable",
				args = {},
				parents = {},
			}
			for atag, arg in pairs(task.args or {}) do
				config[ntag].tasks[ttag].args[atag] = arg
			end
			for ptag, parent in pairs(task.parents or {}) do
				config[ntag].tasks[ttag].parents[ptag] = parent
			end
		end
	end
	return config
end

return newConfig
