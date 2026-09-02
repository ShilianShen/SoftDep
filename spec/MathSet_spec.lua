package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path
local assert = require("luassert")
local MathSet = require("softdep.MathSet")

describe("MathSet", function()
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
