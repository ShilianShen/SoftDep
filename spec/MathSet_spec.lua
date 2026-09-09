package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path
local assert = require("luassert")
local MathSet = require("softdep.MathSet")

describe("MathSet", function()
	describe("tab2arr", function()
		it("returns every key regardless of its value", function()
			local arr = MathSet.tab2arr({ a = false, b = 0, c = "value" })
			table.sort(arr)
			assert.same({ "a", "b", "c" }, arr)
		end)

		it("handles an empty table", function()
			assert.same({}, MathSet.tab2arr({}))
		end)

		it("preserves mixed key types and returns an independent array", function()
			local key = {}
			local input = { [key] = "table", [false] = "boolean", [7] = "number" }
			local arr = MathSet.tab2arr(input)
			local seen = {}
			assert.equal(3, #arr)
			for _, value in ipairs(arr) do
				assert.is_nil(seen[value])
				seen[value] = true
			end
			assert.is_true(seen[key])
			assert.is_true(seen[false])
			assert.is_true(seen[7])
			arr[1] = "changed"
			assert.same({ [key] = "table", [false] = "boolean", [7] = "number" }, input)
		end)
	end)

	describe("validation errors", function()
		local cases = {
			{
				"arr2set",
				function()
					MathSet.arr2set(false)
				end,
			},
			{
				"tab2arr",
				function()
					MathSet.tab2arr(false)
				end,
			},
			{
				"tab2set",
				function()
					MathSet.tab2set(false)
				end,
			},
			{
				"set2arr",
				function()
					MathSet.set2arr({ a = false })
				end,
			},
			{
				"set2tab",
				function()
					MathSet.set2tab({ a = false }, {})
				end,
			},
			{
				"count",
				function()
					MathSet.count({ a = false })
				end,
			},
		}

		for _, case in ipairs(cases) do
			it("reports a type validation message for " .. case[1], function()
				local ok, err = pcall(case[2])
				assert.is_false(ok)
				assert.is_string(err)
				assert.matches("expect", err, 1, true)
			end)
		end
	end)

	describe("arr2set", function()
		it("converts an array to a set", function()
			assert.same({
				a = true,
				b = true,
				c = true,
			}, MathSet.arr2set({ "a", "b", "c" }))
		end)

		it("removes duplicate values", function()
			assert.same({
				a = true,
				b = true,
			}, MathSet.arr2set({ "a", "b", "a" }))
		end)

		it("handles an empty array", function()
			assert.same({}, MathSet.arr2set({}))
		end)

		it("rejects non-array input", function()
			assert.has_error(function()
				MathSet.arr2set("abc")
			end)
		end)
	end)

	describe("set2arr", function()
		it("converts a set to an array", function()
			local arr = MathSet.set2arr({
				a = true,
				b = true,
				c = true,
			})

			table.sort(arr)

			assert.same({ "a", "b", "c" }, arr)
		end)

		it("handles an empty set", function()
			assert.same({}, MathSet.set2arr({}))
		end)

		it("rejects invalid sets", function()
			assert.has_error(function()
				MathSet.set2arr({
					a = false,
				})
			end)
		end)
	end)

	describe("set2tab", function()
		it("preserves false values and nested value references", function()
			local nested = {}
			local data = { a = false, b = nested, c = 3 }
			local result = MathSet.set2tab({ a = true, b = true }, data)
			assert.is_false(result.a)
			assert.equal(nested, result.b)
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

			assert.same(
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

		it("omits keys missing from data", function()
			assert.same(
				{
					a = 10,
				},
				MathSet.set2tab({
					a = true,
					missing = true,
				}, {
					a = 10,
				})
			)
		end)

		it("handles an empty set", function()
			assert.same(
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
			assert.same(
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

		it("handles an empty table", function()
			assert.same({}, MathSet.tab2set({}))
		end)

		it("rejects non-table input", function()
			assert.has_error(function()
				MathSet.tab2set(123)
			end)
		end)
	end)

	describe("count", function()
		it("counts set elements", function()
			assert.equal(
				3,
				MathSet.count({
					a = true,
					b = true,
					c = true,
				})
			)
		end)

		it("returns zero for an empty set", function()
			assert.equal(0, MathSet.count({}))
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
