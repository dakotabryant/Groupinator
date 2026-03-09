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

function GRP.GetActivityIDFromChallengeModeMapID(cmID)
    for activityID, activityInfo in pairs(C.ACTIVITY) do
        if activityInfo.cmID and activityInfo.cmID == cmID then
            return activityID
        end
    end
    return 0
end

function GRP.GetThisWeeksAffixNameLocalized()
    local affixIDs = C_MythicPlus.GetCurrentAffixes()
    if not affixIDs then return nil end -- result might not have been loaded yet
    local tyrannicalOrFortifiedAffix = affixIDs[1]
    if not tyrannicalOrFortifiedAffix or not tyrannicalOrFortifiedAffix.id then return nil end
    local name, description, filedataid = C_ChallengeMode.GetAffixInfo(tyrannicalOrFortifiedAffix.id)
    return name
end

function GRP.GetPlayerInfo()
    local avgItemLevel, avgItemLevelEquipped, avgItemLevelPvp = GetAverageItemLevel()

    local result = {}
    result.avgItemLevel = avgItemLevel
    result.avgItemLevelEquipped = avgItemLevelEquipped
    result.avgItemLevelPvp = avgItemLevelPvp
    result.mymprating = GRP.SupportsMythicPlus() and C_ChallengeMode.GetOverallDungeonScore() or 0
    result.affixRating = {}
    result.avgAffixRating = 0
    result.medianAffixRating = 0
    result.dungeonRating = {}
    result.avgDungeonRating = 0
    result.medianDungeonRating = 0

    if not GRP.SupportsMythicPlus() then return result end -- stop if Mythic Plus not supported

    local thisWeeksAffixNameLocalized = GRP.GetThisWeeksAffixNameLocalized()
    local cmIDs = C_ChallengeMode.GetMapTable()
    if not cmIDs then return result end -- result might not have been loaded yet

    for _, cmID in pairs(cmIDs) do
        local activityID = GRP.GetActivityIDFromChallengeModeMapID(cmID)
        if activityID > 0 then
            local affixScores, bestOverAllScore = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(cmID)
            result.dungeonRating[activityID] = bestOverAllScore or 0 -- can be nil

            local affixScore = 0
            if affixScores then -- can be nil
                for _, affixInfo in pairs(affixScores) do -- contains 1 or 2 entries
                    if affixInfo and affixInfo.name == thisWeeksAffixNameLocalized then
                        affixScore = affixInfo.score or 0
                    end
                end
            end
            result.affixRating[activityID] = affixScore
        end
    end

    result.avgAffixRating = GRP.Table_Mean(result.affixRating)
    result.medianAffixRating = GRP.Table_Median(result.affixRating)
    result.avgDungeonRating = GRP.Table_Mean(result.dungeonRating)
    result.medianDungeonRating = GRP.Table_Median(result.dungeonRating)
    return result
end
