-------------------------------------------------------------------------------
-- WoW API Mock for Busted tests
--
-- WoW addons receive (addonName, namespace) as varargs via select(1/2, ...).
-- This module recreates that namespace so addon files can be loaded outside
-- the game client using load_module().
-------------------------------------------------------------------------------

local M = {}

--- Build a fresh GRP namespace identical to what Init.lua creates.
function M.create_namespace()
    local GRP = {}
    GRP.L = {}
    GRP.C = {}

    local C = GRP.C

    C.NORMAL     = 1
    C.HEROIC     = 2
    C.MYTHIC     = 3
    C.MYTHICPLUS = 4
    C.ARENA2V2   = 5
    C.ARENA3V3   = 6
    C.ARENA5V5   = 7

    C.DIFFICULTY_MAP = {
        [  1] = C.NORMAL,     [  2] = C.HEROIC,     [  3] = C.NORMAL,
        [  4] = C.NORMAL,     [  5] = C.HEROIC,     [  6] = C.HEROIC,
        [  7] = 0,            [  8] = C.MYTHICPLUS,  [  9] = C.NORMAL,
        [ 14] = C.NORMAL,     [ 15] = C.HEROIC,     [ 16] = C.MYTHIC,
        [ 17] = 0,            [ 23] = C.MYTHIC,
    }
    setmetatable(C.DIFFICULTY_MAP, { __index = function() return 0 end })

    C.DIFFICULTY_KEYWORD = {
        [C.NORMAL]     = "normal",
        [C.HEROIC]     = "heroic",
        [C.MYTHIC]     = "mythic",
        [C.MYTHICPLUS] = "mythicplus",
        [C.ARENA2V2]   = "arena2v2",
        [C.ARENA3V3]   = "arena3v3",
        [C.ARENA5V5]   = "arena5v5",
    }

    C.PLAYSTYLE_KEYWORD = { [1] = "learning", [2] = "relaxed", [3] = "competitive", [4] = "carry" }

    C.ROLE_PREFIX = { ["DAMAGER"] = "dps", ["HEALER"] = "heal", ["TANK"] = "tank" }
    C.ROLE_SUFFIX = { ["DAMAGER"] = "dps", ["HEALER"] = "heals", ["TANK"] = "tanks" }

    return GRP
end

--- Load an addon Lua file, injecting the GRP namespace as the varargs.
-- This replicates how WoW passes (addonName, namespace) to each file.
function M.load_module(filepath, grp)
    local fn, err = loadfile(filepath)
    if not fn then error("Failed to load " .. filepath .. ": " .. tostring(err)) end
    setfenv(fn, setmetatable({}, {
        __index = function(_, k)
            return rawget(grp, k) or _G[k]
        end,
        __newindex = _G,
    }))
    fn("Groupinator", grp)
end

--- Stub commonly referenced WoW globals so files don't error on load.
function M.stub_wow_globals()
    _G.GAMEMENU_OPTIONS = "Options"
    _G.GroupinatorSettings = {}
    _G.GroupinatorState = nil
    _G.CreateFrame = function() return { RegisterEvent = function() end, SetScript = function() end } end
    _G.RequestRaidInfo = function() end
    _G.C_MythicPlus = { RequestCurrentAffixes = function() end, RequestMapInfo = function() end }
    _G.C_AddOns = { GetAddOnMetadata = function() return "" end }
    _G.GetAddOnMetadata = function() return "" end
end

return M
