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
		dirty = true,
		count = 0,
	}

	assert(types.task(task))

	return task
end

function Task.runTask(task, data, parents_d)
	check(2, task.dirty, "task not dirty")

	task.func(data, parents_d)
	task.count = task.count + 1
	task.dirty = false
end

return Task
