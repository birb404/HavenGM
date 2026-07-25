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
            "World Map: %s   UI Map: %s   X: %.2f   Y: %.2f   Z: %.2f",
            tostring(map or "n/a"), tostring(uiMap or "n/a"), x or 0, y or 0, z or 0
        ))
    end)

    local inspect = HG:Section(parent, "INSPECTION & ADVANCED ACTIONS", 12, -82, 736, 116)
    HG:Button(inspect, "GPS", 14, -42, 68, function() HG:Execute("gps") end)
    HG:Button(inspect, "GUID", 92, -42, 68, function() HG:Execute("guid") end)
    HG:Button(inspect, "DISTANCE", 170, -42, 84, function() HG:Execute("distance") end)
    HG:Button(inspect, "NPC INFO", 264, -42, 88, function() HG:Execute("npcInfo") end)
    HG:Button(inspect, "OBJECT INFO", 362, -42, 102, function() HG:Execute("objectInfo") end)
    HG:Button(inspect, "LINE OF SIGHT", 474, -42, 116, function() HG:Execute("debugLOS") end)
    HG:Button(inspect, "AURAS", 600, -42, 72, function() HG:Execute("listAuras") end)

    HG:Label(inspect, "Range", 14, -82)
    HG:Edit(inspect, "nearRange", 58, -73, 58, true, "25")
    HG:Button(inspect, "NEAR NPCS", 126, -73, 94, function()
        local range = HG:GetPositiveInteger("nearRange", "range", 500)
        if range then HG:Execute("npcNear", range) end
    end)
    HG:Button(inspect, "NEAR OBJECTS", 230, -73, 108, function()
        local range = HG:GetPositiveInteger("nearRange", "range", 500)
        if range then HG:Execute("objectNear", range) end
    end)
    HG:Label(inspect, "Sound", 350, -82)
    HG:Edit(inspect, "soundID", 396, -73, 62, true, "")
    HG:Button(inspect, "PLAY", 468, -73, 58, function()
        local id = HG:GetPositiveInteger("soundID", "sound ID")
        if id then HG:Execute("debugSound", id) end
    end)
    HG:Label(inspect, "Anim", 538, -82)
    HG:Edit(inspect, "animationID", 576, -73, 62, true, "")
    HG:Button(inspect, "PLAY", 648, -73, 58, function()
        local id = HG:GetPositiveInteger("animationID", "animation ID")
        if id then HG:Execute("debugAnim", id) end
    end)

    local output = HG:Section(parent, "SERVER OUTPUT", 12, -210, 736, 166)
    local scroll = CreateFrame("ScrollFrame", "HavenGMDebugOutputScroll", output, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -40)
    scroll:SetPoint("BOTTOMRIGHT", -34, 40)
    local text = CreateFrame("EditBox", nil, scroll)
    text:SetMultiLine(true)
    text:SetAutoFocus(false)
    text:SetFontObject(ChatFontNormal)
    text:SetWidth(660)
    text:SetHeight(90)
    text:SetTextInsets(4, 4, 4, 4)
    text:SetScript("OnEscapePressed", text.ClearFocus)
    scroll:SetScrollChild(text)
    HG.output.Refresh = function(self)
        text:SetText(self:GetText())
        text:SetCursorPosition(0)
    end
    HG.output:Refresh()
    HG:Button(output, "SELECT ALL", 14, -132, 96, function()
        text:SetFocus()
        text:HighlightText()
    end)
    HG:Button(output, "CLEAR", 120, -132, 72, function()
        HG.output.lines = {}
        HG.output:Refresh()
    end)
    HG:Label(output, "First ID", 210, -140)
    local firstID = HG:Edit(output, "debugFirstID", 264, -132, 82, true, "")
    HG:Button(output, "EXTRACT", 356, -132, 78, function()
        local id = HG.output:FirstID()
        if id then
            firstID:SetText(id)
            firstID:SetFocus()
            firstID:HighlightText()
        else
            HG:Notify("No numeric ID found in the captured output.")
        end
    end, "Extracts the first recognized ID and selects it for copying.")
    HG:Label(output, "Captured responses stay out of normal chat.", 450, -138, 250)
end)
