local _, HG = ...

local function check(parent, text, x, y, getter, setter)
    local button = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    button:SetPoint("TOPLEFT", x, y)
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", button, "RIGHT", 2, 1)
    label:SetText(text)
    button:SetChecked(getter())
    button:SetScript("OnClick", function(self) setter(self:GetChecked() == true) end)
    return button
end

HG:RegisterTab("settings", "SETTINGS", 8, function(parent)
    local section = HG:Section(parent, "ADDON SETTINGS", 12, -12, 736, 282)
    check(section, "Echo commands in chat", 14, -42,
        function() return HG.db.settings.echoCommands ~= false end,
        function(v) HG.db.settings.echoCommands = v end)
    check(section, "Show Item IDs", 14, -76,
        function() return HG.db.settings.showItemIDs ~= false end,
        function(v) HG.db.settings.showItemIDs = v end)
    check(section, "Show NPC Entry and Spawn IDs", 14, -110,
        function() return HG.db.settings.showNPCIDs ~= false end,
        function(v) HG.db.settings.showNPCIDs = v end)
    check(section, "Show Quest IDs", 14, -144,
        function() return HG.db.settings.showQuestIDs ~= false end,
        function(v)
            HG.db.settings.showQuestIDs = v
            if HG.RefreshQuestIDs then HG.RefreshQuestIDs() end
        end)
    check(section, "Show GameObject IDs", 14, -178,
        function() return HG.db.settings.showObjectIDs ~= false end,
        function(v) HG.db.settings.showObjectIDs = v end)
    check(section, "Ctrl + Right-click captures IDs", 14, -212,
        function() return HG.db.settings.captureIDs ~= false end,
        function(v) HG.db.settings.captureIDs = v end)
    check(section, "Auto-fill NPC ID from target", 360, -144,
        function() return HG.db.settings.autoTargetIDs ~= false end,
        function(v) HG.db.settings.autoTargetIDs = v end)
    check(section, "Show minimap button", 360, -110,
        function() return HG.db.settings.showMinimap ~= false end,
        function(v) HG.db.settings.showMinimap = v; if HG.minimapButton then HG.minimapButton:SetShown(v) end end)
    check(section, "Confirm persistent and destructive commands", 360, -42,
        function() return HG.db.settings.confirmDangerous ~= false end,
        function(v) HG.db.settings.confirmDangerous = v end)
    check(section, "Lock frame position", 360, -76,
        function() return HG.db.settings.lockFrame == true end,
        function(v)
            HG.db.settings.lockFrame = v
            if HG.frame then HG.frame:SetMovable(not v) end
        end)

    HG:Label(section, "Scale", 360, -188)
    local scale = HG:Edit(section, "uiScale", 408, -179, 72, false, tostring(HG.db.settings.scale or 1))
    HG:Button(section, "APPLY", 490, -179, 76, function()
        local value = tonumber(scale:GetText())
        if not value or value < 0.65 or value > 1.35 then
            HG:Notify("Scale must be between 0.65 and 1.35.")
            return
        end
        HG.db.settings.scale = value
        HG.frame:SetScale(value)
    end)

    HG:Button(section, "RESET WINDOW POSITION", 360, -222, 190, function()
        HG.db.position = nil
        HG.frame:ClearAllPoints()
        HG.frame:SetPoint("CENTER")
    end)
    HG:Button(section, "RESET ADDON SETTINGS", 14, -252, 190, function()
        HG:Confirm("Reset every HavenGM setting and reload the UI?", "/reload", function()
            HavenGMDB = nil
            ReloadUI()
        end)
    end)
    local community = HG:Section(parent, "COMMUNITY", 12, -306, 350, 104)
    HG:Button(community, "WOW HAVEN DISCORD", 14, -40, 190, function()
        StaticPopup_Show("HAVENGM_DISCORD")
    end, "Opens a selectable invite link for the WoW Haven Discord server.")

    local about = HG:Section(parent, "ABOUT", 374, -306, 374, 104)
    HG:Label(about, "Addon created by Birb@", 14, -48, 220)
end)
