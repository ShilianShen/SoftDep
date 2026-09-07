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
			{
				"equal first argument",
				function()
					MathSet.equal({ a = false }, {})
				end,
			},
			{
				"equal second argument",
				function()
					MathSet.equal({}, { a = false })
				end,
			},
			{
				"isSubset first argument",
				function()
					MathSet.isSubset({ a = false }, {})
				end,
			},
			{
				"isSubset second argument",
				function()
					MathSet.isSubset({}, { a = false })
				end,
			},
			{
				"allSubsets",
				function()
					MathSet.allSubsets({ a = false })
				end,
			},
			{
				"cup first argument",
				function()
					MathSet.cup({ a = false }, {})
				end,
			},
			{
				"cup later argument",
				function()
					MathSet.cup({}, {}, { a = false })
				end,
			},
			{
				"cap first argument",
				function()
					MathSet.cap({ a = false }, {})
				end,
			},
			{
				"cap later argument",
				function()
					MathSet.cap({}, {}, { a = false })
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

	describe("equal", function()
		it("returns true for equal sets", function()
			assert.is_true(MathSet.equal({
				a = true,
				b = true,
			}, {
				b = true,
				a = true,
			}))
		end)

		it("returns true for two empty sets", function()
			assert.is_true(MathSet.equal({}, {}))
		end)

		it("returns false when the first set has extra elements", function()
			assert.is_false(MathSet.equal({
				a = true,
				b = true,
			}, {
				a = true,
			}))
		end)

		it("returns false when the second set has extra elements", function()
			assert.is_false(MathSet.equal({
				a = true,
			}, {
				a = true,
				b = true,
			}))
		end)

		it("returns false for disjoint sets", function()
			assert.is_false(MathSet.equal({
				a = true,
			}, {
				b = true,
			}))
		end)

		it("rejects invalid input", function()
			assert.has_error(function()
				MathSet.equal({}, {
					a = false,
				})
			end)
		end)
	end)

	describe("isSubset", function()
		it("returns true for a proper subset", function()
			assert.is_true(MathSet.isSubset({
				a = true,
			}, {
				a = true,
				b = true,
			}))
		end)

		it("returns true when both sets are equal", function()
			assert.is_true(MathSet.isSubset({
				a = true,
				b = true,
			}, {
				a = true,
				b = true,
			}))
		end)

		it("returns true for the empty subset", function()
			assert.is_true(MathSet.isSubset({}, {
				a = true,
			}))
		end)

		it("returns true for two empty sets", function()
			assert.is_true(MathSet.isSubset({}, {}))
		end)

		it("returns false when an element is missing from the superset", function()
			assert.is_false(MathSet.isSubset({
				a = true,
				c = true,
			}, {
				a = true,
				b = true,
			}))
		end)

		it("returns false when the candidate subset is larger", function()
			assert.is_false(MathSet.isSubset({
				a = true,
				b = true,
			}, {
				a = true,
			}))
		end)
	end)

	describe("allSubsets", function()
		it("keeps iterators and yielded subsets independent", function()
			local input = { a = true }
			local first = MathSet.allSubsets(input)
			local second = MathSet.allSubsets(input)
			local empty = first()
			empty.extra = true
			assert.same({ a = true }, first())
			assert.is_nil(first())
			assert.same({}, second())
			assert.same({ a = true }, second())
			assert.is_nil(second())
			assert.same({ a = true }, input)
		end)

		local function collect(iterator)
			local result = {}

			while true do
				local value = iterator()
				if value == nil then
					break
				end

				result[#result + 1] = value
			end

			return result
		end

		local function contains(sets, expected)
			for _, set in ipairs(sets) do
				if MathSet.equal(set, expected) then
					return true
				end
			end

			return false
		end

		it("returns the empty set for an empty input set", function()
			local subsets = collect(MathSet.allSubsets({}))

			assert.equal(1, #subsets)
			assert.same({}, subsets[1])
		end)

		it("generates all subsets", function()
			local subsets = collect(MathSet.allSubsets({
				a = true,
				b = true,
			}))

			assert.equal(4, #subsets)

			assert.is_true(contains(subsets, {}))
			assert.is_true(contains(subsets, {
				a = true,
			}))
			assert.is_true(contains(subsets, {
				b = true,
			}))
			assert.is_true(contains(subsets, {
				a = true,
				b = true,
			}))
		end)

		it("generates exactly 2^n subsets", function()
			local subsets = collect(MathSet.allSubsets({
				a = true,
				b = true,
				c = true,
			}))

			assert.equal(8, #subsets)
		end)

		it("does not generate duplicate subsets", function()
			local subsets = collect(MathSet.allSubsets({
				a = true,
				b = true,
				c = true,
			}))

			for i = 1, #subsets do
				for j = i + 1, #subsets do
					assert.is_false(MathSet.equal(subsets[i], subsets[j]))
				end
			end
		end)

		it("returns nil after exhaustion", function()
			local iterator = MathSet.allSubsets({
				a = true,
			})

			assert.is_table(iterator())
			assert.is_table(iterator())
			assert.is_nil(iterator())
			assert.is_nil(iterator())
		end)

		it("rejects invalid sets", function()
			assert.has_error(function()
				MathSet.allSubsets({
					a = false,
				})
			end)
		end)
	end)

	describe("cup", function()
		it("returns the union of two sets", function()
			assert.same(
				{
					a = true,
					b = true,
					c = true,
				},
				MathSet.cup({
					a = true,
					b = true,
				}, {
					b = true,
					c = true,
				})
			)
		end)

		it("supports multiple sets", function()
			assert.same(
				{
					a = true,
					b = true,
					c = true,
				},
				MathSet.cup({
					a = true,
				}, {
					b = true,
				}, {
					c = true,
				})
			)
		end)

		it("supports one set", function()
			assert.same(
				{
					a = true,
				},
				MathSet.cup({
					a = true,
				})
			)
		end)

		it("returns an empty set with no arguments", function()
			assert.same({}, MathSet.cup())
		end)

		it("does not mutate its arguments", function()
			local set1 = {
				a = true,
			}
			local set2 = {
				b = true,
			}

			MathSet.cup(set1, set2)

			assert.same({
				a = true,
			}, set1)

			assert.same({
				b = true,
			}, set2)
		end)

		it("rejects invalid sets", function()
			assert.has_error(function()
				MathSet.cup({}, {
					a = false,
				})
			end)
		end)
	end)

	describe("cap", function()
		it("returns an empty intersection with an empty operand in any position", function()
			assert.same({}, MathSet.cap({}, { a = true }, { a = true }))
			assert.same({}, MathSet.cap({ a = true }, {}, { a = true }))
			assert.same({}, MathSet.cap({ a = true }, { a = true }, {}))
		end)

		it("returns an independent set for a single operand", function()
			local input = { a = true }
			local result = MathSet.cap(input)
			result.a = nil
			assert.same({ a = true }, input)
		end)

		it("returns the intersection of two sets", function()
			assert.same(
				{
					b = true,
				},
				MathSet.cap({
					a = true,
					b = true,
				}, {
					b = true,
					c = true,
				})
			)
		end)

		it("supports multiple sets", function()
			assert.same(
				{
					b = true,
				},
				MathSet.cap({
					a = true,
					b = true,
					c = true,
				}, {
					b = true,
					c = true,
					d = true,
				}, {
					b = true,
					e = true,
				})
			)
		end)

		it("returns an empty set for disjoint sets", function()
			assert.same(
				{},
				MathSet.cap({
					a = true,
				}, {
					b = true,
				})
			)
		end)

		it("supports one set", function()
			assert.same(
				{
					a = true,
					b = true,
				},
				MathSet.cap({
					a = true,
					b = true,
				})
			)
		end)

		it("does not mutate its arguments", function()
			local set1 = {
				a = true,
				b = true,
			}
			local set2 = {
				b = true,
				c = true,
			}

			MathSet.cap(set1, set2)

			assert.same({
				a = true,
				b = true,
			}, set1)

			assert.same({
				b = true,
				c = true,
			}, set2)
		end)

		it("rejects invalid sets", function()
			assert.has_error(function()
				MathSet.cap({
					a = true,
				}, {
					b = false,
				})
			end)
		end)
	end)
end)
