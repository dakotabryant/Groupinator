local mock = require("spec.wow_mock")

local GRP = mock.create_namespace()
mock.stub_wow_globals()

mock.load_module("Localization/enUS.lua", GRP)
mock.load_module("Modules/Util.lua", GRP)
mock.load_module("Modules/Expression.lua", GRP)

-- Capture popup messages instead of calling the (non-existent) WoW UI
local last_popup = nil
GRP.StaticPopup_Show = function(_, msg)
    last_popup = msg
end

-- Helper: build a typical group environment table
local function make_env(overrides)
    local env = {
        -- difficulty booleans
        normal = false, heroic = false, mythic = false, mythicplus = false,
        -- role counts
        tanks = 0, heals = 0, dps = 0, members = 0,
        -- misc
        ilvl = 0, age = 0, voice = false,
    }
    if overrides then
        for k, v in pairs(overrides) do env[k] = v end
    end
    return env
end

describe("DoesPassThroughFilter", function()

    before_each(function()
        last_popup = nil
    end)

    -- ======================================================================
    -- Correct expressions
    -- ======================================================================

    it("returns true when expression matches the environment", function()
        local env = make_env({ mythic = true, tanks = 0, members = 4 })
        assert.is_true(GRP.DoesPassThroughFilter(env, "mythic and tanks==0 and members==4"))
    end)

    it("returns false when expression does not match", function()
        local env = make_env({ mythic = true, tanks = 1, members = 4 })
        assert.is_false(GRP.DoesPassThroughFilter(env, "mythic and tanks==0 and members==4"))
    end)

    it("handles simple boolean variables", function()
        assert.is_true(GRP.DoesPassThroughFilter(make_env({ mythic = true }), "mythic"))
        assert.is_false(GRP.DoesPassThroughFilter(make_env({ mythic = false }), "mythic"))
    end)

    it("supports numeric comparisons", function()
        local env = make_env({ members = 3, tanks = 1, heals = 1, dps = 1 })
        assert.is_true(GRP.DoesPassThroughFilter(env, "members >= 3"))
        assert.is_false(GRP.DoesPassThroughFilter(env, "members > 3"))
        assert.is_true(GRP.DoesPassThroughFilter(env, "tanks == 1 and heals == 1"))
    end)

    it("supports 'not' operator", function()
        local env = make_env({ heroic = false })
        assert.is_true(GRP.DoesPassThroughFilter(env, "not heroic"))
    end)

    it("supports 'or' operator", function()
        local env = make_env({ mythic = false, heroic = true })
        assert.is_true(GRP.DoesPassThroughFilter(env, "mythic or heroic"))
    end)

    it("supports parenthesized sub-expressions", function()
        local env = make_env({ mythic = true, tanks = 1, heals = 1 })
        assert.is_true(GRP.DoesPassThroughFilter(env, "(mythic) and (tanks >= 1 or heals >= 1)"))
    end)

    -- ======================================================================
    -- Syntax errors
    -- ======================================================================

    it("returns true (no filtering) on syntax error", function()
        local env = make_env()
        local result = GRP.DoesPassThroughFilter(env, "and and tanks==0")
        assert.is_true(result)
        assert.is_not_nil(last_popup)
    end)

    -- ======================================================================
    -- Semantic errors (undefined variable access)
    -- ======================================================================

    it("returns true (no filtering) on semantic error from undefined variable", function()
        local env = make_env()
        local result = GRP.DoesPassThroughFilter(env, "tansk < 0")
        assert.is_true(result)
    end)

    -- ======================================================================
    -- Non-boolean result
    -- ======================================================================

    it("returns true and warns when expression evaluates to a number", function()
        local env = make_env({ tanks = 2 })
        local result = GRP.DoesPassThroughFilter(env, "tanks")
        assert.is_true(result)
        assert.is_not_nil(last_popup)
    end)

    -- ======================================================================
    -- Edge cases
    -- ======================================================================

    it("handles expressions that evaluate to nil gracefully", function()
        local env = make_env()
        local result = GRP.DoesPassThroughFilter(env, "nil")
        assert.is_true(result)
    end)
end)
