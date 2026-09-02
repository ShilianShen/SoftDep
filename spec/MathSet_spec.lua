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
			}, MathSet.arr2set({ "a", "b", "a", "b" }))
		end)

		it("handles an empty array", function()
			assert.same({}, MathSet.arr2set({}))
		end)

		it("supports non-string values", function()
			assert.same({
				[1] = true,
				[2] = true,
				foo = true,
			}, MathSet.arr2set({ 1, 2, "foo" }))
		end)

		it("rejects non-arrays", function()
			assert.has_error(function()
				MathSet.arr2set("invalid")
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

			assert.are.equal(3, #arr)
			assert.is_true(MathSet.equal(MathSet.arr2set(arr), { a = true, b = true, c = true }))
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
			local set = {
				a = true,
				c = true,
			}

			local data = {
				a = 10,
				b = 20,
				c = 30,
			}

			assert.same({
				a = 10,
				c = 30,
			}, MathSet.set2tab(set, data))
		end)

		it("ignores data keys outside the set", function()
			assert.same({
				a = 1,
			}, MathSet.set2tab({ a = true }, { a = 1, b = 2 }))
		end)

		it("handles missing data values", function()
			assert.same({}, MathSet.set2tab({ missing = true }, {}))
		end)

		it("handles an empty set", function()
			assert.same(
				{},
				MathSet.set2tab({}, {
					a = 1,
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

		it("returns zero for an empty set", function()
			assert.are.equal(0, MathSet.count({}))
		end)

		it("supports non-string keys", function()
			assert.are.equal(
				3,
				MathSet.count({
					[1] = true,
					[2] = true,
					foo = true,
				})
			)
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
			assert.is_true(MathSet.equal({ a = true, b = true }, { b = true, a = true }))
		end)

		it("returns true for empty sets", function()
			assert.is_true(MathSet.equal({}, {}))
		end)

		it("returns false when the second set has extra elements", function()
			assert.is_false(MathSet.equal({ a = true }, { a = true, b = true }))
		end)

		it("returns false when the first set has extra elements", function()
			assert.is_false(MathSet.equal({ a = true, b = true }, { a = true }))
		end)

		it("returns false for different sets with the same size", function()
			assert.is_false(MathSet.equal({ a = true, b = true }, { a = true, c = true }))
		end)

		it("rejects invalid arguments", function()
			assert.has_error(function()
				MathSet.equal({ a = false }, {})
			end)

			assert.has_error(function()
				MathSet.equal({}, { a = false })
			end)
		end)
	end)

	describe("isSubset", function()
		it("returns true for a proper subset", function()
			assert.is_true(MathSet.isSubset({ a = true }, { a = true, b = true }))
		end)

		it("returns true for equal sets", function()
			assert.is_true(MathSet.isSubset({ a = true, b = true }, { a = true, b = true }))
		end)

		it("returns true for the empty subset", function()
			assert.is_true(MathSet.isSubset({}, { a = true }))
		end)

		it("returns true when both sets are empty", function()
			assert.is_true(MathSet.isSubset({}, {}))
		end)

		it("returns false when an element is missing", function()
			assert.is_false(MathSet.isSubset({ a = true, c = true }, { a = true, b = true }))
		end)

		it("returns false when the subset is larger", function()
			assert.is_false(MathSet.isSubset({ a = true, b = true }, { a = true }))
		end)

		it("rejects invalid arguments", function()
			assert.has_error(function()
				MathSet.isSubset({ a = false }, {})
			end)

			assert.has_error(function()
				MathSet.isSubset({}, { a = false })
			end)
		end)
	end)

	describe("allSubsets", function()
		local function collect(iterator)
			local result = {}

			for subset in iterator do
				result[#result + 1] = subset
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

		it("enumerates the empty set", function()
			local subsets = collect(MathSet.allSubsets({}))

			assert.are.equal(1, #subsets)
			assert.same({}, subsets[1])
		end)

		it("enumerates all subsets of a single-element set", function()
			local subsets = collect(MathSet.allSubsets({
				a = true,
			}))

			assert.are.equal(2, #subsets)
			assert.is_true(contains(subsets, {}))
			assert.is_true(contains(subsets, { a = true }))
		end)

		it("enumerates every subset", function()
			local subsets = collect(MathSet.allSubsets({
				a = true,
				b = true,
				c = true,
			}))

			assert.are.equal(8, #subsets)

			local expected = {
				{},
				{ a = true },
				{ b = true },
				{ c = true },
				{ a = true, b = true },
				{ a = true, c = true },
				{ b = true, c = true },
				{ a = true, b = true, c = true },
			}

			for _, subset in ipairs(expected) do
				assert.is_true(contains(subsets, subset), "expected subset was not generated")
			end
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

		it("finishes after all subsets are generated", function()
			local iterator = MathSet.allSubsets({
				a = true,
				b = true,
			})

			for _ = 1, 4 do
				assert.is_table(iterator())
			end

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
end)
