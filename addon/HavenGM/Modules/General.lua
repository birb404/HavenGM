local _, HG = ...

HG:RegisterTab("general", "GENERAL", 1, function(parent)
    local cheats = HG:Section(parent, "CHEATS", 12, -12, 736, 124)
    local cheatsButton
    local cheatControls = {}

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

    cheatsButton:SetScript("OnLeave", function(self)
        self:Refresh()
        GameTooltip_Hide()
    end)

    HG.cheatsButton = cheatsButton
    cheatsButton:Refresh()
    cheatControls[#cheatControls + 1] = cheatsButton

    cheatControls[#cheatControls + 1] =
        HG:RuntimeToggle(cheats, "god", "GOD", 0, -42, 108, "god")

    cheatControls[#cheatControls + 1] =
        HG:RuntimeToggle(cheats, "cast", "CAST", 0, -42, 108, "cast")

    cheatControls[#cheatControls + 1] =
        HG:RuntimeToggle(cheats, "cooldown", "CD", 0, -42, 108, "cooldown")

    cheatControls[#cheatControls + 1] =
        HG:RuntimeToggle(cheats, "power", "POWER", 0, -42, 108, "power")

    cheatControls[#cheatControls + 1] =
        HG:RuntimeToggle(cheats, "fly", "FLY", 0, -42, 108, "fly")

    cheatsButton:SetWidth(108)
    HG:CenterRow(cheats, cheatControls, -65, 10)

    local combat = HG:Section(parent, "COMBAT", 12, -146, 736, 124)
    local combatControls = {}

    combatControls[#combatControls + 1] =
        HG:Button(combat, "KILL TARGET", 0, -42, 126, function()
            HG:Execute("kill")
        end)

    combatControls[#combatControls + 1] =
        HG:Button(
            combat,
            "FOAM HIT",
            0,
            -42,
            126,
            function()
                if not UnitExists("target") then
                    HG:Notify("Select a target first.")
                    return
                end

                local current = UnitHealth("target") or 0

                if current <= 1 then
                    HG:Notify("The target is already at minimum safe health.")
                    return
                end

                -- Remove 80% of the target's current health.
                -- The final clamp ensures that the target is left with at least 1 HP.
                local damage = math.floor(current * 0.80)
                damage = math.max(1, math.min(damage, current - 1))

                HG:Execute("damage", damage)
            end,
            "Removes 80% of the target's current health without intentionally killing it."
        )

    combatControls[#combatControls + 1] =
        HG:Button(combat, "REVIVE SELF", 0, -42, 126, function()
            HG:Execute("reviveName", UnitName("player"))
        end, "Revives your own character by name. HavenCore's bare .revive command requires a selected player.")

    combatControls[#combatControls + 1] =
        HG:Button(combat, "REPAIR SELF", 0, -42, 126, function()
            HG:Execute("repairName", UnitName("player"))
        end, "Repairs all durability on your own character.")

    combatControls[#combatControls + 1] =
        HG:Button(combat, "SAVE CHARACTER", 0, -42, 126, function()
            HG:Execute("save")
        end, "Writes your current character state to the character database immediately.")

    HG:CenterRow(combat, combatControls, -65, 10)

    local utilities = HG:Section(parent, "UTILITIES", 12, -280, 736, 124)

    HG:Label(utilities, "Speed", 20, -74)

    local speedDisplay =
        HG:Edit(utilities, "speed", 68, -65, 58, true, HG.db.inputs.speed or "1")

    speedDisplay:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText())

        if not value or value < 1 or value > 20 then
            HG:Notify("Speed must be between 1 and 20.")
            return
        end

        value = math.floor(value)
        self:SetText(value)
        self:ClearFocus()
        HG:Execute("speed", value)
    end)

    HG:Step(
        utilities,
        speedDisplay,
        "-",
        136,
        -65,
        -1,
        1,
        20,
        function(value)
            HG:Execute("speed", value)
        end
    )

    HG:Step(
        utilities,
        speedDisplay,
        "+",
        174,
        -65,
        1,
        1,
        20,
        function(value)
            HG:Execute("speed", value)
        end
    )

    local presets = { 1, 2, 3, 5, 7, 10, 15, 20 }

    for index, value in ipairs(presets) do
        HG:Button(
            utilities,
            tostring(value),
            212 + ((index - 1) * 48),
            -65,
            38,
            function()
                speedDisplay:SetText(value)
                HG.db.inputs.speed = tostring(value)
                HG:Execute("speed", value)
            end,
            "Apply movement speed x" .. value .. "."
        )
    end

    HG:Button(utilities, "RESET SPEED", 602, -65, 114, function()
        speedDisplay:SetText("1")
        HG.db.inputs.speed = "1"
        HG:Execute("speed", 1)
    end)
end)