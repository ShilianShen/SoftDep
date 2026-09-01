package.path = "src/lua/?.lua;" .. "src/lua/?/init.lua;" .. package.path
local assert = require("luassert")
local adopt = require("softdep.adopt")

describe("adopt", function()
	it("converts parent sets to child sets", function()
		local parentSets = {
			a = {},
			b = {
				a = true,
			},
			c = {
				a = true,
				b = true,
			},
		}

		assert.same({
			a = {
				b = true,
				c = true,
			},
			b = {
				c = true,
			},
			c = {},
		}, adopt(parentSets))
	end)

	it("handles empty parent sets", function()
		assert.same({}, adopt({}))
	end)

	it("creates empty child sets for nodes without children", function()
		local parentSets = {
			a = {},
			b = {},
			c = {},
		}

		assert.same({
			a = {},
			b = {},
			c = {},
		}, adopt(parentSets))
	end)

	it("supports multiple children for the same parent", function()
		local parentSets = {
			parent = {},
			child1 = {
				parent = true,
			},
			child2 = {
				parent = true,
			},
		}

		assert.same({
			parent = {
				child1 = true,
				child2 = true,
			},
			child1 = {},
			child2 = {},
		}, adopt(parentSets))
	end)

	it("supports multiple parents for the same child", function()
		local parentSets = {
			parent1 = {},
			parent2 = {},
			child = {
				parent1 = true,
				parent2 = true,
			},
		}

		assert.same({
			parent1 = {
				child = true,
			},
			parent2 = {
				child = true,
			},
			child = {},
		}, adopt(parentSets))
	end)

	it("supports self references", function()
		local parentSets = {
			a = {
				a = true,
			},
		}

		assert.same({
			a = {
				a = true,
			},
		}, adopt(parentSets))
	end)

	it("rejects an undeclared parent", function()
		assert.has_error(function()
			adopt({
				child = {
					parent = true,
				},
			})
		end)
	end)

	it("rejects invalid parent set values", function()
		assert.has_error(function()
			adopt({
				a = {},
				b = {
					a = false,
				},
			})
		end)
	end)

	it("rejects non-string node names", function()
		assert.has_error(function()
			adopt({
				[1] = {},
			})
		end)
	end)

	it("rejects non-string parent names", function()
		assert.has_error(function()
			adopt({
				a = {},
				b = {
					[1] = true,
				},
			})
		end)
	end)

	it("rejects non-table input", function()
		assert.has_error(function()
			adopt("invalid")
		end)
	end)
end)
