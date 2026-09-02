local Access = {}

local poset = {
	elements = {
		none = function(a)
			return {}
		end,
		readonly = function(a)
			local b = setmetatable({}, {
				__index = a,
				__newindex = function()
					assert(false)
				end,
				__metatable = false,
			})
			return b
		end,
		writable = function(a)
			return a
		end,
	},
	le = {
		none = { none = true, readonly = true, writable = true },
		readonly = { none = false, readonly = true, writable = true },
		writable = { none = false, readonly = false, writable = true },
	},
}

local mt = {
	__eq = function(a, b)
		return rawequal(a, b)
	end,
	__lt = function(a, b)
		return poset.le[a.key][b.key] and not rawequal(a, b)
	end,
}

for key, func in pairs(poset.elements) do
	Access[key] = setmetatable({
		key = key,
		func = func,
	}, mt)
end

return Access
