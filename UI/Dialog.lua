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

-- Panel ID
-- cX  see C.CATEGORY_ID
-- f0  Default
-- f1  Recommended    -- raids
-- f2  NotRecommended -- raids
-- f4  PvE            -- custom
-- f8  PvP            -- custom

local PGFDialog = CreateFrame("Frame", "GroupinatorDialog", PVEFrame, "GroupinatorDialogTemplate")

function PGFDialog:OnLoad()
    GRP.Logger:Debug("PGFDialog:OnLoad")
    self.minimizedHeight = 220
    self.maximizedHeight = PVEFrame:GetHeight()
    self.panels = {}
    self.activeId = nil
    self.activeState = nil
    self.activePanel = nil

    self:SetScript("OnShow", self.OnShow)
    self:SetScript("OnHide", self.OnHide)
    self:SetScript("OnMouseDown", self.OnMouseDown)
    self:SetScript("OnMouseUp", self.OnMouseUp)

    self:SetTitle(L["addon.name.long"])
    if GRP.SupportsDragonflightUI() then
        self:SetBorder("ButtonFrameTemplateNoPortraitMinimizable")
        self:SetPortraitShown(false)
        self.MaximizeMinimizeFrame:SetOnMaximizedCallback(function () self:OnMaximize() end)
        self.MaximizeMinimizeFrame:SetOnMinimizedCallback(function () self:OnMinimize() end)
    end

    self.ResetButton:SetScript("OnClick", function () self:OnResetButtonClick() end)
    self.ResetButton:SetScript("OnEnter", function (self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["dialog.reset"], nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    self.ResetButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    self.SettingsButton:SetScript("OnClick", function () GRP.OpenSettings() end)
    self.SettingsButton:SetScript("OnEnter", function (self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["dialog.settings"], nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    self.SettingsButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    self.RefreshButton:SetText(L["dialog.refresh"])
    self.RefreshButton:SetScript("OnClick", function () self:OnRefreshButtonClick() end)
end

function PGFDialog:OnShow()
    GRP.Logger:Debug("PGFDialog:OnShow")
    if not GroupinatorSettings.dialogMovable then
        self:ResetPosition()
    end
    if self.activePanel and self.activePanel.OnShow then
        self.activePanel:OnShow()
    end
end

function PGFDialog:OnHide()
    GRP.Logger:Debug("PGFDialog:OnHide")
    if self.activePanel and self.activePanel.OnHide then
        self.activePanel:OnHide()
    end
end

function PGFDialog:OnMouseDown(button)
    if not GroupinatorSettings.dialogMovable then return end
    self:StartMoving()
end

function PGFDialog:OnMouseUp(button)
    if not GroupinatorSettings.dialogMovable then return end
    self:StopMovingOrSizing()
    if button == "RightButton" then
        self:ResetPosition()
    end
end

function PGFDialog:OnMaximize()
    GRP.Logger:Debug("PGFDialog:OnMaximize")
    self.activeState.minimized = false
    self:SetHeight(self.maximizedHeight)
    self:SwitchToPanel()
end

function PGFDialog:OnMinimize()
    GRP.Logger:Debug("PGFDialog:OnMinimize")
    self.activeState.minimized = true
    self:SetHeight(self.minimizedHeight)
    self:SwitchToPanel()
end

function PGFDialog:MaximizeMinimize()
    if self.activeState.minimized then
        self.MaximizeMinimizeFrame.isMinimized = true
        self.MaximizeMinimizeFrame:SetMaximizedLook() -- button should show maximize icon
        self:SetHeight(self.minimizedHeight)
    else
        self.MaximizeMinimizeFrame.isMinimized = false
        self.MaximizeMinimizeFrame:SetMinimizedLook() -- button should show minimize icon
        self:SetHeight(self.maximizedHeight)
    end
end

function PGFDialog:OnResetButtonClick()
    GRP.Logger:Debug("PGFDialog:OnResetButtonClick")
    GRP.StaticPopup_Show("GRP_CONFIRM_RESET")
end

function PGFDialog:OnRefreshButtonClick()
    GRP.Logger:Debug("PGFDialog:OnRefreshButtonClick")
    self:Refresh()
end

function PGFDialog:Refresh()
    LFGListSearchPanel_DoSearch(LFGListFrame.SearchPanel)
end

function PGFDialog:Reset()
    GRP.Logger:Debug("PGFDialog:Reset")
    self.activePanel:OnReset()
end

function PGFDialog:UpdateExpression(expression, sorting)
    GRP.Logger:Debug("PGFDialog:SetExpressionFromMacro")
    self.activePanel:OnUpdateExpression(expression, sorting)
end

function PGFDialog:Toggle()
    GRP.Logger:Debug("PGFDialog:Toggle")
    local isSearchPanelVisible = PVEFrame:IsVisible()
            and LFGListFrame.activePanel == LFGListFrame.SearchPanel
            and LFGListFrame.SearchPanel:IsVisible()
    if isSearchPanelVisible and self.activeState and self.activeState.enabled then
        self:Show()
    else
        self:Hide()
    end
end

function PGFDialog:UpdateCategory(categoryID, filters, baseFilters)
    GRP.Logger:Debug("PGFDialog:UpdateCategory(".. categoryID ..", "..filters..", "..baseFilters..")")
    local allFilters = bit.bor(baseFilters, filters);
    local id = "c"..categoryID.."f"..allFilters
    self.activeId = id
    self.activeState = self:GetState(id)
    if GRP.SupportsDragonflightUI() then
        self:MaximizeMinimize()
    end
    self:SwitchToPanel()
end

function PGFDialog:SwitchToPanel()
    local panel = self.activeState.minimized
            and self.panels.mini          -- if minimized, use mini panel
            or self.panels[self.activeId] -- if maximized, use panel for current category
            or self.panels.role           -- if no panel for current category, use role panel
    GRP.Logger:Debug("PGFDialog:SwitchToPanel("..panel.name..")")
    self.activeState[panel.name] = self.activeState[panel.name] or {} -- initialize panel state
    if self.activePanel then self.activePanel:Hide() end
    self.activePanel = panel
    self.activePanel:Init(self.activeState[panel.name])
    if self.activePanel.GetDesiredDialogWidth then
        local desiredWidth = self.activePanel:GetDesiredDialogWidth()
        self:SetWidth(desiredWidth)
    elseif GRP.SupportsDragonflightUI() then
        self:SetWidth(300)
    else
        self:SetWidth(310)
    end
    if not GRP.SupportsDragonflightUI() then
        self.activePanel:ClearAllPoints()
        self.activePanel:SetPoint("TOPLEFT", 5, -20)
        self.activePanel:SetPoint("BOTTOMRIGHT", 0, 35)
    end
    self.activePanel:Show()
end

function PGFDialog:GetState(id)
    if GroupinatorState[id] == nil then
        GroupinatorState[id] = {}
        if self.panels[id] then -- if there is a special panel registered for this id, enable it on first run
            GroupinatorState[id].enabled = true
        end
    end
    return GroupinatorState[id]
end

function PGFDialog:GetEnabled()
    return self.activeState and self.activeState.enabled or false
end

function PGFDialog:SetEnabled(enabled)
    self.activeState.enabled = enabled
    self:Toggle()
    self:OnFilterExpressionChanged(true)
end

function PGFDialog:OnFilterExpressionChanged(shouldRefresh)
    GRP.Logger:Debug("PGFDialog:OnFilterExpressionChanged")
    if shouldRefresh then
        self:Refresh()
    end
    GRP.FilterSearchResults()
end

function PGFDialog:GetFilterExpression()
    GRP.Logger:Debug("PGFDialog:GetFilterExpression")
    if not self.activePanel then return nil end
    return self.activePanel:GetFilterExpression()
end

function PGFDialog:GetSortingExpression()
    if not self.activePanel then return nil end
    return self.activePanel:GetSortingExpression()
end

function PGFDialog:ResetPosition()
    GRP.Logger:Debug("PGFDialog:ResetPosition")
    self:ClearAllPoints()
    if GRP.SupportsDragonflightUI() then
        self:SetPoint("TOPLEFT", PVEFrame, "TOPRIGHT")
    else
        self:SetPoint("TOPLEFT", PVEFrame, "TOPRIGHT", -5, 0)
    end
end

function PGFDialog:RegisterPanel(id, panel)
    GRP.Logger:Debug("PGFDialog:RegisterPanel("..id..")")
    self.panels[id] = panel
end

local pvpButtonsHooked = false
hooksecurefunc("LFGListSearchPanel_SetCategory", function(self, categoryID, filters, baseFilters)
    PGFDialog:UpdateCategory(categoryID, filters, baseFilters)
end)
hooksecurefunc("LFGListFrame_SetActivePanel", function () PGFDialog:Toggle() end)
hooksecurefunc("PVEFrame_ShowFrame", function (sidePanelName, selection)
    -- PVPUIFrame is loaded dynamically and not available on startup
    if sidePanelName == "PVPUIFrame" and PVPQueueFrame_ShowFrame and not pvpButtonsHooked then
        hooksecurefunc("PVPQueueFrame_ShowFrame", function () PGFDialog:Toggle() end)
        pvpButtonsHooked = true
    end
    PGFDialog:Toggle()
end)
hooksecurefunc("GroupFinderFrame_ShowGroupFrame", function () PGFDialog:Toggle() end)
PVEFrame:HookScript("OnShow", function () PGFDialog:Toggle() end)
PVEFrame:HookScript("OnHide", function () PGFDialog:Toggle() end)

PGFDialog:OnLoad()
GRP.Dialog = PGFDialog
