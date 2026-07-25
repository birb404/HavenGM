local _, HG = ...

HG:RegisterTab("general", "GENERAL", 1, function(parent)
    local cheats = HG:Section(parent, "CHEATS", 12, -12, 736, 96)
    local cheatsButton
    cheatsButton = HG:Button(cheats, "CHEATS", 14, -42, 118, function()
        local enabled = HG.db.cheatsEnabled ~= true
        HG.db.cheatsEnabled = enabled
        for _, key in ipairs({ "god", "cast", "cooldown", "power" }) do
            HG.db.toggles[key] = enabled
        end
        HG:Execute("cheats", enabled and "on" or "off")
        HG:RefreshRuntimeButtons()
    end, "Toggles GM mode, God, instant casting, cooldowns and power. Fly is separate.")
    function cheatsButton:Refresh()
        local enabled = HG.db.cheatsEnabled == true
        self.label:SetText("CHEATS " .. (enabled and "ON" or "OFF"))
        self:SetRestingColor(enabled and HG.colors.on or HG.colors.off)
    end
    cheatsButton:SetScript("OnLeave", function(self) self:Refresh(); GameTooltip_Hide() end)
    HG.cheatsButton = cheatsButton
    cheatsButton:Refresh()

    HG:RuntimeToggle(cheats, "god", "GOD", 142, -42, 100, "god")
    HG:RuntimeToggle(cheats, "cast", "CAST", 252, -42, 100, "cast")
    HG:RuntimeToggle(cheats, "cooldown", "CD", 362, -42, 100, "cooldown")
    HG:RuntimeToggle(cheats, "power", "POWER", 472, -42, 108, "power")
    HG:RuntimeToggle(cheats, "fly", "FLY", 590, -42, 100, "fly")

    local combat = HG:Section(parent, "COMBAT", 12, -120, 736, 88)
    HG:Button(combat, "KILL TARGET", 14, -42, 118, function() HG:Execute("kill") end)
    HG:Button(combat, "REVIVE SELF", 142, -42, 108, function()
        HG:Execute("reviveName", UnitName("player"))
    end, "Revives your own character by name. HavenCore's bare .revive command requires a selected player.")
    HG:Button(combat, "REPAIR SELF", 260, -42, 108, function()
        HG:Execute("repairName", UnitName("player"))
    end, "Repairs all durability on your own character.")
    HG:Button(combat, "SAVE CHARACTER", 378, -42, 132, function() HG:Execute("save") end,
        "Writes your current character state to the character database immediately.")

    local utilities = HG:Section(parent, "UTILITIES", 12, -220, 736, 136)
    HG:Label(utilities, "Speed", 14, -46)
    local speedDisplay = HG:ReadOnly(utilities, 62, -37, 58, HG.db.inputs.speed or "1")
    HG.fields.speed = speedDisplay
    local presets = { 1, 2, 3, 5, 7, 10, 15, 20 }
    for index, value in ipairs(presets) do
        HG:Button(utilities, tostring(value), 136 + ((index - 1) * 52), -37, 44, function()
            speedDisplay:SetText(value)
            HG.db.inputs.speed = tostring(value)
            HG:Execute("speed", value)
        end, "Apply movement speed x" .. value .. ".")
    end
    HG:Button(utilities, "RESET SPEED", 566, -37, 126, function()
        speedDisplay:SetText("1")
        HG.db.inputs.speed = "1"
        HG:Execute("speed", 1)
    end)
    HG:Label(utilities,
        "Speed presets apply immediately. The display is read-only and shows the last speed requested by HavenGM.",
        14, -88, 680)
end)
