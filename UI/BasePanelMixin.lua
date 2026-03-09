-------------------------------------------------------------------------------
-- Groupinator
-------------------------------------------------------------------------------
-- Copyright (C) 2026 dakotabryant
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

GRP.BasePanelMixin = {}

function GRP.BasePanelMixin:InitMinMaxFields(fieldDefs)
    for _, def in ipairs(fieldDefs) do
        self.state[def.key] = self.state[def.key] or {}
        local uiElement = self.Group[def.uiKey]
        if uiElement then
            uiElement.Act:SetChecked(self.state[def.key].act or false)
            uiElement.Min:SetText(self.state[def.key].min or "")
            uiElement.Max:SetText(self.state[def.key].max or "")
        end
    end
end

function GRP.BasePanelMixin:ResetMinMaxFields(fieldDefs)
    for _, def in ipairs(fieldDefs) do
        self.state[def.key].act = false
        self.state[def.key].min = ""
        self.state[def.key].max = ""
    end
end

function GRP.BasePanelMixin:BuildMinMaxExpression(expression, fieldDefs)
    for _, def in ipairs(fieldDefs) do
        if self.state[def.key].act then
            local envKey = def.envKey or def.key
            if GRP.NotEmpty(self.state[def.key].min) then
                expression = expression .. " and " .. envKey .. " >= " .. self.state[def.key].min
            end
            if GRP.NotEmpty(self.state[def.key].max) then
                expression = expression .. " and " .. envKey .. " <= " .. self.state[def.key].max
            end
        end
    end
    return expression
end

function GRP.BasePanelMixin:OnUpdateExpressionBase(expression)
    self.state.expression = expression
    self:Init(self.state)
end

function GRP.BasePanelMixin:TriggerFilterExpressionChangeBase()
    local expression = self:GetFilterExpression()
    local hint = expression == "true" and "" or expression
    self.Advanced.Expression.EditBox.Instructions:SetText(hint)
    GRP.Dialog:OnFilterExpressionChanged()
end

function GRP.BasePanelMixin:FinalizeExpression(expression)
    self.state.expression = self.state.expression or ""
    local userExp = GRP.UI_NormalizeExpression(self.state.expression)
    if userExp ~= "" then expression = expression .. " and ( " .. userExp .. " )" end
    expression = expression:gsub("^true and ", "")
    return expression
end
