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

function GRP.HasRemainingSlotsForLocalPlayerRole(memberCounts)
    local playerRole = GetSpecializationRole(GetSpecialization())
    if not playerRole then return false end
    return (memberCounts[C.ROLE_REMAINING_KEYS[playerRole]] or 0) > 0
end

function GRP.GetPartyRoles()
    local numGroupMembers = GetNumGroupMembers()
    local groupType = IsInRaid() and "raid" or "party"
    local partyRoles = { ["TANK"] = 0, ["HEALER"] = 0, ["DAMAGER"] = 0 }
    if numGroupMembers == 0 then
        local playerRole = GetSpecializationRole(GetSpecialization())
        partyRoles[playerRole] = 1
    else
        for i = 1, numGroupMembers do
            local unit = (i == 1) and "player" or (groupType .. (i - 1))

            local groupMemberRole = UnitGroupRolesAssigned(unit)
            if groupMemberRole == "NONE" then groupMemberRole = "DAMAGER" end

            partyRoles[groupMemberRole] = partyRoles[groupMemberRole] + 1
        end
    end
    return partyRoles
end

function GRP.HasRemainingSlotsForLocalPlayerPartyRoles(memberCounts)
    if not memberCounts then return false end

    if GetNumGroupMembers() == 0 then
        -- not in a group
        return GRP.HasRemainingSlotsForLocalPlayerRole(memberCounts)
    end

    local partyRoles = GRP.GetPartyRoles()
    for role, remainingKey in pairs(C.ROLE_REMAINING_KEYS) do
        if memberCounts[remainingKey] < partyRoles[role] then
            return false
        end
    end

    return true
end

function GRP.GetMemberCountsAfterJoin(memberCounts)
    local memberCountsAfterJoin = GRP.Table_Copy_Shallow(memberCounts)
    local groupType = IsInRaid() and "raid" or "party"
    local numGroupMembers = GetNumGroupMembers()
    -- not in group
    if numGroupMembers == 0 then
        local role = GetSpecializationRole(GetSpecialization())
        if not role then role = "DAMAGER" end
        local roleRemaining = C.ROLE_REMAINING_KEYS[role]
        memberCountsAfterJoin[role] = (memberCountsAfterJoin[role] or 0) + 1
        memberCountsAfterJoin[roleRemaining] = (memberCountsAfterJoin[roleRemaining] or 0) - 1
        return memberCountsAfterJoin
    end
    -- in group
    for i = 1, numGroupMembers do
        local unit = (i == 1) and "player" or (groupType .. (i - 1))
        local role = UnitGroupRolesAssigned(unit)
        if not role or role == "NONE" then role = "DAMAGER" end
        local roleRemaining = C.ROLE_REMAINING_KEYS[role]
        memberCountsAfterJoin[role] = (memberCountsAfterJoin[role] or 0) + 1
        memberCountsAfterJoin[roleRemaining] = (memberCountsAfterJoin[roleRemaining] or 0) - 1
    end
    return memberCountsAfterJoin
end

function GRP.HasRemainingSlotsForBloodlustAfterJoin(memberCounts)
    local memberCountsAfterJoin = GRP.GetMemberCountsAfterJoin(memberCounts)
    return memberCountsAfterJoin.HEALER_REMAINING > 0 or
            memberCountsAfterJoin.DAMAGER_REMAINING > 0
end

function GRP.HasRemainingSlotsForBattleRezzAfterJoin(memberCounts)
    local memberCountsAfterJoin = GRP.GetMemberCountsAfterJoin(memberCounts)
    return memberCountsAfterJoin.HEALER_REMAINING > 0 or
            memberCountsAfterJoin.DAMAGER_REMAINING > 0 or
            memberCountsAfterJoin.TANK_REMAINING > 0
end

function GRP.UnitHasProperty(unit, prop)
    local class = select(2, UnitClass(unit)) -- MAGE, WARRIOR, ...
    return class and C.DPS_CLASS_TYPE[class] and C.DPS_CLASS_TYPE[class][prop]
end

function GRP.PlayerOrGroupHasProperty(prop)
    local numGroupMembers = GetNumGroupMembers()
    if numGroupMembers == 0 then
        return GRP.UnitHasProperty("player", prop)
    end
    local groupType = IsInRaid() and "raid" or "party"
    for i = 1, numGroupMembers do
        local unit = (i == 1) and "player" or (groupType .. (i - 1))
        if GRP.UnitHasProperty(unit, prop) then
            return true
        end
    end
    return false
end

function GRP.PlayerOrGroupHasBloodlust()
    return GRP.PlayerOrGroupHasProperty("bl")
end

function GRP.PlayerOrGroupHasBattleRezz()
    return GRP.PlayerOrGroupHasProperty("br")
end
