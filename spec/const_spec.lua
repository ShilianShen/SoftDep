package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path

local assert = require("luassert")
local softdep = require("softdep")
local const = softdep.const

describe("const", function()
	it("reads scalar fields and exposes wrapped functions", function()
		local readonly = const({
			boolean = false,
			func = function() end,
			number = 42,
			string = "value",
		})

		assert.is_false(readonly.boolean)
		assert.is_function(readonly.func)
		assert.are.equal(42, readonly.number)
		assert.are.equal("value", readonly.string)
		assert.is_nil(readonly.missing)
	end)

	it("binds method calls to the source", function()
		local source = {
			value = 1,
			increment = function(self, amount)
				self.value = self.value + amount
				return self
			end,
		}
		local readonly = const(source)

		assert.are.equal(source, readonly:increment(2))
		assert.are.equal(3, source.value)
	end)

	it("caches wrappers by source function", function()
		local function getValue(self)
			return self.value
		end

		local first = const({ value = "first", getValue = getValue })
		local second = const({ value = "second", getValue = getValue })

		assert.are.equal(first.getValue, first.getValue)
		assert.are.equal(first.getValue, second.getValue)
		assert.are.equal("first", first:getValue())
		assert.are.equal("second", second:getValue())
	end)

	it("uses a replacement source function", function()
		local source = {
			getValue = function()
				return "old"
			end,
		}
		local readonly = const(source)
		local oldMethod = readonly.getValue

		source.getValue = function()
			return "new"
		end

		assert.are_not.equal(oldMethod, readonly.getValue)
		assert.are.equal("new", readonly:getValue())
	end)

	it("rejects method calls with an invalid receiver", function()
		local method = const({ func = function() end }).func

		assert.has_error(function()
			method({})
		end, "const method called with an invalid receiver")
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
		end)
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
			end)
		end)
	end

	it("protects its metatable", function()
		assert.is_false(getmetatable(const({})))
	end)
end)
