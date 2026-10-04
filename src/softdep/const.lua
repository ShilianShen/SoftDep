---@type table<table, table>
local sources = setmetatable({}, { __mode = "k" })

---@type table<function, function>
local methods = setmetatable({}, { __mode = "k" })

---@param func function
---@return function
local function bindMethod(func)
	local method = methods[func]

	if method == nil then
		method = function(B, ...)
			local A = sources[B]

			if A == nil then
				error("const method called with an invalid receiver", 2)
			end

			return func(A, ...)
		end

		methods[func] = method
	end

	return method
end

local function index(B, key)
	local value = sources[B][key]

	if type(value) == "table" then
		error(("cannot access table-valued field %q from const table"):format(tostring(key)), 2)
	end

	if type(value) == "function" then
		return bindMethod(value)
	end

	return value
end

local function newindex(_, key, _)
	error(("cannot modify const table field %q"):format(tostring(key)), 2)
end

local mt = {
	__index = index,
	__newindex = newindex,
	__metatable = false,
}

---@param A table
---@return table
local function const(A)
	local B = {}
	sources[B] = A
	return setmetatable(B, mt)
end

return const
