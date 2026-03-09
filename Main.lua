-------------------------------------------------------------------------------
-- Groupinator
-------------------------------------------------------------------------------
-- Copyright (C) 2026 Bernhard Saumweber
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License along
-- with this program; if not, write to the Free Software Foundation, Inc.,
-- 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
-------------------------------------------------------------------------------

local GRP = select(2, ...)
local L = GRP.L
local C = GRP.C

GRP.currentSearchResults = {}
GRP.lastSearchEntryReset = time()
GRP.previousSearchExpression = ""
GRP.currentSearchExpression = ""
GRP.previousSearchGroupKeys = {}
GRP.currentSearchGroupKeys = {}
GRP.searchResultIDInfo = {}
GRP.numResultsBeforeFilter = 0
GRP.numResultsAfterFilter = 0

function GRP.ResetSearchEntries()
    -- make sure to wait at least some time between two resets
    if time() - GRP.lastSearchEntryReset > C.SEARCH_ENTRY_RESET_WAIT then
        GRP.previousSearchGroupKeys = GRP.Table_Copy_Shallow(GRP.currentSearchGroupKeys)
        GRP.currentSearchGroupKeys = {}
        GRP.previousSearchExpression = GRP.currentSearchExpression
        GRP.lastSearchEntryReset = time()
        GRP.searchResultIDInfo = {}
        GRP.numResultsBeforeFilter = 0
        GRP.numResultsAfterFilter = 0
    end
end

function GRP.GetUserSortingTable()
    local sorting = GRP.Dialog:GetSortingExpression()
    if GRP.Empty(sorting) then return {} end
    -- example string:  "friends asc, age desc , bar   desc , x"
    -- resulting sortTable = {
    --     [1] = { key = "friends", order = "asc" },
    --     [2] = { key = "age",     order = "desc" },
    --     [3] = { key = "bar",     order = "desc" },
    -- }
    local t = {}
    for k, v in string.gmatch(sorting, "(%w+)%s+(%w+),?") do
        table.insert(t, { key = k, order = v })
    end
    return t
end

function GRP.SortSearchResults(results)
    local sortTable = GRP.GetUserSortingTable()
    if sortTable and #sortTable > 0 then -- use custom sorting if defined
        table.sort(results, GRP.SortByExpression)
    elseif GRP.IsRetail() then -- use our extended useful sorting
        table.sort(results, GRP.SortByUsefulOrder)
    end
    -- else keep the existing sorting as classic clients have a pretty big
    -- intelligent sorting algorithm in LFGBrowseUtil_SortSearchResults
end

function GRP.SortByExpression(searchResultID1, searchResultID2)
    if not searchResultID1 or not searchResultID2 then return false end -- race condition

    -- look-up via table should be faster
    local info1 = GRP.searchResultIDInfo[searchResultID1]
    local info2 = GRP.searchResultIDInfo[searchResultID2]
    if not info1 or not info2 then return false end -- race condition

    local sortTable = GRP.GetUserSortingTable()
    for _, sort in ipairs(sortTable) do
        if info1.env[sort.key] ~= info2.env[sort.key] then -- works with unknown keys as 'nil ~= nil' is false (or 'nil == nil' is true)
            if sort.order == "desc" then
                if type(info1.env[sort.key]) == "boolean" then return info1.env[sort.key] end -- true before false
                return info1.env[sort.key] > info2.env[sort.key]
            else -- works with unknown 'v', in this case sort ascending by default
                if type(info1.env[sort.key]) == "boolean" then return info2.env[sort.key] end -- false before true
                return info1.env[sort.key] < info2.env[sort.key]
            end
        end
    end
    -- no sorting defined or all properties are the same, fall back to default sorting
    return GRP.SortByUsefulOrder(searchResultID1, searchResultID2)
end

function GRP.SortByUsefulOrder(searchResultID1, searchResultID2)
    if not searchResultID1 or not searchResultID2 then return false end -- race condition

    -- look-up via table should be faster
    local info1 = GRP.searchResultIDInfo[searchResultID1]
    local info2 = GRP.searchResultIDInfo[searchResultID2]
    if not info1 or not info2 then return false end -- race condition

    -- sort applications to the top
    if info1.env.apporder ~= info2.env.apporder then
        return info1.env.apporder > info2.env.apporder
    end

    local searchResultInfo1 = info1.searchResultInfo
    local searchResultInfo2 = info2.searchResultInfo

    if GRP.SupportsSpecializations() then
        -- sort by partyfit
        local hasRemainingRole1 = GRP.HasRemainingSlotsForLocalPlayerRole(info1.memberCounts)
        local hasRemainingRole2 = GRP.HasRemainingSlotsForLocalPlayerRole(info2.memberCounts)
        if hasRemainingRole1 ~= hasRemainingRole2 then return hasRemainingRole1 end
    end

    -- sort by friends desc
    if searchResultInfo1.numBNetFriends ~= searchResultInfo2.numBNetFriends then
        return searchResultInfo1.numBNetFriends > searchResultInfo2.numBNetFriends
    end
    if searchResultInfo1.numCharFriends ~= searchResultInfo2.numCharFriends then
        return searchResultInfo1.numCharFriends > searchResultInfo2.numCharFriends
    end
    if searchResultInfo1.numGuildMates ~= searchResultInfo2.numGuildMates then
        return searchResultInfo1.numGuildMates > searchResultInfo2.numGuildMates
    end

    -- if dungeon, sort by mprating desc
    if info1.activityInfo.categoryID == C.CATEGORY_ID.DUNGEON or
       info2.activityInfo.categoryID == C.CATEGORY_ID.DUNGEON then
        if info1.env.mprating ~= info2.env.mprating then
            return info1.env.mprating > info2.env.mprating
        end
    end
    -- if arena or RBG, sort by pvprating desc
    if info1.activityInfo.categoryID == C.CATEGORY_ID.ARENA or
       info2.activityInfo.categoryID == C.CATEGORY_ID.ARENA or
       info1.activityInfo.categoryID == C.CATEGORY_ID.RATED_BATTLEGROUND or
       info2.activityInfo.categoryID == C.CATEGORY_ID.RATED_BATTLEGROUND then
        if info1.env.pvprating ~= info2.env.pvprating then
            return info1.env.pvprating > info2.env.pvprating
        end
    end

    if searchResultInfo1.isWarMode ~= searchResultInfo2.isWarMode then
        return searchResultInfo1.isWarMode == C_PvP.IsWarModeDesired()
    end

    return searchResultInfo1.age < searchResultInfo2.age
end

--- Puts a table that maps localized boss names to a boolean that indicates if the boss was defeated
--- @generic V
--- @param resultID number search result identifier
--- @param env table<string, V> environment to be prepared
function GRP.PutEncounterNames(resultID, env)
    local encounterToBool = {}
    -- return false for all values not explicitly set to true
    local encounterToBoolMeta = {}
    encounterToBoolMeta.__index = function (table, key) return false end
    setmetatable(encounterToBool, encounterToBoolMeta)

    local encounterInfo = C_LFGList.GetSearchResultEncounterInfo(resultID); -- list of localized boss names
    if encounterInfo then
        for _, val in pairs(encounterInfo) do
            encounterToBool[val] = true
            encounterToBool[val:lower()] = true
        end
    end

    env.boss = encounterToBool
end

function GRP.DoFilterSearchResults(results)
    --print(debugstack())
    --print("filtering, size is "..#results)

    if not GRP.Dialog:GetEnabled() then return results end
    if not results or #results == 0 then return results end

    local exp = GRP.Dialog:GetFilterExpression()
    GRP.Logger:Debug("Main: exp = "..exp)
    GRP.currentSearchExpression = exp

    local playerInfo = GRP.GetPlayerInfo()

    GRP.numResultsBeforeFilter = #results
    -- loop backwards through the results list so we can remove elements from the table
    for idx = #results, 1, -1 do
        local resultID = results[idx]
        local searchResultInfo = GRP.GetSearchResultInfo(resultID)
        if searchResultInfo then
            -- /dump GRP.GetSearchResultInfo(select(2, C_LFGList.GetSearchResults())[1])
            -- name and comment are now protected strings like "|Ks1969|k0000000000000000|k" which can only be printed
            local _, appStatus, pendingStatus, appDuration = C_LFGList.GetApplicationInfo(resultID)
            -- /dump C_LFGList.GetApplicationInfo(select(2, C_LFGList.GetSearchResults())[1])
            -- appStatus flow:
            --   none ─┬─▶ applied ─┬─▶ invited ───┬─▶ inviteaccepted
            --         └─▶ failed   ├─▶ cancelled  └─▶ invitedeclined
            --                      ├─▶ declined
            --                      ├─▶ declined_delisted
            --                      ├─▶ declined_full
            --                      └─▶ timedout
            -- pendingStatus flow (used for role check if in a group before transition of appStatus to applied):
            --   <nil> ◀──▶ applied ──▶ cancelled
            local memberCounts = C_LFGList.GetSearchResultMemberCounts(resultID)
            local numGroupDefeated, numPlayerDefeated, maxBosses,
            matching, groupAhead, groupBehind = GRP.GetLockoutInfo(searchResultInfo.activityID, resultID)
            local activityInfo = C_LFGList.GetActivityInfoTable(searchResultInfo.activityID)

            local difficulty = C.ACTIVITY[searchResultInfo.activityID].difficulty

            -- Delves do not have a fixed number of roles, but usually a dungeon composition is preferred
            if activityInfo.categoryID == C.CATEGORY_ID.DELVES then
                memberCounts["TANK_REMAINING"] = 1 - memberCounts["TANK"]
                memberCounts["HEALER_REMAINING"] = 1 - memberCounts["HEALER"]
                memberCounts["DAMAGER_REMAINING"] = 3 - memberCounts["DAMAGER"]
            end

            local env = {}
            env.activity = searchResultInfo.activityID
            env.activityname = activityInfo.fullName:lower()
            env.leader = searchResultInfo.leaderName and searchResultInfo.leaderName:lower() or ""
            env.age = math.floor(searchResultInfo.age / 60) -- age in minutes
            env.agesecs = searchResultInfo.age -- age in seconds
            env.voice = searchResultInfo.voiceChat and searchResultInfo.voiceChat ~= ""
            env.voicechat = searchResultInfo.voiceChat
            env.ilvl = searchResultInfo.requiredItemLevel or 0
            env.hlvl = searchResultInfo.requiredHonorLevel or 0
            env.friends = searchResultInfo.numBNetFriends + searchResultInfo.numCharFriends + searchResultInfo.numGuildMates
            env.members = searchResultInfo.numMembers
            env.tanks = memberCounts.TANK
            env.heals = memberCounts.HEALER
            env.healers = memberCounts.HEALER
            env.dps = memberCounts.DAMAGER + memberCounts.NOROLE
            env.defeated = numGroupDefeated
            env.normal     = difficulty == C.NORMAL
            env.heroic     = difficulty == C.HEROIC
            env.mythic     = difficulty == C.MYTHIC
            env.mythicplus = difficulty == C.MYTHICPLUS
            env.myrealm = searchResultInfo.leaderName and searchResultInfo.leaderName ~= "" and searchResultInfo.leaderName:find('-') == nil or false
            env.partialid = numPlayerDefeated > 0
            env.fullid = numPlayerDefeated > 0 and numPlayerDefeated == maxBosses
            env.noid = not env.partialid and not env.fullid
            env.matchingid = groupAhead == 0 and groupBehind == 0
            env.bossesmatching = matching
            env.bossesahead = groupAhead
            env.bossesbehind = groupBehind
            env.maxplayers = activityInfo.maxNumPlayers
            env.suggestedilvl = activityInfo.ilvlSuggestion
            env.minlvl = activityInfo.minLevel
            env.categoryid = activityInfo.categoryID
            env.groupid = activityInfo.groupFinderActivityGroupID
            env.autoinv = searchResultInfo.autoAccept
            env.questid = searchResultInfo.questID
            env.harddeclined = GRP.IsHardDeclinedGroup(searchResultInfo)
            env.softdeclined = GRP.IsSoftDeclinedGroup(searchResultInfo)
            env.declined = env.harddeclined or env.softdeclined
            env.canceled = GRP.IsCanceledGroup(searchResultInfo)
            env.warmode = searchResultInfo.isWarMode or false
            local playstyleEnum = Enum.LFGEntryPlaystyle or Enum.LFGEntryGeneralPlaystyle or {}
            local playstyleValue = searchResultInfo.playstyle or searchResultInfo.generalPlaystyle or 0
            env.playstyle   = playstyleValue
            env.learning    = playstyleValue == (playstyleEnum.Learning or playstyleEnum.Standard or 1)
            env.relaxed     = playstyleValue == (playstyleEnum.FunRelaxed or playstyleEnum.Casual or 2)
            env.competitive = playstyleValue == (playstyleEnum.FunSerious or playstyleEnum.Hardcore or 3)
            env.carry       = playstyleValue == (playstyleEnum.CarryOffered or 4)
            -- backward compatibility aliases
            env.standard    = env.learning
            env.casual      = env.relaxed
            env.hardcore    = env.competitive
            env.mprating = searchResultInfo.leaderOverallDungeonScore or 0
            env.mpmaprating = 0
            env.mpmapname   = ""
            env.mpmapmaxkey = 0
            env.mpmapintime = false
            if searchResultInfo.leaderDungeonScoreInfo then
                env.mpmaprating = searchResultInfo.leaderDungeonScoreInfo.mapScore
                env.mpmapname   = searchResultInfo.leaderDungeonScoreInfo.mapName
                env.mpmapmaxkey = searchResultInfo.leaderDungeonScoreInfo.bestRunLevel
                env.mpmapintime = searchResultInfo.leaderDungeonScoreInfo.finishedSuccess
            end
            env.pvpactivityname = ""
            env.pvprating = 0
            env.pvptierx = 0
            env.pvptier = 0
            env.pvptiername = ""
            if searchResultInfo.leaderPvpRatingInfo then
                env.pvpactivityname = searchResultInfo.leaderPvpRatingInfo.activityName
                env.pvprating       = searchResultInfo.leaderPvpRatingInfo.rating
                env.pvptierx        = searchResultInfo.leaderPvpRatingInfo.tier
                env.pvptier         = C.PVP_TIER_MAP[searchResultInfo.leaderPvpRatingInfo.tier].tier
                env.pvptiername     = PVPUtil.GetTierName(searchResultInfo.leaderPvpRatingInfo.tier)
            end
            env.horde = searchResultInfo.leaderFactionGroup == 0
            env.alliance = searchResultInfo.leaderFactionGroup == 1
            env.crossfaction = searchResultInfo.crossFactionListing or false
            env.appstatus = appStatus
            env.pendingstatus = pendingStatus
            env.appduration = appDuration
            env.isapp = appStatus ~= "none" or pendingStatus or false
            env.apporder = env.isapp and resultID or 0 -- allows sorting applications to the top via `apporder desc`

            GRP.PutSearchResultMemberInfos(resultID, searchResultInfo, env)
            GRP.PutEncounterNames(resultID, env)

            env.hasbr = env.druids > 0 or env.paladins > 0 or env.warlocks > 0 or env.deathknights > 0
            env.hasbl = env.shamans > 0 or env.evokers > 0 or env.hunters > 0 or env.mages > 0
            env.hashero = env.hasbl
            env.haslust = env.hasbl
            env.dispells = env.shamans + env.evokers + env.priests + env.mages + env.paladins + env.monks + env.druids

            for _, tier in pairs(C.ARMOR_TO_TIER) do env[tier] = 0 end
            for class, info in pairs(C.DPS_CLASS_TYPE) do
                local tier = C.ARMOR_TO_TIER[info.armor]
                if tier then
                    env[tier] = env[tier] + (env[class:lower() .. "s"] or 0)
                end
            end

            env.brfit = env.hasbr or GRP.PlayerOrGroupHasBattleRezz() or GRP.HasRemainingSlotsForBattleRezzAfterJoin(memberCounts)
            env.blfit = env.hasbl or GRP.PlayerOrGroupHasBloodlust() or GRP.HasRemainingSlotsForBloodlustAfterJoin(memberCounts)
            env.partyfit = GRP.HasRemainingSlotsForLocalPlayerPartyRoles(memberCounts)

            env.fresh = env.age < C.FRESHNESS_THRESHOLD_FRESH
            env.recent = env.age < C.FRESHNESS_THRESHOLD_RECENT

            env.myilvl = playerInfo.avgItemLevelEquipped
            env.myilvlpvp = playerInfo.avgItemLevelPvp
            env.mymprating = playerInfo.mymprating
            env.myaffixrating = playerInfo.affixRating[searchResultInfo.activityID] or 0
            env.mydungeonrating = playerInfo.dungeonRating[searchResultInfo.activityID] or 0
            env.myavgaffixrating = playerInfo.avgAffixRating
            env.mymedianaffixrating = playerInfo.medianAffixRating
            env.myavgdungeonrating = playerInfo.avgDungeonRating
            env.mymediandungeonrating = playerInfo.medianDungeonRating

            local numbers = GRP.String_ExtractNumbers(env.activityname)
            env.findnumber = function (min, max)
                for _, v in ipairs(numbers) do
                    if (not min or v >= min) and (not max or v <= max) then
                        return true
                    end
                end
                return false
            end

            GRP.PutActivityKeywords(env, searchResultInfo.activityID)

            if GRP.PutRaiderIOMetrics then
                GRP.PutRaiderIOMetrics(env, searchResultInfo.leaderName, searchResultInfo.activityID)
            end
            if GRP.PutPremadeRegionInfo then
                GRP.PutPremadeRegionInfo(env, searchResultInfo.leaderName)
            end

            GRP.searchResultIDInfo[resultID] = {
                env = env,
                searchResultInfo = searchResultInfo,
                memberCounts = memberCounts,
                activityInfo = activityInfo,
            }
            if GRP.DoesPassThroughFilter(env, exp) then
                local groupKey = GRP.GetGroupKey(searchResultInfo)
                -- group key can be nil if falling back to leaderName, which is nil at this point if the group is new
                if groupKey then GRP.currentSearchGroupKeys[groupKey] = true end
            else
                table.remove(results, idx)
            end
        end
    end
    GRP.numResultsAfterFilter = #results

    GRP.SortSearchResults(results)
    return results
end

function GRP.ColorGroupTexts(self, searchResultInfo)
    if not GroupinatorSettings.coloredGroupTexts then return end
    local groupKey = GRP.GetGroupKey(searchResultInfo)
    -- try once again to update the group key if we had to fall back to the leaderName
    if groupKey then GRP.currentSearchGroupKeys[groupKey] = true end
    if not searchResultInfo.isDelisted then
        -- color name if new
        if GRP.currentSearchExpression ~= "true"                          -- not trivial search
        and GRP.currentSearchExpression == GRP.previousSearchExpression   -- and the same search
        and (groupKey and not GRP.previousSearchGroupKeys[groupKey]) then -- and group is new
            local color = C.COLOR_ENTRY_NEW
            self.Name:SetTextColor(color.R, color.G, color.B)
        end
        -- color name if declined
        if GRP.IsSoftDeclinedGroup(searchResultInfo) then
            local color = C.COLOR_ENTRY_DECLINED_SOFT
            self.Name:SetTextColor(color.R, color.G, color.B)
            if not GroupinatorSettings.signUpDeclined then
                self.PendingLabel:SetTextColor(color.R, color.G, color.B)
            end
        end
        if GRP.IsHardDeclinedGroup(searchResultInfo) then
            local color = C.COLOR_ENTRY_DECLINED_HARD
            self.Name:SetTextColor(color.R, color.G, color.B)
            if not GroupinatorSettings.signUpDeclined then
                self.PendingLabel:SetTextColor(color.R, color.G, color.B)
            end
        end
        if GRP.IsCanceledGroup(searchResultInfo) then
            local color = C.COLOR_ENTRY_CANCELED
            self.Name:SetTextColor(color.R, color.G, color.B)
        end
        -- color activity if lockout
        local numGroupDefeated, numPlayerDefeated, maxBosses,
              matching, groupAhead, groupBehind = GRP.GetLockoutInfo(searchResultInfo.activityID, self.resultID)
        local color
        if numPlayerDefeated > 0 and numPlayerDefeated == maxBosses then
            color = C.COLOR_LOCKOUT_FULL
        elseif numPlayerDefeated > 0 and groupAhead == 0 and groupBehind == 0 then
            color = C.COLOR_LOCKOUT_MATCH
        end
        if color then
            self.ActivityName:SetTextColor(color.R, color.G, color.B)
        end
    end
end

function GRP.ColorFreshness(self, searchResultInfo)
    if searchResultInfo.isDelisted then return end
    local info = GRP.searchResultIDInfo[self.resultID]
    if not info then return end
    local ageMinutes = info.env.age
    if ageMinutes < C.FRESHNESS_THRESHOLD_FRESH then
        local color = C.COLOR_FRESH
        self.ActivityName:SetTextColor(color.R, color.G, color.B)
    elseif ageMinutes < C.FRESHNESS_THRESHOLD_RECENT then
        local color = C.COLOR_RECENT
        self.ActivityName:SetTextColor(color.R, color.G, color.B)
    end
end

function GRP.OnLFGListSearchEntryUpdate(self)
    local searchResultInfo = GRP.GetSearchResultInfo(self.resultID)
    if not searchResultInfo then return end
    GRP.ColorGroupTexts(self, searchResultInfo)
    GRP.ColorFreshness(self, searchResultInfo)
    GRP.AddRoleIndicators(self, searchResultInfo)
    GRP.AddRatingInfo(self, searchResultInfo)
end

function GRP.OnLFGListSearchPanelUpdateResultList(self)
    GRP.Logger:Debug("GRP.OnLFGListSearchPanelUpdateResultList")
    GRP.currentSearchResults = self.results
    GRP.ResetSearchEntries()
    GRP.FilterSearchResults()
end

function GRP.FilterSearchResults()
    GRP.Logger:Debug("GRP.FilterSearchResults")
    local copy = GRP.Table_Copy_Shallow(GRP.currentSearchResults)
    local results = GRP.DoFilterSearchResults(copy)
    -- publish
    LFGListFrame.SearchPanel.results = results
    LFGListFrame.SearchPanel.totalResults = #results
    LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel)
end

hooksecurefunc("LFGListSearchEntry_Update", GRP.OnLFGListSearchEntryUpdate)
hooksecurefunc("LFGListSearchPanel_UpdateResultList", GRP.OnLFGListSearchPanelUpdateResultList)

-- Allow other addons to overwrite the sorting function
local originalSortSearchResults = GRP.SortSearchResults
Groupinator.OverwriteSortSearchResults = function(addonName, func)
    GRP.SortSearchResults = func
    print(string.format(L["message.sortingoverwritten"], (addonName or "<?>")))
end
Groupinator.RestoreSortSearchResults = function(addonName)
    GRP.SortSearchResults = originalSortSearchResults
    print(string.format(L["message.sortingrestored"], (addonName or "<?>")))
end
