local _, HG = ...

HG.followers = {}
HG.followerOrder = {}
HG.maxFollowers = 8
local FOLLOWER_FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local function creatureEntry(guid)
    if not guid then return nil end
    local kind, _, _, _, _, entry = strsplit("-", guid)
    if kind == "Creature" or kind == "Vehicle" then return tonumber(entry) end
end

function HG:IsTargetFollower()
    local guid = UnitGUID("target")
    return guid and self.followers[guid] ~= nil
end

function HG:FollowerCount()
    local count = 0
    for _, follower in pairs(self.followers) do
        if follower then count = count + 1 end
    end
    return count
end

function HG:RefreshFollowerButton()
    local button = self.followButton
    if not button then return end
    local following = self:IsTargetFollower()
    button.label:SetText(following and "FOLLOW ON" or "FOLLOW OFF")
    button:SetRestingColor(following and self.colors.on or self.colors.off)
end

function HG:RefreshFactionButton()
    local button = self.factionButton
    if not button then return end
    if self:IsPossessing() then
        button:Disable()
        button.label:SetText("POSSESSED")
        button:SetRestingColor(self.colors.off)
        return
    end
    button:Enable()
    local guid = UnitGUID("target")
    if not guid or not creatureEntry(guid) then
        button.label:SetText("NO NPC")
        button:SetRestingColor(self.colors.off)
        return
    end
    local friendly = self.db.factionModes[guid]
    if friendly == nil then friendly = not UnitCanAttack("player", "target") end
    button.label:SetText(friendly and "FRIENDLY" or "HOSTILE")
    button:SetRestingColor(friendly and self.colors.on or self.colors.off)
end

function HG:ToggleTargetFaction()
    if self:IsPossessing() then
        self:Notify("Release possession before changing faction.")
        return
    end
    local guid = UnitGUID("target")
    if not guid or not creatureEntry(guid) then self:Notify("Select an NPC target first.") return end
    local friendly = self.db.factionModes[guid]
    if friendly == nil then friendly = not UnitCanAttack("player", "target") end
    friendly = not friendly
    if self:Execute("modifyFaction", friendly and 35 or 14) then
        self.db.factionModes[guid] = friendly
        self:RefreshFactionButton()
    end
end

function HG:RefreshFollowerIcons()
    local visible = 0
    local seen = {}
    local compactOrder = {}
    for _, guid in ipairs(self.followerOrder) do
        local follower = self.followers[guid]
        if follower and not seen[guid] then
            seen[guid] = true
            compactOrder[#compactOrder + 1] = guid
            visible = visible + 1
            follower.button:ClearAllPoints()
            follower.button:SetPoint("TOPLEFT", self.frame, "TOPRIGHT", 4, -8 - ((visible - 1) * 52))
            follower.button:Show()
        end
    end
    self.followerOrder = compactOrder
end

function HG:RemoveFollower(guid)
    local follower = self.followers[guid]
    if not follower then return end
    follower.button:Hide()
    self.followers[guid] = nil
    if self.db and self.db.followers then self.db.followers[guid] = nil end
    local compactOrder = {}
    for _, orderedGuid in ipairs(self.followerOrder) do
        if orderedGuid ~= guid then
            compactOrder[#compactOrder + 1] = orderedGuid
        end
    end
    self.followerOrder = compactOrder
    self:RefreshFollowerIcons()
    self:RefreshFollowerButton()
    self:RefreshFactionButton()
end

function HG:CreateFollower(guid, entry, name, useTargetPortrait)
    if not guid or not entry or self.followers[guid] then return self.followers[guid] ~= nil end
    if self:FollowerCount() >= self.maxFollowers then
        self:Notify("Follower list is full (8/8). Dismiss one before adding another.")
        return false
    end
    local button = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
    button:SetSize(48, 48)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(38, 38)
    icon:SetPoint("CENTER")
    icon:SetTexture(FOLLOWER_FALLBACK_ICON)
    if useTargetPortrait and UnitGUID("target") == guid then
        SetPortraitTexture(icon, "target")
    end
    button:SetHighlightTexture(nil)
    button:SetAttribute("type1", "macro")
    button:SetAttribute("macrotext1", "/targetexact " .. name)
    button:SetAttribute("type2", "macro")
    button:SetAttribute("macrotext2", "/targetexact " .. name)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(name)
        GameTooltip:AddLine("NPC ID: " .. entry, 0.20, 0.85, 1)
        GameTooltip:AddLine("Following you", 0.25, 1, 0.35)
        GameTooltip:AddLine("Left-click to target and load NPC ID.", 1, 1, 1)
        GameTooltip:AddLine("Right-click to dismiss, even if dead or missing.", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("PostClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            if UnitGUID("target") == guid then
                SetPortraitTexture(icon, "target")
                HG:SetField("creatorEntry", entry)
                HG:RefreshFollowerButton()
            else
                HG:Notify("Could not safely target " .. name .. ".")
            end
            return
        end
        if mouseButton ~= "RightButton" then return end
        if UnitGUID("target") == guid then
            HG:Execute("npcFollowStop")
        end
        HG:RemoveFollower(guid)
        HG:Notify("Follower removed: " .. name)
    end)

    self.followers[guid] = {
        guid = guid, entry = entry, name = name, button = button,
    }
    self.db.followers = self.db.followers or {}
    self.db.followers[guid] = {
        guid = guid, entry = entry, name = name,
    }
    -- A previously dismissed follower may still exist in an older in-memory
    -- order list. Remove every stale occurrence before appending it once.
    local compactOrder = {}
    for _, orderedGuid in ipairs(self.followerOrder) do
        if orderedGuid ~= guid and self.followers[orderedGuid] then
            compactOrder[#compactOrder + 1] = orderedGuid
        end
    end
    self.followerOrder = compactOrder
    self.followerOrder[#self.followerOrder + 1] = guid
    self:RefreshFollowerIcons()
    return true
end

function HG:AddTargetFollower()
    local guid = UnitGUID("target")
    local entry = creatureEntry(guid)
    if not guid or not entry then self:Notify("Select an NPC target first.") return false end
    return self:CreateFollower(guid, entry, UnitName("target") or ("NPC " .. entry), true)
end

function HG:RestoreFollowers()
    self.followers = {}
    self.followerOrder = {}
    local saved = {}
    for guid, record in pairs(self.db.followers or {}) do
        saved[#saved + 1] = { guid = guid, record = record }
    end
    self.db.followers = {}
    for index, item in ipairs(saved) do
        if index > self.maxFollowers then break end
        local record = item.record
        self:CreateFollower(item.guid, tonumber(record.entry), record.name or "Follower", false)
    end
    self:RefreshFollowerIcons()
end

function HG:ClearFollowers()
    for _, follower in pairs(self.followers) do
        if follower.button then follower.button:Hide() end
    end
    self.followers = {}
    self.followerOrder = {}
    self.db.followers = {}
    self:RefreshFollowerButton()
end

function HG:ToggleTargetFollower()
    local guid = UnitGUID("target")
    if not guid or not creatureEntry(guid) then self:Notify("Select an NPC target first.") return end
    if self.followers[guid] then
        if self:Execute("npcFollowStop") then self:RemoveFollower(guid) end
    elseif self:FollowerCount() >= self.maxFollowers then
        self:Notify("Follower list is full (8/8). Dismiss one before adding another.")
    elseif self:Execute("npcFollow") then
        self:AddTargetFollower()
    end
    self:RefreshFollowerButton()
end
