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

local MiniPanel = CreateFrame("Frame", "GroupinatorMiniPanel", GRP.Dialog, "GroupinatorMiniPanelTemplate")

function MiniPanel:OnLoad()
    GRP.Logger:Debug("MiniPanel:OnLoad")
    self.name = "mini"

    GRP.UI_SetupAdvancedExpression(self)
    local fontFile, _, fontFlags = self.Advanced.Title:GetFont()
    self.Sorting.Title:SetText(L["dialog.sorting"])
    self.Sorting.Expression:SetFont(fontFile, C.FONTSIZE_TEXTBOX, fontFlags)
    self.Sorting.Expression:SetScript("OnTextChanged", InputBoxInstructions_OnTextChanged)
    self.Sorting.Expression:SetScript("OnEditFocusLost", function ()
        self.state.sorting = self.Sorting.Expression:GetText()
        self:TriggerFilterExpressionChange()
    end)
    self.Sorting.Expression.Instructions:SetFont(fontFile, C.FONTSIZE_TEXTBOX, fontFlags)
    self.Sorting.Expression.Instructions:SetText("friends desc, age asc")
end

function MiniPanel:Init(state)
    GRP.Logger:Debug("MiniPanel:Init")
    self.state = state
    self.state.expression = self.state.expression or ""
    self.state.sorting = self.state.sorting or ""
    self.Advanced.Expression.EditBox:SetText(self.state.expression)
    self.Sorting.Expression:SetText(self.state.sorting)
end

function MiniPanel:OnShow()
    GRP.Logger:Debug("MiniPanel:OnShow")
end

function MiniPanel:OnHide()
    GRP.Logger:Debug("MiniPanel:OnHide")
end

function MiniPanel:OnReset()
    GRP.Logger:Debug("MiniPanel:OnReset")
    self.state.expression = ""
    self.state.sorting = ""
    self:TriggerFilterExpressionChange()
    self:Init(self.state)
end

function MiniPanel:OnUpdateExpression(expression, sorting)
    GRP.Logger:Debug("MiniPanel:OnUpdateExpression")
    self.state.expression = expression
    self.state.sorting = sorting
    self:Init(self.state)
end

function MiniPanel:GetFilterExpression()
    GRP.Logger:Debug("MiniPanel:GetFilterExpression")
    local userExp = GRP.UI_NormalizeExpression(self.state.expression)
    if userExp == "" then
        return "true"
    else
        return userExp
    end
end

function MiniPanel:GetSortingExpression()
    return self.state.sorting
end

function MiniPanel:TriggerFilterExpressionChange()
    GRP.Logger:Debug("MiniPanel:TriggerFilterExpressionChange")
    GRP.Dialog:OnFilterExpressionChanged()
end

MiniPanel:OnLoad()
GRP.Dialog:RegisterPanel("mini", MiniPanel)
