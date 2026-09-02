package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path
local assert = require("luassert")
local MathSet = require("softdep.MathSet")

describe("MathSet", function()
	describe("arr2set", function()
		it("converts an array to a set", function()
			local result = MathSet.arr2set({ "a", "b", "c" })

			assert.same({
				a = true,
				b = true,
				c = true,
			}, result)
		end)

		it("removes duplicate values", function()
			local result = MathSet.arr2set({ "a", "b", "a", "b" })

			assert.same({
				a = true,
				b = true,
			}, result)
		end)

		it("handles an empty array", function()
			assert.same({}, MathSet.arr2set({}))
		end)

		it("supports non-string values", function()
			local key = {}

			local result = MathSet.arr2set({
				"a",
				1,
				false,
				key,
			})

			assert.is_true(result["a"])
			assert.is_true(result[1])
			assert.is_true(result[false])
			assert.is_true(result[key])
		end)

		it("rejects non-array input", function()
			assert.has_error(function()
				MathSet.arr2set("invalid")
			end)
		end)
	end)

	describe("set2arr", function()
		it("converts a set to an array", function()
			local set = {
				a = true,
				b = true,
				c = true,
			}

			local result = MathSet.set2arr(set)

			assert.same(set, MathSet.arr2set(result))
		end)

		it("handles an empty set", function()
			assert.same({}, MathSet.set2arr({}))
		end)

		it("rejects values other than true", function()
			assert.has_error(function()
				MathSet.set2arr({
					a = true,
					b = false,
				})
			end)
		end)

		it("rejects non-table input", function()
			assert.has_error(function()
				MathSet.set2arr("invalid")
			end)
		end)
	end)

	describe("set2tab", function()
		it("selects data entries whose keys are in the set", function()
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

		it("handles an empty set", function()
			local data = {
				a = 10,
				b = 20,
			}

			assert.same({}, MathSet.set2tab({}, data))
		end)

		it("ignores keys missing from data", function()
			local set = {
				a = true,
				b = true,
			}

			local data = {
				a = 10,
			}

			assert.same({
				a = 10,
			}, MathSet.set2tab(set, data))
		end)

		it("rejects an invalid set", function()
			assert.has_error(function()
				MathSet.set2tab({
					a = 1,
				}, {})
			end)
		end)
	end)

	describe("count", function()
		it("returns the number of elements", function()
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

		it("supports arbitrary key types", function()
			local key = {}

			assert.equal(
				4,
				MathSet.count({
					["a"] = true,
					[1] = true,
					[false] = true,
					[key] = true,
				})
			)
		end)

		it("rejects an invalid set", function()
			assert.has_error(function()
				MathSet.count({
					a = false,
				})
			end)
		end)
	end)
end)
