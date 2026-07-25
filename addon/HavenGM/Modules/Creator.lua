local _, HG = ...

local function textValue(key, label)
    local field = HG.fields[key]
    local value = field and strtrim(field:GetText() or "")
    if not value or value == "" then
        HG:Notify("Enter " .. label .. ".")
        if field then field:SetFocus() end
        return nil
    end
    return value
end

local emotePresets = {
    { text = "Talk", id = 1 }, { text = "Bow", id = 2 },
    { text = "Wave", id = 3 }, { text = "Cheer", id = 4 },
    { text = "Exclamation", id = 5 }, { text = "Question", id = 6 },
    { text = "Eat", id = 7 }, { text = "Dance", id = 10 },
    { text = "Laugh", id = 11 }, { text = "Sit", id = 13 },
    { text = "Rude", id = 14 }, { text = "Roar", id = 15 },
    { text = "Kneel", id = 16 }, { text = "Kiss", id = 17 },
    { text = "Cry", id = 18 }, { text = "Chicken", id = 19 },
    { text = "Beg", id = 20 }, { text = "Applaud", id = 21 },
    { text = "Shout", id = 22 }, { text = "Flex", id = 23 },
    { text = "Shy", id = 24 }, { text = "Point", id = 25 },
}

HG:RegisterTab("creator", "CREATOR", 6, function(parent)
    local npc = HG:Section(parent, "NPC", 12, -12, 736, 124)
    HG:Label(npc, "Name", 14, -50)
    local npcSearch = HG:Edit(npc, "creatorSearch", 90, -41, 146, false, "")
    HG:ClearButton(npc, npcSearch, 246, -41)
    HG:Button(npc, "SEARCH", 284, -41, 78, function()
        HG:LookupInto("lookupCreature", npcSearch:GetText(), "creatorEntry")
    end)
    HG:Label(npc, "ID", 376, -50)
    local npcID = HG:Edit(npc, "creatorEntry", 406, -41, 76, true, "")
    HG:ClearButton(npc, npcID, 492, -41)
    HG:Button(npc, "TEMP", 530, -41, 68, function()
        local id = HG:GetPositiveInteger("creatorEntry", "NPC ID")
        if id then HG:Execute("npcAddTemp", id) end
    end, "Temporary test spawn.")
    HG:Button(npc, "PERM", 608, -41, 68, function()
        local id = HG:GetPositiveInteger("creatorEntry", "NPC ID")
        if id then HG:ExecuteConfirmed("npcAdd", "Create a persistent NPC spawn?", id) end
    end, "Persistent database spawn. Confirmation required.")

    local npcActions = {}
    npcActions[#npcActions + 1] = HG:Button(npc, "DELETE", 0, -75, 72, function()
        HG:ExecuteConfirmed("npcDelete", "Delete the selected NPC spawn?")
    end)
    local follow = HG:Button(npc, "FOLLOW OFF", 0, -75, 104, function() HG:ToggleTargetFollower() end)
    npcActions[#npcActions + 1] = follow
    HG.followButton = follow
    follow:SetScript("OnLeave", function() HG:RefreshFollowerButton(); GameTooltip_Hide() end)
    HG:RefreshFollowerButton()
    local faction = HG:Button(npc, "FRIENDLY", 0, -75, 108, function() HG:ToggleTargetFaction() end)
    npcActions[#npcActions + 1] = faction
    HG.factionButton = faction
    faction:SetScript("OnLeave", function() HG:RefreshFactionButton(); GameTooltip_Hide() end)
    HG:RefreshFactionButton()
    npcActions[#npcActions + 1] = HG:PossessToggle(npc, 0, -75, 118)
    npcActions[#npcActions + 1] = HG:Button(npc, "RESPAWN", 0, -75, 88, function() HG:Execute("respawn") end)
    HG:AlignRow(npc, npcActions, 90, -85, 10)

    local object = HG:Section(parent, "GAMEOBJECT", 12, -146, 736, 100)
    HG:Label(object, "Name", 14, -62)
    local objectSearch = HG:Edit(object, "objectSearch", 90, -53, 146, false, "")
    HG:ClearButton(object, objectSearch, 246, -53)
    HG:Button(object, "SEARCH", 284, -53, 78, function()
        HG:LookupInto("lookupObject", objectSearch:GetText(), "objectEntry")
    end)
    HG:Label(object, "ID", 376, -62)
    local objectID = HG:Edit(object, "objectEntry", 406, -53, 76, true, "")
    HG:ClearButton(object, objectID, 492, -53)
    HG:Button(object, "TEMP", 530, -53, 68, function()
        local id = HG:GetPositiveInteger("objectEntry", "GameObject ID")
        if id then HG:Execute("objectAddTemp", id) end
    end)
    HG:Button(object, "PERM", 608, -53, 68, function()
        local id = HG:GetPositiveInteger("objectEntry", "GameObject ID")
        if id then HG:ExecuteConfirmed("objectAdd", "Create a persistent GameObject?", id) end
    end)

    local scene = HG:Section(parent, "SCENE ACTIONS", 12, -258, 736, 158)
    HG:Label(scene, "Emote preset", 14, -67)
    local emoteDrop = HG:DropDown(scene, "HavenGMEmotePresetDropDown", 90, -58, 160, emotePresets, emotePresets[1])
    HG:Button(scene, "PLAY", 294, -60, 72, function()
        HG:Execute("npcEmote", emoteDrop:GetSelected().id)
    end, "Runs a known emote ID on the selected NPC.")
    HG:Label(scene, "Speech", 14, -117)
    local speech = HG:Edit(scene, "npcSpeech", 90, -108, 354, false, "")
    HG:ClearButton(scene, speech, 454, -108)
    HG:Button(scene, "SAY", 492, -108, 72, function()
        local value = textValue("npcSpeech", "speech text")
        if value then HG:Execute("npcSay", value) end
    end)
    HG:Button(scene, "YELL", 574, -108, 72, function()
        local value = textValue("npcSpeech", "speech text")
        if value then HG:Execute("npcYell", value) end
    end)
end)
