local ADDON_NAME, HG = ...

HG.name = ADDON_NAME
HG.version = "0.3.4-beta"
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
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == ADDON_NAME then
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
        HG.db = HavenGMDB
        HG:BuildUI()
        HG:RestoreFollowers()
        HG:InstallIntegrations()
        HG:Notify("v" .. HG.version .. " loaded. Type /hgm to show or hide.")
    elseif event == "PLAYER_LOGIN" and HG.db then
        -- Runtime flags cannot be queried reliably. A real login therefore
        -- starts with neutral local indicators without sending any commands.
        if type(IsInitialLogin) == "function" and IsInitialLogin() then
            HG:ClearFollowers()
            HG.db.factionModes = {}
            HG.db.cheatsEnabled = false
            for _, key in ipairs({ "god", "cast", "cooldown", "power", "fly" }) do
                HG.db.toggles[key] = false
            end
            for _, key in ipairs({ "follow", "possess" }) do
                HG.db.creatorToggles[key] = false
            end
            HG:RefreshRuntimeButtons()
        end
    end
end)
