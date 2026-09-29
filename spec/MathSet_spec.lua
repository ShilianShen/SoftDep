package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path

local assert = require("luassert")
local MathSet = require("softdep.MathSet")

describe("MathSet", function()
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

		it("does not modify the array and returns independent sets", function()
			local arr = { "a", "b", "a" }
			local first = MathSet.arr2set(arr)
			local second = MathSet.arr2set(arr)
			first.a = nil

			assert.are.same({ "a", "b", "a" }, arr)
			assert.are.same({ a = true, b = true }, second)
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

		it("omits keys missing from data", function()
			assert.are.same({ a = 10 }, MathSet.set2tab({ a = true, missing = true }, { a = 10 }))
		end)

		it("handles an empty set", function()
			assert.are.same(
				{},
				MathSet.set2tab({}, {
					a = 10,
				})
			)
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
	end)
end)
