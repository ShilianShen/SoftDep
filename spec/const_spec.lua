package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path

local assert = require("luassert")
local const = require("softdep.const")

describe("const", function()
	it("reads non-table fields from the source", function()
		local func = function() end
		local readonly = const({
			boolean = false,
			func = func,
			number = 42,
			string = "value",
		})

		assert.is_false(readonly.boolean)
		assert.are.equal(func, readonly.func)
		assert.are.equal(42, readonly.number)
		assert.are.equal("value", readonly.string)
		assert.is_nil(readonly.missing)
	end)

	it("reflects changes made to the source", function()
		local source = { value = 1 }
		local readonly = const(source)

		source.value = 2
		source.added = "new"

		assert.are.equal(2, readonly.value)
		assert.are.equal("new", readonly.added)
	end)

	it("keeps proxies bound to their own sources", function()
		local first = const({ value = "first" })
		local second = const({ value = "second" })

		assert.are.equal("first", first.value)
		assert.are.equal("second", second.value)
	end)

	it("rejects access to table-valued fields", function()
		local readonly = const({ nested = {} })

		assert.has_error(function()
			return readonly.nested
		end, 'cannot access table-valued field "nested" from const table')
	end)

	for _, case in ipairs({
		{ "existing fields", { value = 1 }, "value", 2 },
		{ "missing fields", {}, "missing", true },
		{ "field deletion", { value = 1 }, "value", nil },
	}) do
		it("rejects modification of " .. case[1], function()
			local readonly = const(case[2])

			assert.has_error(function()
				readonly[case[3]] = case[4]
			end, ('cannot modify const table field "%s"'):format(case[3]))
		end)
	end

	it("protects its metatable", function()
		assert.is_false(getmetatable(const({})))
	end)
end)
