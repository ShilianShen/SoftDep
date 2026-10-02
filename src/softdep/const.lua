---@type table<table, table>
local sources = setmetatable({}, { __mode = "k" })

local function index(B, key)
	local value = sources[B][key]

	if type(value) == "table" then
		error(("cannot access table-valued field %q from const table"):format(tostring(key)), 2)
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
