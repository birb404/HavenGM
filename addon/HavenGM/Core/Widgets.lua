local _, HG = ...

local function backdrop(frame, color)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(unpack(color or HG.colors.inset))
    frame:SetBackdropBorderColor(0.72, 0.43, 0.08, 1)
end

function HG:Section(parent, title, x, y, width, height)
    local section = CreateFrame("Frame", nil, parent)
    section:SetPoint("TOPLEFT", x, y)
    section:SetSize(width, height)
    backdrop(section, self.colors.inset)
    local label = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("TOPLEFT", 14, -12)
    label:SetText(title)
    return section
end

function HG:Label(parent, text, x, y, width)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", x, y)
    if width then label:SetWidth(width); label:SetJustifyH("LEFT") end
    label:SetText(text)
    return label
end

function HG:Button(parent, text, x, y, width, callback, tooltip)
    local button = CreateFrame("Button", nil, parent)
    button:SetPoint("TOPLEFT", x, y)
    button:SetSize(width, 26)
    backdrop(button, self.colors.gold)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.label:SetPoint("CENTER")
    button.label:SetText(text)
    button.restingColor = self.colors.gold
    function button:SetRestingColor(color)
        self.restingColor = color or HG.colors.gold
        self:SetBackdropColor(unpack(self.restingColor))
    end
    function button:RestoreColor()
        self:SetBackdropColor(unpack(self.restingColor or HG.colors.gold))
    end
    button:SetScript("OnClick", callback)
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(HG.colors.goldHover))
        if tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.label:GetText())
            GameTooltip:AddLine(tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function(self)
        self:RestoreColor()
        GameTooltip_Hide()
    end)
    return button
end

function HG:ClearButton(parent, field, x, y, cleared)
    local button = self:Button(parent, "X", x, y, 28, function()
        field:SetText("")
        field:ClearFocus()
        if cleared then cleared() end
    end, "Clear this field.")
    button:SetRestingColor(self.colors.off)
    return button
end

function HG:ReadOnly(parent, x, y, width, initial)
    local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    edit:SetPoint("TOPLEFT", x, y)
    edit:SetSize(width or 110, 24)
    edit:SetAutoFocus(false)
    edit:SetText(tostring(initial or ""))
    edit:SetJustifyH("CENTER")
    edit:EnableMouse(false)
    edit:SetTextColor(0.78, 0.82, 0.90)
    return edit
end

function HG:Edit(parent, key, x, y, width, numeric, initial)
    local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    edit:SetPoint("TOPLEFT", x, y)
    edit:SetSize(width or 110, 24)
    edit:SetAutoFocus(false)
    edit:SetNumeric(numeric == true)
    edit:SetMaxLetters(80)
    local value = self.db.inputs[key]
    edit:SetText(value ~= nil and tostring(value) or tostring(initial or ""))
    edit:SetJustifyH(numeric and "CENTER" or "LEFT")
    edit:SetScript("OnEscapePressed", edit.ClearFocus)
    edit:SetScript("OnEnterPressed", edit.ClearFocus)
    edit:SetScript("OnTextChanged", function(self)
        if HG.db then HG.db.inputs[key] = self:GetText() end
    end)
    self.fields[key] = edit
    return edit
end

function HG:Step(parent, edit, text, x, y, delta, minimum, maximum, changed)
    return self:Button(parent, text, x, y, 28, function()
        local value = tonumber(edit:GetText()) or minimum
        value = math.max(minimum, math.min(maximum, math.floor(value + delta)))
        edit:SetText(value)
        if changed then changed(value) end
    end)
end

function HG:RuntimeToggle(parent, key, text, x, y, width, commandKey)
    local button
    button = self:Button(parent, text, x, y, width, function()
        local enabled = HG.db.toggles[key] ~= true
        HG.db.toggles[key] = enabled
        if key == "god" or key == "cast" or key == "cooldown" or key == "power" then
            HG.db.cheatsEnabled =
                HG.db.toggles.god == true and
                HG.db.toggles.cast == true and
                HG.db.toggles.cooldown == true and
                HG.db.toggles.power == true
        end
        HG:Execute(commandKey, enabled and "on" or "off")
        HG:RefreshRuntimeButtons()
    end, "Green/red is the last state requested by HavenGM, not queried server state.")
    function button:Refresh()
        local enabled = HG.db.toggles[key] == true
        self.label:SetText(text .. (enabled and " ON" or " OFF"))
        self:SetRestingColor(enabled and HG.colors.on or HG.colors.off)
    end
    button:SetScript("OnLeave", function(self) self:Refresh(); GameTooltip_Hide() end)
    self.runtimeButtons[key] = button
    button:Refresh()
    return button
end

function HG:PairToggle(parent, key, text, x, y, width, enableCommand, disableCommand, tooltip)
    self.db.creatorToggles = self.db.creatorToggles or {}
    local button
    button = self:Button(parent, text, x, y, width, function()
        local enabled = HG.db.creatorToggles[key] ~= true
        local commandKey = enabled and enableCommand or disableCommand
        if HG:Execute(commandKey) then
            HG.db.creatorToggles[key] = enabled
            button:Refresh()
            if key == "possess" then HG:RefreshFactionButton() end
        end
    end, tooltip or "Green/red is the last state requested by HavenGM, not queried server state.")
    function button:Refresh()
        local enabled = HG.db.creatorToggles[key] == true
        self.label:SetText(text .. (enabled and " ON" or " OFF"))
        self:SetRestingColor(enabled and HG.colors.on or HG.colors.off)
    end
    button:SetScript("OnLeave", function(self) self:Refresh(); GameTooltip_Hide() end)
    self.pairButtons[key] = button
    button:Refresh()
    return button
end

function HG:RefreshRuntimeButtons()
    for _, button in pairs(self.runtimeButtons) do button:Refresh() end
    for _, button in pairs(self.pairButtons) do button:Refresh() end
    if self.cheatsButton then self.cheatsButton:Refresh() end
end

function HG:DropDown(parent, name, x, y, width, items, selected, changed)
    local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", x, y)
    UIDropDownMenu_SetWidth(dropdown, width)
    local current = selected or items[1]
    UIDropDownMenu_SetText(dropdown, current.text or current.name)
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        for _, item in ipairs(items) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.text or item.name
            info.checked = item == current
            info.func = function()
                current = item
                UIDropDownMenu_SetText(dropdown, item.text or item.name)
                CloseDropDownMenus()
                if changed then changed(item) end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    function dropdown:GetSelected() return current end
    function dropdown:SetItems(newItems, newSelected)
        items = newItems
        current = newSelected or items[1]
        UIDropDownMenu_SetText(dropdown, current.text or current.name)
    end
    return dropdown
end
