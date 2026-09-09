package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path

local assert = require("luassert")
local MathSet = require("softdep.MathSet")

describe("MathSet", function()
	describe("validation errors", function()
		local cases = {
			{
				"arr2set",
				function()
					MathSet.arr2set(false)
				end,
				"MathSet.arr2set: expected arr to be an array with consecutive integer keys starting at 1",
			},
			{
				"tab2set",
				function()
					MathSet.tab2set(false)
				end,
				"MathSet.tab2set: expected tab to be a table",
			},
			{
				"set2tab",
				function()
					MathSet.set2tab({ a = false }, {})
				end,
				"MathSet.set2tab: expected set to be a table with all values equal to true",
			},
			{
				"count",
				function()
					MathSet.count({ a = false })
				end,
				"MathSet.count: expected set to be a table with all values equal to true",
			},
		}

		for _, case in ipairs(cases) do
			it("reports a type validation message for " .. case[1], function()
				assert.has_error(case[2], case[3])
			end)
		end
	end)

	for _, name in ipairs({ "arr2set", "tab2set", "set2tab", "count" }) do
		it("rejects a missing first argument for " .. name, function()
			assert.has_error(function()
				MathSet[name](nil, {})
			end)
		end)
	end

	describe("arr2set", function()
		it("converts an array to a set", function()
			assert.are.same({
				a = true,
				b = true,
				c = true,
			}, MathSet.arr2set({ "a", "b", "c" }))
		end)

		it("removes duplicate values", function()
			assert.are.same({
				a = true,
				b = true,
			}, MathSet.arr2set({ "a", "b", "a" }))
		end)

		it("handles an empty array", function()
			assert.are.same({}, MathSet.arr2set({}))
		end)

		it("preserves distinct value types and table identity", function()
			local first, second = {}, {}
			local result = MathSet.arr2set({ 1, "1", false, true, first, second, first })

			assert.are.same(
				{ [1] = true, ["1"] = true, [false] = true, [true] = true, [first] = true, [second] = true },
				result
			)
			assert.is_true(result[first])
			assert.is_true(result[second])
		end)

		it("does not modify the array and returns independent sets", function()
			local arr = { "a", "b", "a" }
			local first = MathSet.arr2set(arr)
			local second = MathSet.arr2set(arr)
			first.a = nil

			assert.are.same({ "a", "b", "a" }, arr)
			assert.are.same({ a = true, b = true }, second)
		end)

		it("rejects tables with named keys or gaps in their indices", function()
			assert.has_error(function()
				MathSet.arr2set({ a = "value" })
			end)
			assert.has_error(function()
				MathSet.arr2set({ [2] = "value" })
			end)
		end)

		it("rejects non-array input", function()
			assert.has_error(function()
				MathSet.arr2set("abc")
			end)
		end)
	end)

	describe("set2tab", function()
		it("preserves false values and nested value references", function()
			local nested = {}
			local data = { a = false, b = nested, c = 3 }
			local result = MathSet.set2tab({ a = true, b = true }, data)
			assert.is_false(result.a)
			assert.are.equal(nested, result.b)
			assert.is_nil(result.c)
			result.a = true
			assert.is_false(data.a)
		end)

		it("selects values whose keys are in the set", function()
			local data = {
				a = 10,
				b = 20,
				c = 30,
			}

			assert.are.same(
				{
					a = 10,
					c = 30,
				},
				MathSet.set2tab({
					a = true,
					c = true,
				}, data)
			)
		end)

		it("rejects keys missing from data", function()
			assert.has_error(function()
				MathSet.set2tab({ a = true, missing = true }, { a = 10 })
			end, "MathSet.set2tab: missing key in data: missing")
		end)

		it("reports missing numeric, boolean and table keys", function()
			for _, key in ipairs({ 42, false, {} }) do
				assert.has_error(function()
					MathSet.set2tab({ [key] = true }, {})
				end, "MathSet.set2tab: missing key in data: " .. tostring(key))
			end
		end)

		it("rejects non-table data even for an empty set", function()
			assert.has_error(function()
				MathSet.set2tab({}, false)
			end, "MathSet.set2tab: expected data to be a table")
			assert.has_error(function()
				MathSet.set2tab({})
			end, "MathSet.set2tab: expected data to be a table")
		end)

		it("selects numeric, boolean and table keys", function()
			local key = {}
			local set = { [3] = true, [false] = true, [key] = true }
			local data = { [3] = 0, [false] = "", [key] = "value", extra = 1 }
			local result = MathSet.set2tab(set, data)

			assert.are.same({ [3] = 0, [false] = "", [key] = "value" }, result)
			assert.are.equal("value", result[key])
			assert.are.same({ [3] = true, [false] = true, [key] = true }, set)
			assert.are.same({ [3] = 0, [false] = "", [key] = "value", extra = 1 }, data)
		end)

		it("handles an empty set", function()
			assert.are.same(
				{},
				MathSet.set2tab({}, {
					a = 10,
				})
			)
		end)

		it("rejects invalid sets", function()
			assert.has_error(function()
				MathSet.set2tab({
					a = 1,
				}, {})
			end)
		end)
	end)

	describe("tab2set", function()
		it("converts table keys to a set", function()
			assert.are.same(
				{
					a = true,
					b = true,
					c = true,
				},
				MathSet.tab2set({
					a = 10,
					b = false,
					c = "value",
				})
			)
		end)

		it("uses numeric, boolean and table keys regardless of their values", function()
			local key = {}
			local result = MathSet.tab2set({ [0] = false, [3] = 0, [false] = "", [key] = {} })

			assert.are.same({ [0] = true, [3] = true, [false] = true, [key] = true }, result)
			assert.is_true(result[key])
		end)

		it("does not modify the table and returns an independent set", function()
			local tab = { a = 10, b = false }
			local result = MathSet.tab2set(tab)
			result.a = nil
			result.b = "changed"

			assert.are.same({ a = 10, b = false }, tab)
		end)

		it("handles an empty table", function()
			assert.are.same({}, MathSet.tab2set({}))
		end)

		it("rejects non-table input", function()
			assert.has_error(function()
				MathSet.tab2set(123)
			end)
		end)
	end)

	describe("count", function()
		it("counts set elements", function()
			assert.are.equal(
				3,
				MathSet.count({
					a = true,
					b = true,
					c = true,
				})
			)
		end)

		it("counts sparse numeric and mixed keys without modifying the set", function()
			local key = {}
			local set = { [0] = true, [100] = true, [false] = true, [key] = true, a = true }

			assert.are.equal(5, MathSet.count(set))
			assert.are.same({ [0] = true, [100] = true, [false] = true, [key] = true, a = true }, set)
		end)

		it("returns zero for an empty set", function()
			assert.are.equal(0, MathSet.count({}))
		end)

		it("rejects invalid sets", function()
			assert.has_error(function()
				MathSet.count({
					a = false,
				})
			end)
		end)
	end)
end)
