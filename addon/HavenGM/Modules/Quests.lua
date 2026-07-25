local _, HG = ...

local function questTitle(questID)
    questID = tonumber(questID)
    if not questID then return nil end

    if C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local ok, title = pcall(C_QuestLog.GetTitleForQuestID, questID)
        if ok and title and title ~= "" then return title end
    end
    if GetQuestInfo then
        local ok, title = pcall(GetQuestInfo, questID)
        if ok and title and title ~= "" then return title end
    end
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
        for index = 1, C_QuestLog.GetNumQuestLogEntries() do
            local info = C_QuestLog.GetInfo(index)
            if info and info.questID == questID and info.title and info.title ~= "" then
                return info.title
            end
        end
    end
    return nil
end

local requestedQuests = {}
local function requestQuest(questID)
    if C_QuestLog and C_QuestLog.RequestLoadQuestByID and questID and not requestedQuests[questID] then
        requestedQuests[questID] = true
        pcall(C_QuestLog.RequestLoadQuestByID, questID)
    end
end

local function clientQuestLine(questID)
    if not questID or not C_QuestLine or not C_QuestLine.GetQuestLineInfo or
        not C_QuestLine.GetQuestLineQuests then return nil end

    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local ok, info = pcall(C_QuestLine.GetQuestLineInfo, questID, mapID)
    if not ok or type(info) ~= "table" or not info.questLineID then return nil end

    local questsOK, quests = pcall(C_QuestLine.GetQuestLineQuests, info.questLineID)
    if not questsOK or type(quests) ~= "table" then return nil end

    local ids = {}
    for _, quest in ipairs(quests) do
        local id = type(quest) == "table" and
            (quest.questID or quest.questId or quest.QuestID) or tonumber(quest)
        if id then ids[#ids + 1] = tonumber(id) end
    end
    return #ids > 0 and ids or nil
end

local function databaseQuestLine(questID)
    local data = HG.questChainData
    if not data or not data[questID] then return nil end

    local ids = { questID }
    local seen = { [questID] = true }
    local current = questID
    for _ = 1, 100 do
        local link = data[current]
        local previous = link and tonumber(link.prev)
        if not previous or previous == 0 or seen[previous] then break end
        table.insert(ids, 1, previous)
        seen[previous] = true
        current = previous
    end

    current = questID
    for _ = 1, 100 do
        local link = data[current]
        local nextQuest = link and tonumber(link.next)
        if not nextQuest or nextQuest == 0 or seen[nextQuest] then break end
        ids[#ids + 1] = nextQuest
        seen[nextQuest] = true
        current = nextQuest
    end
    return ids
end

local function resolvedQuestTitle(questID)
    local clientTitle = questTitle(questID)
    if clientTitle then return clientTitle end
    local databaseEntry = HG.questChainData and HG.questChainData[tonumber(questID)]
    return databaseEntry and databaseEntry.title ~= "" and databaseEntry.title or nil
end

HG:RegisterTab("quests", "QUESTS", 3, function(parent)
    local section = HG:Section(parent, "QUEST TESTING", 12, -12, 736, 404)

    HG:Label(section, "Search", 14, -53)
    local search = HG:Edit(section, "questSearch", 84, -44, 220, false, "")
    HG:ClearButton(section, search, 314, -44)
    HG:Button(section, "SEARCH", 352, -44, 88, function()
        local query = strtrim(search:GetText() or "")
        if query == "" then HG:Notify("Enter a quest name or ID.") return end
        HG:OpenLookupModal("lookupQuest", query, "questID", "QUESTS")
    end)

    HG:Label(section, "Quest ID", 14, -91)
    local questField = HG:Edit(section, "questID", 84, -82, 110, true, "")
    HG:ClearButton(section, questField, 204, -82, function()
        HG:SetField("questSearch", "")
        if HG.RefreshQuestChain then HG:RefreshQuestChain() end
    end)

    HG:Button(section, "ADD", 84, -124, 92, function()
        local id = HG:GetPositiveInteger("questID", "quest ID")
        if id then HG:Execute("questAdd", id) end
    end)
    HG:SecureSelfButton(section, "REMOVE", 196, -124, 104, function()
        local id = HG:GetPositiveInteger("questID", "quest ID")
        if id then HG:Execute("questRemove", id) end
    end, "Securely targets your own character before removing the quest.")

    HG:Button(section, "COMPLETE", 84, -164, 112, function()
        local id = HG:GetPositiveInteger("questID", "quest ID")
        if id then HG:Execute("questComplete", id) end
    end, "Force-completes standard objectives. Scripted quests can still require their actual events.")
    HG:Button(section, "GO TO OBJECTIVE", 216, -164, 152, function()
        local id = HG:GetPositiveInteger("questID", "quest ID")
        if id then HG:Execute("questGo", id) end
    end)

    HG:Button(section, "RESET FOR REPLAY", 84, -204, 172, function()
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
    end, "Clears active/rewarded state and adds the quest again. Use outside combat.")

    HG:Label(section, "QUEST CHAIN", 14, -257)
    local chainStatus = HG:Label(section, "", 118, -257, 590)
    chainStatus:SetTextColor(0.72, 0.78, 0.88)

    local cards = {}
    local cardDefinitions = {
        { x = 18, role = "PREVIOUS", color = HG.colors.questPrevious, hover = HG.colors.questPreviousHover },
        { x = 263, role = "SELECTED", color = HG.colors.gold, hover = HG.colors.goldHover },
        { x = 508, role = "NEXT", color = HG.colors.questNext, hover = HG.colors.questNextHover },
    }
    for index, definition in ipairs(cardDefinitions) do
        local cardIndex = index
        local restingColor = definition.color
        local hoverColor = definition.hover
        local card = HG:Button(section, definition.role, definition.x, -290, 210, function()
            local data = cards[cardIndex].questID
            if data then
                HG:SetField("questID", data)
                HG:SetField("questSearch", resolvedQuestTitle(data) or "")
                HG:RefreshQuestChain(data)
            end
        end)
        card:SetSize(210, 80)
        card:SetRestingColor(restingColor)
        card:SetScript("OnEnter", function(self)
            self:SetBackdropColor(unpack(hoverColor))
        end)
        card:SetScript("OnLeave", function(self)
            self:RestoreColor()
            GameTooltip_Hide()
        end)
        card.label:ClearAllPoints()
        card.label:SetPoint("TOPLEFT", 8, -8)
        card.label:SetPoint("BOTTOMRIGHT", -8, 8)
        card.label:SetJustifyH("CENTER")
        card.label:SetJustifyV("MIDDLE")
        cards[cardIndex] = card
    end

    local function setCard(card, role, questID)
        card.questID = questID
        card:SetEnabled(questID ~= nil)
        card:SetAlpha(questID and 1 or 0.42)
        if questID then
            requestQuest(questID)
            local title = resolvedQuestTitle(questID)
            if not title and questID == tonumber(questField:GetText()) then
                local selectedName = strtrim(search:GetText() or "")
                if selectedName ~= "" then title = selectedName end
            end
            if title then
                card.label:SetText(role .. "\n" .. title .. "\nID " .. questID)
            else
                card.label:SetText(role .. "\nID " .. questID)
            end
        else
            card.label:SetText(role .. "\nNone")
        end
    end

    function HG:RefreshQuestChain(forcedID)
        local questID = tonumber(forcedID) or tonumber(questField:GetText())
        if not questID then
            self.questChainIDs, self.questChainIndex = nil, nil
            setCard(cards[1], "PREVIOUS", nil)
            setCard(cards[2], "SELECTED", nil)
            setCard(cards[3], "NEXT", nil)
            chainStatus:SetText("Enter or select a quest ID.")
            return
        end

        requestQuest(questID)
        local ids = databaseQuestLine(questID)
        local source = ids and "HavenCore database" or nil
        if not ids then
            ids = clientQuestLine(questID)
            source = ids and "Client quest line" or nil
        end
        ids = ids or { questID }
        local selectedIndex = 1
        for index, id in ipairs(ids) do
            if id == questID then selectedIndex = index break end
        end
        self.questChainIDs = ids
        self.questChainIndex = selectedIndex
        setCard(cards[1], "PREVIOUS", ids[selectedIndex - 1])
        setCard(cards[2], "SELECTED", questID)
        setCard(cards[3], "NEXT", ids[selectedIndex + 1])
        if #ids > 1 then
            chainStatus:SetText(source .. ": " .. selectedIndex .. " of " .. #ids)
        else
            chainStatus:SetText("No chain relation is available for this quest.")
        end
    end

    questField:HookScript("OnTextChanged", function()
        C_Timer.After(0, function()
            if HG.RefreshQuestChain then HG:RefreshQuestChain() end
        end)
    end)

    local questEvents = CreateFrame("Frame")
    questEvents:RegisterEvent("QUEST_DATA_LOAD_RESULT")
    questEvents:SetScript("OnEvent", function()
        if parent:IsShown() and HG.RefreshQuestChain then HG:RefreshQuestChain() end
    end)

    HG:RefreshQuestChain()
end)
