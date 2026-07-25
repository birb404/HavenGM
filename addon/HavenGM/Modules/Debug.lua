local _, HG = ...

HG:RegisterTab("debug", "DEBUG", 7, function(parent)
    local position = HG:Section(parent, "LIVE POSITION", 12, -12, 736, 58)
    local positionText = position:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    positionText:SetPoint("TOPLEFT", 14, -38)
    positionText:SetWidth(700)
    positionText:SetJustifyH("LEFT")
    local elapsed = 0
    position:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed < 0.5 then return end
        elapsed = 0
        local x, y, z, map = UnitPosition("player")
        local uiMap = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
        positionText:SetText(string.format(
            "World Map: %s   UI Map: %s   X: %.2f   Y: %.2f",
            tostring(map or "n/a"), tostring(uiMap or "n/a"), x or 0, y or 0
        ))
    end)

    local inspect = HG:Section(parent, "INSPECTION & ADVANCED ACTIONS", 12, -82, 736, 116)
    local inspectActions = {
        HG:Button(inspect, "GPS", 0, -42, 68, function() HG:Execute("gps") end),
        HG:Button(inspect, "GUID", 0, -42, 68, function() HG:Execute("guid") end),
        HG:Button(inspect, "DISTANCE", 0, -42, 84, function() HG:Execute("distance") end),
        HG:Button(inspect, "NPC INFO", 0, -42, 88, function() HG:Execute("npcInfo") end),
        HG:Button(inspect, "OBJECT INFO", 0, -42, 102, function() HG:Execute("objectInfo") end),
        HG:Button(inspect, "LINE OF SIGHT", 0, -42, 116, function() HG:Execute("debugLOS") end),
        HG:Button(inspect, "AURAS", 0, -42, 72, function() HG:Execute("listAuras") end),
    }
    HG:CenterRow(inspect, inspectActions, -42, 8)

    local nearNPCs = HG:Button(inspect, "NEAR NPCS", 0, -81, 94, function()
        HG:Execute("npcNear", 50)
    end)
    local nearObjects = HG:Button(inspect, "NEAR OBJECTS", 0, -81, 108, function()
        HG:Execute("objectNear", 50)
    end)

    local soundGroup = CreateFrame("Frame", nil, inspect)
    soundGroup:SetSize(214, HG.layout.controlHeight)
    HG:Label(soundGroup, "Sound", 0, -9)
    local sound = HG:Edit(soundGroup, "soundID", 46, 0, 62, true, "")
    HG:ClearButton(soundGroup, sound, 118, 0)
    HG:Button(soundGroup, "PLAY", 156, 0, 58, function()
        local id = HG:GetPositiveInteger("soundID", "sound ID")
        if id then HG:Execute("debugSound", id) end
    end)

    local animationGroup = CreateFrame("Frame", nil, inspect)
    animationGroup:SetSize(206, HG.layout.controlHeight)
    HG:Label(animationGroup, "Anim", 0, -9)
    local animation = HG:Edit(animationGroup, "animationID", 38, 0, 62, true, "")
    HG:ClearButton(animationGroup, animation, 110, 0)
    HG:Button(animationGroup, "PLAY", 148, 0, 58, function()
        local id = HG:GetPositiveInteger("animationID", "animation ID")
        if id then HG:Execute("debugAnim", id) end
    end)
    HG:CenterRow(inspect, { nearNPCs, nearObjects, soundGroup, animationGroup }, -81, 10)

    local output = HG:Section(parent, "SERVER OUTPUT", 12, -210, 736, 208)
    local scroll = CreateFrame("ScrollFrame", "HavenGMDebugOutputScroll", output, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -40)
    scroll:SetPoint("BOTTOMRIGHT", -176, 14)
    local text = CreateFrame("EditBox", nil, scroll)
    text:SetMultiLine(true)
    text:SetAutoFocus(false)
    text:SetFontObject(ChatFontNormal)
    text:SetWidth(536)
    text:SetHeight(150)
    text:SetTextInsets(4, 4, 4, 4)
    text:SetScript("OnEscapePressed", text.ClearFocus)
    scroll:SetScrollChild(text)
    local function refreshScrollBar()
        C_Timer.After(0, function()
            local scrollBar = scroll.ScrollBar or _G.HavenGMDebugOutputScrollScrollBar
            if scrollBar then scrollBar:SetShown((scroll:GetVerticalScrollRange() or 0) > 0) end
        end)
    end
    HG.output.Refresh = function(self)
        text:SetText(self:GetText())
        text:SetCursorPosition(0)
        refreshScrollBar()
    end
    HG.output:Refresh()
    scroll:SetScript("OnSizeChanged", refreshScrollBar)
    HG:Button(output, "SELECT ALL", 604, -40, 102, function()
        text:SetFocus()
        text:HighlightText()
    end)
    HG:Button(output, "CLEAR", 604, -76, 102, function()
        HG.output.lines = {}
        HG.output:Refresh()
    end)
    HG:Label(output, "First ID", 604, -116)
    local firstID = HG:Edit(output, "debugFirstID", 610, -132, 60, true, "")
    HG:ClearButton(output, firstID, 678, -132)
    HG:Button(output, "EXTRACT", 604, -164, 102, function()
        local id = HG.output:FirstID()
        if id then
            firstID:SetText(id)
            firstID:SetFocus()
            firstID:HighlightText()
        else
            HG:Notify("No numeric ID found in the captured output.")
        end
    end, "Extracts the first recognized ID and selects it for copying.")
end)
