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

function GRP.GameTooltip_AddWhite(left)
    GameTooltip:AddLine(left, 255, 255, 255)
end

function GRP.GameTooltip_AddDoubleWhite(left, right)
    GameTooltip:AddDoubleLine(left, right, 255, 255, 255, 255, 255, 255)
end

function GRP.Dialog_InfoButton_OnEnter(self, motion)
    local AddDoubleWhiteUsingKey = function (key)
        GRP.GameTooltip_AddDoubleWhite(key, L["dialog.tooltip." .. key]) end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["dialog.tooltip.title"])
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(L["dialog.tooltip.variable"], L["dialog.tooltip.description"])
    AddDoubleWhiteUsingKey("ilvl")
    AddDoubleWhiteUsingKey("myilvl")
    if GRP.IsRetail() then
        AddDoubleWhiteUsingKey("hlvl")
        AddDoubleWhiteUsingKey("pvprating")
        AddDoubleWhiteUsingKey("mprating")
    end
    AddDoubleWhiteUsingKey("defeated")
    AddDoubleWhiteUsingKey("members")
    AddDoubleWhiteUsingKey("tanks")
    AddDoubleWhiteUsingKey("heals")
    AddDoubleWhiteUsingKey("dps")
    if GRP.IsRetail() then
        AddDoubleWhiteUsingKey("partyfit")
        AddDoubleWhiteUsingKey("warmode")
        GRP.GameTooltip_AddDoubleWhite("autoinv", LFG_LIST_TOOLTIP_AUTO_ACCEPT)
    end
    AddDoubleWhiteUsingKey("age")
    AddDoubleWhiteUsingKey("voice")
    AddDoubleWhiteUsingKey("myrealm")
    AddDoubleWhiteUsingKey("noid")
    AddDoubleWhiteUsingKey("matchingid")
    GRP.GameTooltip_AddWhite("boss/bossesmatching/... — " .. L["dialog.tooltip.seewebsite"])
    GRP.GameTooltip_AddDoubleWhite("priests/warriors/...", L["dialog.tooltip.classes"])
    if GRP.IsRetail() then
        GRP.GameTooltip_AddDoubleWhite("vs/moq/dr/np/lou/...", L["dialog.tooltip.raids"])
        GRP.GameTooltip_AddDoubleWhite("mai/npx/mt/ws", L["dialog.tooltip.dungeons"])
        GRP.GameTooltip_AddWhite("aa/seat/sr/pos")
        GRP.GameTooltip_AddDoubleWhite("hov/cos/dht/nl/eoa/brh", L["dialog.tooltip.timewalking"])
        GRP.GameTooltip_AddDoubleWhite("arena2v2/arena3v3", L["dialog.tooltip.arena"])
        GameTooltip:AddLine(" ")
        GRP.GameTooltip_AddDoubleWhite("learning/relaxed/competitive/carry", L["dialog.tooltip.playstyle"])
        GRP.GameTooltip_AddDoubleWhite("fresh", L["dialog.tooltip.fresh"])
        GRP.GameTooltip_AddDoubleWhite("recent", L["dialog.tooltip.recent"])
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(L["dialog.tooltip.op.logic"], L["dialog.tooltip.example"])
    GRP.GameTooltip_AddDoubleWhite("()", "(voice or not voice)")
    GRP.GameTooltip_AddDoubleWhite("not", "not myrealm")
    GRP.GameTooltip_AddDoubleWhite("and", "heroic and hfc")
    GRP.GameTooltip_AddDoubleWhite("or", "normal or heroic")
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(L["dialog.tooltip.op.number"], L["dialog.tooltip.example"])
    GRP.GameTooltip_AddDoubleWhite("==", "dps == 3")
    GRP.GameTooltip_AddDoubleWhite("~=", "members ~= 0")
    GRP.GameTooltip_AddDoubleWhite("<,>,<=,>=", "hlvl >= 5")
    GameTooltip:Show()
end

function GRP.Dialog_InfoButton_OnLeave(self, motion)
    GameTooltip:Hide()
end

function GRP.Dialog_InfoButton_OnClick(self, button, down)
    GRP.StaticPopup_Show("GRP_COPY_URL_KEYWORDS")
end
