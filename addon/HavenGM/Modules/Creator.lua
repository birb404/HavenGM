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
    local npc = HG:Section(parent, "NPC", 12, -12, 736, 116)
    HG:Label(npc, "Name", 14, -44)
    local npcSearch = HG:Edit(npc, "creatorSearch", 56, -35, 146, false, "")
    HG:ClearButton(npc, npcSearch, 208, -35)
    HG:Button(npc, "SEARCH", 246, -35, 78, function()
        HG:LookupInto("lookupCreature", npcSearch:GetText(), "creatorEntry")
    end)
    HG:Label(npc, "ID", 334, -44)
    HG:Edit(npc, "creatorEntry", 366, -35, 76, true, "")
    HG:Button(npc, "TEMP", 452, -35, 68, function()
        local id = HG:GetPositiveInteger("creatorEntry", "NPC ID")
        if id then HG:Execute("npcAddTemp", id) end
    end, "Temporary test spawn.")
    HG:Button(npc, "PERM", 530, -35, 68, function()
        local id = HG:GetPositiveInteger("creatorEntry", "NPC ID")
        if id then HG:ExecuteConfirmed("npcAdd", "Create a persistent NPC spawn?", id) end
    end, "Persistent database spawn. Confirmation required.")

    HG:Button(npc, "DELETE", 14, -75, 72, function()
        HG:ExecuteConfirmed("npcDelete", "Delete the selected NPC spawn?")
    end)
    local follow = HG:Button(npc, "FOLLOW OFF", 96, -75, 104, function() HG:ToggleTargetFollower() end)
    HG.followButton = follow
    follow:SetScript("OnLeave", function() HG:RefreshFollowerButton(); GameTooltip_Hide() end)
    HG:RefreshFollowerButton()
    local faction = HG:Button(npc, "FRIENDLY", 210, -75, 108, function() HG:ToggleTargetFaction() end)
    HG.factionButton = faction
    faction:SetScript("OnLeave", function() HG:RefreshFactionButton(); GameTooltip_Hide() end)
    HG:RefreshFactionButton()
    HG:PairToggle(npc, "possess", "POSSESS", 328, -75, 118, "possess", "unpossess")
    HG:Button(npc, "RESPAWN", 456, -75, 88, function() HG:Execute("respawn") end)

    local object = HG:Section(parent, "GAMEOBJECT", 12, -140, 736, 78)
    HG:Label(object, "Name", 14, -44)
    local objectSearch = HG:Edit(object, "objectSearch", 56, -35, 146, false, "")
    HG:ClearButton(object, objectSearch, 208, -35)
    HG:Button(object, "SEARCH", 246, -35, 78, function()
        HG:LookupInto("lookupObject", objectSearch:GetText(), "objectEntry")
    end)
    HG:Label(object, "ID", 334, -44)
    HG:Edit(object, "objectEntry", 366, -35, 76, true, "")
    HG:Button(object, "TEMP", 452, -35, 68, function()
        local id = HG:GetPositiveInteger("objectEntry", "GameObject ID")
        if id then HG:Execute("objectAddTemp", id) end
    end)
    HG:Button(object, "PERM", 530, -35, 68, function()
        local id = HG:GetPositiveInteger("objectEntry", "GameObject ID")
        if id then HG:ExecuteConfirmed("objectAdd", "Create a persistent GameObject?", id) end
    end)

    local scene = HG:Section(parent, "SCENE ACTIONS", 12, -230, 736, 138)
    HG:Label(scene, "Emote preset", 14, -44)
    local emoteDrop = HG:DropDown(scene, "HavenGMEmotePresetDropDown", 86, -35, 160, emotePresets, emotePresets[1])
    HG:Button(scene, "PLAY", 280, -37, 72, function()
        HG:Execute("npcEmote", emoteDrop:GetSelected().id)
    end, "Runs a known emote ID on the selected NPC.")
    HG:Label(scene, "Reliable visible actions are provided as presets. Raw animation and sound IDs are under Debug.", 370, -44, 340)

    HG:Label(scene, "Speech", 14, -88)
    HG:Edit(scene, "npcSpeech", 62, -79, 420, false, "")
    HG:Button(scene, "SAY", 492, -79, 72, function()
        local value = textValue("npcSpeech", "speech text")
        if value then HG:Execute("npcSay", value) end
    end)
    HG:Button(scene, "YELL", 574, -79, 72, function()
        local value = textValue("npcSpeech", "speech text")
        if value then HG:Execute("npcYell", value) end
    end)
end)
