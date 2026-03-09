local mock = require("spec.wow_mock")

-- Fresh namespace for each test file
local GRP = mock.create_namespace()
mock.stub_wow_globals()

-- Load the localization strings (Expression.lua needs them)
mock.load_module("Localization/enUS.lua", GRP)
-- Load the module under test
mock.load_module("Modules/Util.lua", GRP)

-- ==========================================================================
-- Table utilities
-- ==========================================================================

describe("Table_UpdateWithDefaults", function()
    it("fills in missing keys from defaults", function()
        local t = { a = 1 }
        GRP.Table_UpdateWithDefaults(t, { a = 99, b = 2 })
        assert.are.equal(1, t.a)   -- existing key untouched
        assert.are.equal(2, t.b)   -- missing key filled in
    end)

    it("recursively fills nested tables", function()
        local t = { sub = { x = 10 } }
        GRP.Table_UpdateWithDefaults(t, { sub = { x = 99, y = 20 } })
        assert.are.equal(10, t.sub.x)
        assert.are.equal(20, t.sub.y)
    end)

    it("creates missing sub-tables", function()
        local t = {}
        GRP.Table_UpdateWithDefaults(t, { sub = { a = 1 } })
        assert.are.same({ a = 1 }, t.sub)
    end)
end)

describe("Table_Copy_Shallow", function()
    it("copies all key-value pairs", function()
        local original = { a = 1, b = "hello", c = true }
        local copy = GRP.Table_Copy_Shallow(original)
        assert.are.same(original, copy)
    end)

    it("produces an independent table (shallow)", function()
        local original = { a = 1 }
        local copy = GRP.Table_Copy_Shallow(original)
        copy.a = 999
        assert.are.equal(1, original.a)
    end)

    it("shares nested table references", function()
        local inner = { x = 1 }
        local original = { child = inner }
        local copy = GRP.Table_Copy_Shallow(original)
        assert.are.equal(original.child, copy.child) -- same reference
    end)
end)

describe("Table_Copy_Rec", function()
    it("deep copies nested tables", function()
        local original = { a = { b = { c = 42 } } }
        local copy = GRP.Table_Copy_Rec(original)
        assert.are.same(original, copy)
        assert.are_not.equal(original.a, copy.a) -- different references
    end)

    it("copies non-table values directly", function()
        assert.are.equal(5, GRP.Table_Copy_Rec(5))
        assert.are.equal("hi", GRP.Table_Copy_Rec("hi"))
    end)
end)

describe("Table_Subtract", function()
    it("removes elements present in the subtrahend", function()
        local result = GRP.Table_Subtract({ 1, 2, 3, 4, 5 }, { 2, 4 })
        table.sort(result)
        assert.are.same({ 1, 3, 5 }, result)
    end)

    it("returns all elements when subtrahend is empty", function()
        local result = GRP.Table_Subtract({ 10, 20 }, {})
        table.sort(result)
        assert.are.same({ 10, 20 }, result)
    end)

    it("returns empty when all removed", function()
        local result = GRP.Table_Subtract({ 1, 2 }, { 1, 2 })
        assert.are.same({}, result)
    end)
end)

describe("Table_ValuesAsKeys", function()
    it("converts array values into keys set to true", function()
        local result = GRP.Table_ValuesAsKeys({ "a", "b", "c" })
        assert.is_true(result["a"])
        assert.is_true(result["b"])
        assert.is_true(result["c"])
    end)

    it("returns empty table for nil input", function()
        assert.are.same({}, GRP.Table_ValuesAsKeys(nil))
    end)
end)

describe("Table_Count", function()
    it("counts entries in a hash table", function()
        assert.are.equal(3, GRP.Table_Count({ a = 1, b = 2, c = 3 }))
    end)

    it("returns 0 for nil input", function()
        assert.are.equal(0, GRP.Table_Count(nil))
    end)

    it("returns 0 for empty table", function()
        assert.are.equal(0, GRP.Table_Count({}))
    end)
end)

describe("Table_Mean", function()
    it("calculates the arithmetic mean", function()
        assert.are.equal(2, GRP.Table_Mean({ a = 1, b = 2, c = 3 }))
    end)

    it("returns 0 for empty table", function()
        assert.are.equal(0, GRP.Table_Mean({}))
    end)
end)

describe("Table_Median", function()
    it("returns middle value for odd count", function()
        assert.are.equal(2, GRP.Table_Median({ a = 1, b = 2, c = 3 }))
    end)

    it("returns average of middle two for even count", function()
        assert.are.equal(2.5, GRP.Table_Median({ a = 1, b = 2, c = 3, d = 4 }))
    end)

    it("returns 0 for empty table", function()
        assert.are.equal(0, GRP.Table_Median({}))
    end)
end)

describe("Table_Invert", function()
    it("swaps keys and values", function()
        local result = GRP.Table_Invert({ a = 1, b = 2 })
        assert.are.equal("a", result[1])
        assert.are.equal("b", result[2])
    end)
end)

-- ==========================================================================
-- String utilities
-- ==========================================================================

describe("String_TrimWhitespace", function()
    it("strips leading and trailing spaces", function()
        assert.are.equal("hello", GRP.String_TrimWhitespace("  hello  "))
    end)

    it("strips tabs and mixed whitespace", function()
        assert.are.equal("hi", GRP.String_TrimWhitespace("\t hi \n"))
    end)

    it("handles already-trimmed strings", function()
        assert.are.equal("ok", GRP.String_TrimWhitespace("ok"))
    end)
end)

describe("String_ExtractNumbers", function()
    it("pulls out all integers from a string", function()
        assert.are.same({ 10, 20, 3 }, GRP.String_ExtractNumbers("level 10 to 20 with 3 bosses"))
    end)

    it("returns empty table when no numbers present", function()
        assert.are.same({}, GRP.String_ExtractNumbers("no numbers here"))
    end)
end)

describe("NotEmpty / Empty", function()
    it("NotEmpty returns true for non-empty strings", function()
        assert.is_true(GRP.NotEmpty("hello"))
    end)

    it("NotEmpty returns false for empty string", function()
        assert.is_falsy(GRP.NotEmpty(""))
    end)

    it("NotEmpty returns false for nil", function()
        assert.is_falsy(GRP.NotEmpty(nil))
    end)

    it("Empty is the inverse of NotEmpty", function()
        assert.is_true(GRP.Empty(""))
        assert.is_true(GRP.Empty(nil))
        assert.is_falsy(GRP.Empty("x"))
    end)
end)

describe("String_RemoveBrackets", function()
    it("removes parenthesized text", function()
        assert.are.equal("Grim Batol", GRP.String_RemoveBrackets("Grim Batol (Mythic)"))
    end)

    it("removes square brackets", function()
        assert.are.equal("test", GRP.String_RemoveBrackets("test [info]"))
    end)

    it("removes nested brackets", function()
        assert.are.equal("clean", GRP.String_RemoveBrackets("clean (a (b)) [c]"))
    end)

    it("normalizes leftover whitespace", function()
        assert.are.equal("a b", GRP.String_RemoveBrackets("a   (x)   b"))
    end)
end)

describe("String_Tokenize", function()
    it("splits a string into lowercase tokens", function()
        local tokens = GRP.String_Tokenize("Hello World")
        assert.are.same({ "hello", "world" }, tokens)
    end)

    it("applies an optional filter function", function()
        local tokens = GRP.String_Tokenize("the big dog", function(w) return w ~= "the" end)
        assert.are.same({ "big", "dog" }, tokens)
    end)

    it("normalizes colons and dashes into spaces", function()
        local tokens = GRP.String_Tokenize("Tazavesh: Straßen")
        assert.are.same({ "tazavesh", "straßen" }, tokens)
    end)
end)

-- ==========================================================================
-- Similarity functions
-- ==========================================================================

describe("JaccardIndex", function()
    it("returns 1.0 for identical sets", function()
        assert.are.equal(1.0, GRP.JaccardIndex({ "a", "b" }, { "a", "b" }))
    end)

    it("returns 0.0 for disjoint sets", function()
        assert.are.equal(0.0, GRP.JaccardIndex({ "a" }, { "b" }))
    end)

    it("returns 1/3 for one shared element out of three total", function()
        local result = GRP.JaccardIndex({ "a", "b" }, { "a", "c" })
        assert.is_true(math.abs(result - 1/3) < 0.0001)
    end)

    it("returns 0.5 when two of three elements overlap", function()
        assert.are.equal(0.5, GRP.JaccardIndex({ "a", "b" }, { "a" }))
    end)

    it("returns 0 for two empty sets", function()
        assert.are.equal(0, GRP.JaccardIndex({}, {}))
    end)
end)

describe("IsMostLikelySameInstance", function()
    it("matches identical names", function()
        assert.is_true(GRP.IsMostLikelySameInstance("Grim Batol", "Grim Batol"))
    end)

    it("matches when only difference is bracketed suffix", function()
        assert.is_true(GRP.IsMostLikelySameInstance(
            "Der Smaragdgrüne Alptraum",
            "Der Smaragdgrüne Alptraum (Mythisch)"
        ))
    end)

    it("matches similar dungeon names", function()
        assert.is_true(GRP.IsMostLikelySameInstance(
            "Wasserwerke",
            "Die Wasserwerke"
        ))
    end)

    it("does not match completely different instances", function()
        assert.is_false(GRP.IsMostLikelySameInstance("Grim Batol", "The Necrotic Wake"))
    end)
end)
