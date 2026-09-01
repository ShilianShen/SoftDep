package.path = "src/lua/?.lua;" .. "src/lua/?/init.lua;" .. package.path
local kahn = require("softdep.kahn")
local assert = require("luassert")

local function set(...)
    local result = {}
    for _, value in ipairs({...}) do
        result[value] = true
    end
    return result
end

local function indexOf(order)
    local result = {}
    for i, vtag in ipairs(order) do
        result[vtag] = i
    end
    return result
end

describe("kahn", function()

    it("sorts a simple dependency chain", function()
        -- A -> B -> C
        local parentSets = {
            A = set(),
            B = set("A"),
            C = set("B"),
        }

        local order = kahn(parentSets)

        assert.are.same({"A", "B", "C"}, order)
    end)

    it("sorts a DAG with multiple dependencies", function()
        -- A ----> C ----> D
        --   \-> B ----/
        --
        -- C depends on A
        -- B depends on A
        -- D depends on B and C

        local parentSets = {
            A = set(),
            B = set("A"),
            C = set("A"),
            D = set("B", "C"),
        }

        local order = kahn(parentSets)
        local pos = indexOf(order)

        assert.are.equal(4, #order)

        assert.is_truthy(pos.A)
        assert.is_truthy(pos.B)
        assert.is_truthy(pos.C)
        assert.is_truthy(pos.D)

        assert.is_true(pos.A < pos.B)
        assert.is_true(pos.A < pos.C)
        assert.is_true(pos.B < pos.D)
        assert.is_true(pos.C < pos.D)
    end)

    it("handles multiple independent nodes", function()
        local parentSets = {
            A = set(),
            B = set(),
            C = set(),
        }

        local order = kahn(parentSets)
        local pos = indexOf(order)

        assert.are.equal(3, #order)

        assert.is_truthy(pos.A)
        assert.is_truthy(pos.B)
        assert.is_truthy(pos.C)
    end)

    it("handles disconnected DAG components", function()
        -- A -> B
        --
        -- C -> D

        local parentSets = {
            A = set(),
            B = set("A"),
            C = set(),
            D = set("C"),
        }

        local order = kahn(parentSets)
        local pos = indexOf(order)

        assert.are.equal(4, #order)

        assert.is_true(pos.A < pos.B)
        assert.is_true(pos.C < pos.D)
    end)

    it("handles a single node", function()
        local parentSets = {
            A = set(),
        }

        local order = kahn(parentSets)

        assert.are.same({"A"}, order)
    end)

    it("handles an empty graph", function()
        local parentSets = {}

        local order = kahn(parentSets)

        assert.are.same({}, order)
    end)

    it("rejects a simple cycle", function()
        -- A -> B -> A

        local parentSets = {
            A = set("B"),
            B = set("A"),
        }

        assert.has_error(function()
            kahn(parentSets)
        end, "not a DAG")
    end)

    it("rejects a longer cycle", function()
        -- A -> B -> C -> A

        local parentSets = {
            A = set("C"),
            B = set("A"),
            C = set("B"),
        }

        assert.has_error(function()
            kahn(parentSets)
        end, "not a DAG")
    end)

    it("rejects a graph containing a cycle even if another component is valid", function()
        -- Valid:
        -- A -> B
        --
        -- Cycle:
        -- C <-> D

        local parentSets = {
            A = set(),
            B = set("A"),
            C = set("D"),
            D = set("C"),
        }

        assert.has_error(function()
            kahn(parentSets)
        end, "not a DAG")
    end)

end)