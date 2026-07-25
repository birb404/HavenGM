local _, HG = ...

function HG:InstallIntegrations()
    local function addItemID(tooltip)
        if HG.db.settings.showItemIDs == false then return end
        local _, link = tooltip:GetItem()
        local id = link and tonumber(link:match("item:(%d+)"))
        if id then tooltip:AddLine("Item ID: " .. id, 0.83, 0.61, 0.20); tooltip:Show() end
    end
    GameTooltip:HookScript("OnTooltipSetItem", addItemID)
    ItemRefTooltip:HookScript("OnTooltipSetItem", addItemID)

    local function creatureDataFromGUID(guid)
        if not guid then return nil end
        local kind, _, _, _, _, entry, spawn = strsplit("-", guid)
        if kind == "Creature" or kind == "Vehicle" then
            return tonumber(entry), spawn
        end
    end

    GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
        if HG.db.settings.showNPCIDs == false then return end
        local _, unit = tooltip:GetUnit()
        local entry, spawn = creatureDataFromGUID(unit and UnitGUID(unit))
        if entry then
            tooltip:AddLine("NPC Entry ID: " .. entry, 0.20, 0.85, 1.00)
            if spawn then tooltip:AddLine("Spawn GUID: " .. spawn, 0.55, 0.72, 0.90) end
            tooltip:Show()
        end
    end)

    local targetCapture = CreateFrame("Frame")
    targetCapture:RegisterEvent("PLAYER_TARGET_CHANGED")
    targetCapture:SetScript("OnEvent", function()
        local entry = not UnitIsPlayer("target") and creatureDataFromGUID(UnitGUID("target"))
        if entry then
            if HG.db.settings.autoTargetIDs ~= false then HG:SetField("creatorEntry", entry) end
        end
        HG:RefreshFollowerButton()
        HG:RefreshFactionButton()
    end)

    if ContainerFrameItemButton_OnModifiedClick then
        hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(self, button)
            if HG.db.settings.captureIDs == false or button ~= "RightButton" or not IsControlKeyDown() then return end
            local bag = self:GetParent() and self:GetParent():GetID()
            local link = bag and GetContainerItemLink(bag, self:GetID())
            local id = link and tonumber(link:match("item:(%d+)"))
            if id then
                HG:SetField("itemID", id)
                HG:SetField("itemSearch", "")
            end
        end)
    end

    local function questFromLink(link)
        return link and tonumber(link:match("quest:(%d+)"))
    end
    hooksecurefunc(GameTooltip, "SetHyperlink", function(tooltip, link)
        local id = questFromLink(link)
        if id and HG.db.settings.showQuestIDs ~= false then tooltip:AddLine("Quest ID: " .. id, 0.83, 0.61, 0.20); tooltip:Show() end
    end)
    hooksecurefunc(ItemRefTooltip, "SetHyperlink", function(tooltip, link)
        local id = questFromLink(link)
        if id and HG.db.settings.showQuestIDs ~= false then tooltip:AddLine("Quest ID: " .. id, 0.83, 0.61, 0.20); tooltip:Show() end
    end)
    if HandleModifiedItemClick then
        hooksecurefunc("HandleModifiedItemClick", function(link)
            if HG.db.settings.captureIDs ~= false and IsControlKeyDown() then
                local item = link and tonumber(link:match("item:(%d+)"))
                local quest = questFromLink(link)
                local spell = link and tonumber(link:match("spell:(%d+)"))
                if item then HG:SetField("itemID", item); HG:SetField("itemSearch", "")
                elseif quest then HG:SetField("questID", quest); HG:SetField("questSearch", "")
                elseif spell then HG:SetField("spellID", spell); HG:SetField("spellSearch", "") end
            end
        end)
    end

    local function questIDFromLogIndex(index)
        index = tonumber(index)
        if not index then return nil end
        if C_QuestLog and C_QuestLog.GetInfo then
            local info = C_QuestLog.GetInfo(index)
            if info and info.questID then return info.questID end
        end
        if C_QuestLog and C_QuestLog.GetQuestIDForLogIndex then
            return C_QuestLog.GetQuestIDForLogIndex(index)
        end
        if GetQuestLogTitle then return select(8, GetQuestLogTitle(index)) end
    end

    local function questIDFromButton(button)
        if not button then return nil end
        for _, key in ipairs({ "questID", "questId", "QuestID" }) do
            if tonumber(button[key]) then return tonumber(button[key]) end
        end
        if button.questInfo and tonumber(button.questInfo.questID) then return tonumber(button.questInfo.questID) end
        if button.info and tonumber(button.info.questID) then return tonumber(button.info.questID) end
        if button.questLogIndex then return questIDFromLogIndex(button.questLogIndex) end
        if button.GetID then
            local index = button:GetID()
            if button.type == "Available" and GetAvailableQuestInfo then
                local values = { GetAvailableQuestInfo(index) }
                return tonumber(values[5]) or tonumber(values[#values])
            elseif button.type == "Active" and GetActiveQuestID then
                return GetActiveQuestID(index)
            elseif not button.type then
                return questIDFromLogIndex(index)
            end
        end
    end

    local function questTitleWithID(text, id)
        if not text or text == "" or not id or text:find("%[ID:%s*%d+%]") then return text end
        return text .. " |cffd59b32[ID: " .. id .. "]|r"
    end

    local function decorateQuestButton(button)
        local id = questIDFromButton(button)
        if not id then return end
        if not button.HavenGMQuestID then
            local badge = button:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            badge:SetPoint("RIGHT", button, "RIGHT", -6, 0)
            badge:SetJustifyH("RIGHT")
            badge:SetTextColor(0.95, 0.68, 0.16)
            button.HavenGMQuestID = badge
            HG.questIDBadges = HG.questIDBadges or {}
            HG.questIDBadges[#HG.questIDBadges + 1] = badge
        end
        button.HavenGMQuestID:SetText("[" .. id .. "]")
        button.HavenGMQuestID:Show()
    end

    local function decorateVisibleQuestNames()
        if HG.db.settings.showQuestIDs == false then
            for _, badge in ipairs(HG.questIDBadges or {}) do badge:Hide() end
            return
        end

        -- NPC quest greeting / gossip lists.
        for index = 1, 64 do
            decorateQuestButton(_G["QuestTitleButton" .. index])
            decorateQuestButton(_G["QuestLogTitle" .. index])
            decorateQuestButton(_G["QuestLogTitleButton" .. index])
            decorateQuestButton(_G["GossipTitleButton" .. index])
        end

        -- BFA map quest-log buttons.
        local titles = _G.QuestMapFrame and QuestMapFrame.QuestsFrame
            and QuestMapFrame.QuestsFrame.Contents and QuestMapFrame.QuestsFrame.Contents.Titles
        if titles then
            for _, button in pairs(titles) do decorateQuestButton(button) end
        end

        -- The objective tracker is deliberately excluded because its narrow
        -- headers overlap when IDs are appended at common UI scales.
    end
    HG.RefreshQuestIDs = decorateVisibleQuestNames

    local installed = {}
    local function install(name, callback)
        if not installed[name] and type(_G[name]) == "function" then
            hooksecurefunc(name, callback)
            installed[name] = true
        end
    end
    local function installQuestHooks()
        for _, name in ipairs({
            "QuestMapLogTitleButton_OnClick", "QuestLogTitleButton_OnClick",
            "QuestTitleButton_OnClick", "GossipTitleButton_OnClick",
        }) do
            install(name, function(button, mouseButton)
                if HG.db.settings.captureIDs ~= false and mouseButton == "RightButton" and IsControlKeyDown() then
                    local id = questIDFromButton(button)
                    if id then HG:SetField("questID", id); HG:Notify("Selected quest ID: " .. id) end
                end
            end)
        end
        for _, name in ipairs({
            "QuestMapLogTitleButton_OnEnter", "QuestLogTitleButton_OnEnter",
            "QuestTitleButton_OnEnter", "GossipTitleButton_OnEnter",
        }) do
            install(name, function(button)
                local id = questIDFromButton(button)
                if id and HG.db.settings.showQuestIDs ~= false then
                    GameTooltip:AddLine("Quest ID: " .. id, 0.83, 0.61, 0.20)
                    GameTooltip:Show()
                end
            end)
        end
        for _, name in ipairs({
            "QuestMapFrame_UpdateAll", "QuestMapFrame_UpdateQuestDetails",
            "QuestLogQuests_Update", "QuestFrameGreetingPanel_OnShow",
            "GossipFrameUpdate", "ObjectiveTracker_Update",
        }) do
            install(name, function() C_Timer.After(0, decorateVisibleQuestNames) end)
        end
    end
    installQuestHooks()

    local questEvents = CreateFrame("Frame")
    questEvents:RegisterEvent("GOSSIP_SHOW")
    questEvents:RegisterEvent("QUEST_GREETING")
    questEvents:RegisterEvent("QUEST_DETAIL")
    questEvents:RegisterEvent("QUEST_PROGRESS")
    questEvents:RegisterEvent("QUEST_COMPLETE")
    questEvents:RegisterEvent("QUEST_LOG_UPDATE")
    questEvents:SetScript("OnEvent", function(_, event)
        installQuestHooks()
        C_Timer.After(0, decorateVisibleQuestNames)
        if event == "QUEST_DETAIL" or event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" then
            C_Timer.After(0, function()
                local id = GetQuestID and GetQuestID()
                if not id or id <= 0 then return end
                for _, fontString in ipairs({
                    _G.QuestInfoTitleHeader, _G.QuestProgressTitleText, _G.QuestRewardTitleText,
                }) do
                    if fontString and fontString.GetText and fontString.SetText then
                        local text = fontString:GetText()
                        fontString:SetText(questTitleWithID(fontString:GetText(), id))
                    end
                end
            end)
        end
    end)

    SLASH_HAVENGM1 = "/hgm"
    SlashCmdList.HAVENGM = function(message)
        message = strtrim(message or ""):lower()
        if message == "reset" then
            HG.db.position = nil
            HG.frame:ClearAllPoints()
            HG.frame:SetPoint("CENTER")
        else
            HG.frame:SetShown(not HG.frame:IsShown())
        end
    end
    SLASH_HAVENINSTANTKILL1 = "/instantkill"
    SlashCmdList.HAVENINSTANTKILL = function() HG:Execute("kill") end
    SLASH_HAVENCHEATS1 = "/hcheats"
    SLASH_HAVENCHEATS2 = "/hdebug"
    SlashCmdList.HAVENCHEATS = function() if HG.cheatsButton then HG.cheatsButton:Click() end end
    SLASH_HAVENGOD1 = "/hgod"
    SlashCmdList.HAVENGOD = function() if HG.runtimeButtons.god then HG.runtimeButtons.god:Click() end end
    SLASH_HAVENFLY1 = "/hfly"
    SlashCmdList.HAVENFLY = function() if HG.runtimeButtons.fly then HG.runtimeButtons.fly:Click() end end
    SLASH_HAVENSPEED1 = "/hspeed"
    SlashCmdList.HAVENSPEED = function(message)
        local value = tonumber(strtrim(message or ""))
        if not value or value < 1 or value > 20 then HG:Notify("Usage: /hspeed 1-20") return end
        value = math.floor(value)
        HG:SetField("speed", value)
        HG:Execute("speed", value)
    end
    SLASH_HAVENLEVEL1 = "/hlevel"
    SlashCmdList.HAVENLEVEL = function(message)
        local desired = tonumber(strtrim(message or ""))
        if not desired or desired < 1 or desired > 120 then HG:Notify("Usage: /hlevel 1-120") return end
        desired = math.floor(desired)
        HG:SetField("level", desired)
        local difference = desired - UnitLevel("player")
        if difference ~= 0 then HG:Execute("level", difference) end
    end
end
