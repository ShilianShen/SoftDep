local check = {}

local function fail(path, expected)
	return false, path .. " must be " .. expected
end

local function checkFields(value, path, fields)
	if type(value) ~= "table" then
		return fail(path, "a table")
	end

	for key, _ in pairs(value) do
		if fields[key] == nil then
			return false, path .. " contains an unknown field: " .. tostring(key)
		end
	end

	return true
end

local function checkOptionalType(value, expected, path)
	if value ~= nil and type(value) ~= expected then
		return fail(path, expected)
	end
	return true
end

local function checkMap(value, path, checkValue)
	if type(value) ~= "table" then
		return fail(path, "a table")
	end

	for key, item in pairs(value) do
		if type(key) ~= "string" then
			return fail(path .. " key", "a string")
		end

		local ok, result = checkValue(item, path .. "." .. key)
		if not ok then
			return false, result
		end
	end

	return true
end

local function checkArray(value, path, checkValue, length)
	if type(value) ~= "table" then
		return fail(path, "an array")
	end

	local count = 0
	for key, _ in pairs(value) do
		if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
			return fail(path, "an array")
		end
		count = count + 1
	end

	if length ~= nil and count ~= length then
		return false, path .. " must contain exactly " .. length .. " items"
	end

	for index = 1, count do
		local item = value[index]
		if item == nil then
			return fail(path, "a dense array")
		end

		local ok, result = checkValue(item, path .. "[" .. index .. "]")
		if not ok then
			return false, result
		end
	end

	return true
end

local function checkString(value, path)
	if type(value) ~= "string" then
		return fail(path, "a string")
	end
	return true
end

local function checkAccessLevel(level, path)
	local ok, result = checkFields(level, path, { func = true, os = true })
	if not ok then
		return false, result
	end
	if type(level.func) ~= "function" then
		return fail(path .. ".func", "a function")
	end
	if type(level.os) ~= "boolean" then
		return fail(path .. ".os", "a boolean")
	end
	return true
end

local function checkAccess(access, path)
	local ok, result = checkFields(access, path, { levels = true, lt = true })
	if not ok then
		return false, result
	end

	ok, result = checkMap(access.levels, path .. ".levels", checkAccessLevel)
	if not ok then
		return false, result
	end

	return checkArray(access.lt, path .. ".lt", function(edge, edgePath)
		return checkArray(edge, edgePath, checkString, 2)
	end)
end

local function checkTask(task, path)
	local ok, result = checkFields(task, path, {
		func = true,
		auto = true,
		atag = true,
		parents_c = true,
		parents_d = true,
		back = true,
	})
	if not ok then
		return false, result
	end

	for _, field in ipairs({ "func", "auto" }) do
		ok, result = checkOptionalType(task[field], "function", path .. "." .. field)
		if not ok then
			return false, result
		end
	end

	if type(task.atag) ~= "string" then
		return fail(path .. ".atag", "a string")
	end
	if type(task.back) ~= "boolean" then
		return fail(path .. ".back", "a boolean")
	end

	if task.parents_c ~= nil then
		ok, result = checkArray(task.parents_c, path .. ".parents_c", checkString)
		if not ok then
			return false, result
		end
	end

	if task.parents_d ~= nil then
		return checkMap(task.parents_d, path .. ".parents_d", checkString)
	end

	return true
end

local function checkApi(api, path)
	local ok, result = checkFields(api, path, { func = true, ttag = true, atag = true, dirty = true })
	if not ok then
		return false, result
	end

	ok, result = checkOptionalType(api.func, "function", path .. ".func")
	if not ok then
		return false, result
	end
	ok, result = checkOptionalType(api.ttag, "string", path .. ".ttag")
	if not ok then
		return false, result
	end
	if type(api.atag) ~= "string" then
		return fail(path .. ".atag", "a string")
	end
	if type(api.dirty) ~= "boolean" then
		return fail(path .. ".dirty", "a boolean")
	end
	return true
end

local function checkNode(node, path)
	local ok, result = checkFields(node, path, { atag = true, tasks = true, apis = true })
	if not ok then
		return false, result
	end

	if type(node.atag) ~= "string" then
		return fail(path .. ".atag", "a string")
	end

	if node.tasks ~= nil then
		ok, result = checkMap(node.tasks, path .. ".tasks", checkTask)
		if not ok then
			return false, result
		end
	end

	if node.apis ~= nil then
		return checkMap(node.apis, path .. ".apis", checkApi)
	end

	return true
end

---@param declaration any
---@return boolean, string|nil
function check.graphDeclaration(declaration)
	local ok, result = checkFields(declaration, "graph declaration", {
		access = true,
		nodes = true,
	})
	if not ok then
		return false, result
	end

	ok, result = checkAccess(declaration.access, "graph declaration.access")
	if not ok then
		return false, result
	end

	if declaration.nodes ~= nil then
		return checkMap(declaration.nodes, "graph declaration.nodes", checkNode)
	end

	return true
end

return check
