local ADDON_NAME, HG = ...

HG.name = ADDON_NAME
HG.version = "1.0.0"
HG.prefix = "|cffd59b32HavenGM:|r "
HG.tabs = {}
HG.tabByKey = {}
HG.fields = {}
HG.runtimeButtons = {}
HG.pairButtons = {}

HG.colors = {
    panel = { 0.015, 0.025, 0.04, 0.98 },
    inset = { 0.025, 0.045, 0.07, 0.96 },
    gold = { 0.45, 0.24, 0.03, 1 },
    goldHover = { 0.65, 0.38, 0.05, 1 },
    on = { 0.06, 0.42, 0.13, 1 },
    onHover = { 0.08, 0.58, 0.18, 1 },
    off = { 0.48, 0.06, 0.06, 1 },
    offHover = { 0.67, 0.08, 0.08, 1 },
    questPrevious = { 0.25, 0.07, 0.07, 1 },
    questPreviousHover = { 0.38, 0.11, 0.10, 1 },
    questNext = { 0.04, 0.24, 0.11, 1 },
    questNextHover = { 0.07, 0.37, 0.17, 1 },
}

function HG:Notify(text)
    DEFAULT_CHAT_FRAME:AddMessage(self.prefix .. tostring(text))
end

function HG:RegisterTab(key, title, order, build)
    local definition = { key = key, title = title, order = order, build = build }
    self.tabs[#self.tabs + 1] = definition
    self.tabByKey[key] = definition
end

StaticPopupDialogs.HAVENGM_CONFIRM = {
    text = "%s",
    button1 = YES,
    button2 = NO,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnAccept = function(self)
        if self.data and self.data.callback then self.data.callback() end
    end,
}

StaticPopupDialogs.HAVENGM_DISCORD = {
    text = "WoW Haven Discord",
    button1 = CLOSE,
    hasEditBox = true,
    editBoxWidth = 280,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(self)
        self.editBox:SetText("https://discord.gg/NpAbZfpwn5")
        self.editBox:SetFocus()
        self.editBox:HighlightText()
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    EditBoxOnEnterPressed = function(self)
        self:HighlightText()
    end,
}

function HG:Confirm(title, command, callback)
    if self.db and self.db.settings.confirmDangerous == false then
        callback()
        return
    end
    StaticPopup_Show(
        "HAVENGM_CONFIRM",
        title .. "\n\n|cffd59b32" .. command .. "|r",
        nil,
        { callback = callback }
    )
end

function HG:SetField(key, value)
    local field = self.fields[key]
    if field then
        field:SetText(tostring(value or ""))
    end
end

function HG:GetPositiveInteger(key, label, maximum)
    local field = self.fields[key]
    local value = field and tonumber(field:GetText())
    if not value or value < 1 or (maximum and value > maximum) then
        self:Notify("Enter a valid " .. label .. ".")
        if field then field:SetFocus() end
        return nil
    end
    return math.floor(value)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("UPDATE_POSSESS_BAR")
events:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" and (...) == ADDON_NAME then
        HavenGMDB = HavenGMDB or {}
        HavenGMDB.schema = tonumber(HavenGMDB.schema) or 1
        HavenGMDB.position = HavenGMDB.position
        HavenGMDB.lastTab = HavenGMDB.lastTab or "general"
        HavenGMDB.toggles = HavenGMDB.toggles or {}
        HavenGMDB.inputs = HavenGMDB.inputs or {}
        HavenGMDB.settings = HavenGMDB.settings or {}
        if HavenGMDB.settings.showMinimap == nil then HavenGMDB.settings.showMinimap = true end
        if HavenGMDB.settings.echoCommands == nil then HavenGMDB.settings.echoCommands = false end
        if HavenGMDB.settings.showItemIDs == nil then HavenGMDB.settings.showItemIDs = HavenGMDB.settings.tooltipIDs ~= false end
        if HavenGMDB.settings.showNPCIDs == nil then HavenGMDB.settings.showNPCIDs = HavenGMDB.settings.tooltipIDs ~= false end
        if HavenGMDB.settings.showQuestIDs == nil then HavenGMDB.settings.showQuestIDs = HavenGMDB.settings.tooltipIDs ~= false end
        if HavenGMDB.settings.showObjectIDs == nil then HavenGMDB.settings.showObjectIDs = true end
        if HavenGMDB.settings.captureIDs == nil then HavenGMDB.settings.captureIDs = HavenGMDB.settings.captureItemIDs ~= false end
        if HavenGMDB.settings.autoTargetIDs == nil then HavenGMDB.settings.autoTargetIDs = true end
        if HavenGMDB.settings.confirmDangerous == nil then HavenGMDB.settings.confirmDangerous = true end
        if HavenGMDB.settings.lockFrame == nil then HavenGMDB.settings.lockFrame = false end
        HavenGMDB.settings.scale = tonumber(HavenGMDB.settings.scale) or 1
        HavenGMDB.teleportFavorites = HavenGMDB.teleportFavorites or {}
        HavenGMDB.teleportRecent = HavenGMDB.teleportRecent or {}
        HavenGMDB.creatorToggles = HavenGMDB.creatorToggles or {}
        HavenGMDB.followers = HavenGMDB.followers or {}
        HavenGMDB.factionModes = HavenGMDB.factionModes or {}
        HavenGMDB.cheatsEnabled = false
        for _, key in ipairs({ "god", "cast", "cooldown", "power", "fly" }) do
            HavenGMDB.toggles[key] = false
        end
        HavenGMDB.creatorToggles.possess = false
        HG.db = HavenGMDB
        HG:BuildUI()
        HG:InstallIntegrations()
        HG:Notify("v" .. HG.version .. " loaded. Type /hgm to show or hide.")
    elseif event == "PLAYER_ENTERING_WORLD" and HG.db then
        local isInitialLogin, isReloadingUI = ...
        -- This event explicitly distinguishes a fresh login from /reload.
        -- Preserve server-side follower controls across reloads, but discard
        -- stale controls when a new game session actually begins.
        if isInitialLogin then
            HG:ClearFollowers()
            HG.db.factionModes = {}
            HG:RefreshRuntimeButtons()
        elseif isReloadingUI then
            HG:RestoreFollowers()
        end
        HG:SyncPossessState()
    elseif event == "UPDATE_POSSESS_BAR" and HG.db then
        HG:SyncPossessState()
    end
end)
