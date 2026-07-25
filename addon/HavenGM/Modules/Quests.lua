local _, HG = ...

HG:RegisterTab("quests", "QUESTS", 3, function(parent)
    local section = HG:Section(parent, "QUEST TESTING", 12, -12, 736, 246)
    HG:Label(section, "Search", 14, -46)
    local search = HG:Edit(section, "questSearch", 74, -37, 220, false, "")
    HG:ClearButton(section, search, 300, -37)
    HG:Button(section, "SEARCH", 338, -37, 88, function()
        local query = strtrim(search:GetText() or "")
        if query == "" then HG:Notify("Enter a quest name or ID.") return end
        HG:OpenLookupModal("lookupQuest", query, "questID", "QUESTS")
    end)

    HG:Label(section, "Quest ID", 14, -86)
    HG:Edit(section, "questID", 74, -77, 110, true, "")
    HG:Button(section, "LOAD SELECTED QUEST", 194, -77, 154, function()
        local selected = C_QuestLog and C_QuestLog.GetSelectedQuest and C_QuestLog.GetSelectedQuest()
        selected = (selected and selected > 0 and selected) or HG.lastQuestID
        if selected and selected > 0 then
            HG:SetField("questID", selected)
            if HG.lastQuestName then HG:SetField("questSearch", HG.lastQuestName) end
            HG:Notify("Loaded selected quest ID: " .. selected)
        else
            HG:Notify("Select a quest in Map & Quest Log first.")
        end
    end, "Loads the quest currently selected in Map & Quest Log. This avoids Blizzard's modified-click bindings.")

    HG:Button(section, "ADD", 14, -120, 76, function()
        local id = HG:GetPositiveInteger("questID", "quest ID")
        if id then HG:Execute("questAdd", id) end
    end)
    HG:Button(section, "COMPLETE", 100, -120, 98, function()
        local id = HG:GetPositiveInteger("questID", "quest ID")
        if id then HG:Execute("questComplete", id) end
    end, "Force-completes standard objectives. Scripted or scenario-specific quest logic may still require normal gameplay.")
    HG:SecureSelfButton(section, "REMOVE", 208, -120, 88, function()
        local id = HG:GetPositiveInteger("questID", "quest ID")
        if id then HG:Execute("questRemove", id) end
    end, "Securely targets your own character before removing the quest.")
    HG:Button(section, "GO TO OBJECTIVE", 306, -120, 142, function()
        local id = HG:GetPositiveInteger("questID", "quest ID")
        if id then HG:Execute("questGo", id) end
    end)
    HG:SecureSelfButton(section, "RESET FOR REPLAY", 458, -120, 142, function()
        local id = HG:GetPositiveInteger("questID", "quest ID")
        if not id then return end
        HG:Confirm(
            "Remove active/rewarded state and add this quest again?\nYour own character will be targeted.",
            ".quest remove " .. id .. "\n.quest add " .. id,
            function()
                HG:Execute("questRemove", id)
                C_Timer.After(0.35, function() HG:Execute("questAdd", id) end)
            end
        )
    end, "Securely targets yourself, clears active/rewarded state and adds the quest again. Use outside combat.")

    local note = HG:Label(section,
        "COMPLETE uses HavenCore ForceCompleteQuest. It works well for normal objectives, but scripted quests can still require their actual events.",
        14, -168, 690)
    note:SetTextColor(0.72, 0.78, 0.88)
    local replay = HG:Label(section,
        "RESET FOR REPLAY selects your character, removes active/rewarded state, then adds the quest again.",
        14, -202, 690)
    replay:SetTextColor(0.72, 0.78, 0.88)
end)
