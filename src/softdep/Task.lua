local Access = require("softdep.Access")
local check = require("softdep.check")
local types = require("softdep.types")
local Task = {}

function Task.newTask(args)
	check(2, types.newTaskArgs(args))
	check(2, Access.levels[args.access], "no")

	local task = {
		func = args.func,
		auto = args.auto,
		access = args.access,
		dirty = false,
		count = 0,
	}

	assert(types.task(task))

	return task
end

return Task
