local ADDON_NAME = ...
local PREFIX = "|cffd59b32Haven GM:|r "

local COLORS = {
    gold = { 0.45, 0.24, 0.03, 1 },
    goldHover = { 0.65, 0.38, 0.05, 1 },
    on = { 0.06, 0.42, 0.13, 1 },
    onHover = { 0.08, 0.58, 0.18, 1 },
    off = { 0.48, 0.06, 0.06, 1 },
    offHover = { 0.67, 0.08, 0.08, 1 },
}

local function Notify(text)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. text)
end

local function Run(command)
    if command and command ~= "" then
        SendChatMessage(command, "SAY")
        Notify(command)
    end
end

local function RunMany(commands)
    for _, command in ipairs(commands) do
        Run(command)
    end
end

local function PositiveNumber(editBox, label)
    local value = tonumber(editBox:GetText())
    if not value or value < 1 then
        Notify("Enter a valid " .. label .. ".")
        editBox:SetFocus()
        return nil
    end
    return math.floor(value)
end

local frame = CreateFrame("Frame", "HavenGMFrame", UIParent)
frame:SetSize(620, 332)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 190)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint()
    HavenGMDB.position = { point, relativePoint, x, y }
end)
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 24,
    edgeSize = 24,
    insets = { left = 7, right = 7, top = 7, bottom = 7 },
})

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -15)
title:SetText("GM TOOLKIT")

local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -5, -5)

local function Paint(button, color)
    button:SetBackdropColor(unpack(color))
end

local function BaseButton(text, x, y, width, callback, tooltip)
    local button = CreateFrame("Button", nil, frame)
    button:SetSize(width, 26)
    button:SetPoint("TOPLEFT", x, y)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    button:SetBackdropBorderColor(0.85, 0.58, 0.12, 1)

    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER", 0, 0)
    label:SetText(text)
    button.label = label
    button:SetScript("OnClick", callback)

    if tooltip then
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.label:GetText())
            GameTooltip:AddLine(tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", GameTooltip_Hide)
    end
    return button
end

local function ActionButton(text, x, y, width, callback, tooltip)
    local button = BaseButton(text, x, y, width, callback, tooltip)
    Paint(button, COLORS.gold)
    local previousEnter = button:GetScript("OnEnter")
    local previousLeave = button:GetScript("OnLeave")
    button:SetScript("OnEnter", function(self)
        Paint(self, COLORS.goldHover)
        if previousEnter then previousEnter(self) end
    end)
    button:SetScript("OnLeave", function(self)
        Paint(self, COLORS.gold)
        if previousLeave then previousLeave(self) end
    end)
    return button
end

local toggles = {}

local function ToggleButton(key, text, x, y, width, commandRoot, tooltip)
    local button
    button = BaseButton(text, x, y, width, function()
        local enabled = not HavenGMDB.toggles[key]
        HavenGMDB.toggles[key] = enabled
        Run(commandRoot .. (enabled and " on" or " off"))
        button:Refresh()
    end, tooltip)

    function button:Refresh()
        local enabled = HavenGMDB.toggles[key] == true
        self.label:SetText(text .. (enabled and "  ON" or "  OFF"))
        Paint(self, enabled and COLORS.on or COLORS.off)
    end

    local previousEnter = button:GetScript("OnEnter")
    local previousLeave = button:GetScript("OnLeave")
    button:SetScript("OnEnter", function(self)
        local enabled = HavenGMDB.toggles[key] == true
        Paint(self, enabled and COLORS.onHover or COLORS.offHover)
        if previousEnter then previousEnter(self) end
    end)
    button:SetScript("OnLeave", function(self)
        self:Refresh()
        if previousLeave then previousLeave(self) end
    end)
    toggles[key] = button
    return button
end

local function EditBox(x, y, initial)
    local edit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    edit:SetSize(78, 24)
    edit:SetPoint("TOPLEFT", x, y)
    edit:SetAutoFocus(false)
    edit:SetNumeric(true)
    edit:SetMaxLetters(10)
    edit:SetText(initial or "")
    edit:SetJustifyH("CENTER")
    edit:SetScript("OnEscapePressed", edit.ClearFocus)
    edit:SetScript("OnEnterPressed", edit.ClearFocus)
    return edit
end

local function TextEditBox(x, y, initial)
    local edit = EditBox(x, y, initial)
    edit:SetNumeric(false)
    edit:SetMaxLetters(40)
    return edit
end

local function StepButton(text, x, y, edit, delta, minimum, maximum, onChanged)
    return ActionButton(text, x, y, 26, function()
        local value = tonumber(edit:GetText()) or minimum
        value = math.max(minimum, math.min(maximum, math.floor(value + delta)))
        edit:SetText(value)
        if onChanged then onChanged(value) end
    end)
end

local allButton
allButton = BaseButton("ALL", 16, -44, 102, function()
    local enable = not HavenGMDB.debugAll
    HavenGMDB.debugAll = enable
    for _, key in ipairs({ "god", "cast", "cooldown", "power" }) do
        HavenGMDB.toggles[key] = enable
        toggles[key]:Refresh()
    end
    RunMany({
        ".gm " .. (enable and "on" or "off"),
        ".cheat god " .. (enable and "on" or "off"),
        ".cheat casttime " .. (enable and "on" or "off"),
        ".cheat cooldown " .. (enable and "on" or "off"),
        ".cheat power " .. (enable and "on" or "off"),
    })
    allButton:Refresh()
end, "Toggles GM mode, God, instant casting, no cooldowns and free resources.")

function allButton:Refresh()
    local enabled = HavenGMDB.debugAll == true
    self.label:SetText("ALL  " .. (enabled and "ON" or "OFF"))
    Paint(self, enabled and COLORS.on or COLORS.off)
end

ToggleButton("god", "GOD", 124, -44, 88, ".cheat god", "Prevents incoming damage.")
ToggleButton("cast", "CAST", 218, -44, 88, ".cheat casttime", "Removes spell cast time.")
ToggleButton("cooldown", "CD", 312, -44, 88, ".cheat cooldown", "Removes spell cooldowns.")
ToggleButton("power", "POWER", 406, -44, 96, ".cheat power", "Removes mana, rage and energy costs.")
ToggleButton("fly", "FLY", 508, -44, 96, ".gm fly", "Enables or disables GM flight.")

local function SetRuntimeTogglesOff()
    HavenGMDB.debugAll = false
    for _, key in ipairs({ "god", "cast", "cooldown", "power", "fly" }) do
        HavenGMDB.toggles[key] = false
    end

    allButton:Refresh()
    for _, button in pairs(toggles) do
        button:Refresh()
    end
end

local killButton = ActionButton("KILL TARGET", 16, -78, 108, function()
    Run(".die")
end, "Kills the selected unit through HavenCore.")

local damage80Button = ActionButton("-80% HP", 130, -78, 88, function()
    if not UnitExists("target") or UnitIsDead("target") then
        Notify("Select a living target first.")
        return
    end
    local damage = math.max(1, math.floor(UnitHealth("target") * 0.80))
    Run(".damage " .. damage)
end, "Removes 80% of the selected target's current health without intentionally killing it.")

local speedLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
speedLabel:SetPoint("TOPLEFT", 236, -85)
speedLabel:SetText("Speed")
local speed = EditBox(282, -79, "3")
StepButton("-", 366, -79, speed, -1, 1, 20, function(value)
    Run(".modify speed all " .. value)
end)
StepButton("+", 398, -79, speed, 1, 1, 20, function(value)
    Run(".modify speed all " .. value)
end)
ActionButton("RESET SPEED", 432, -79, 112, function()
    speed:SetText("1")
    Run(".modify speed all 1")
end)

local questLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
questLabel:SetPoint("TOPLEFT", 18, -124)
questLabel:SetText("Quest ID")
local questID = EditBox(82, -117, "")

ActionButton("ADD", 168, -117, 58, function()
    local id = PositiveNumber(questID, "quest ID")
    if id then Run(".quest add " .. id) end
end)
ActionButton("COMPLETE", 232, -117, 86, function()
    local id = PositiveNumber(questID, "quest ID")
    if id then Run(".quest complete " .. id) end
end)
ActionButton("REMOVE", 324, -117, 76, function()
    local id = PositiveNumber(questID, "quest ID")
    if id then Run(".quest remove " .. id) end
end)
ActionButton("GO TO", 406, -117, 68, function()
    local id = PositiveNumber(questID, "quest ID")
    if id then Run(".go quest " .. id) end
end)
ActionButton("USE LOG ID", 480, -117, 124, function()
    local selected = C_QuestLog and C_QuestLog.GetSelectedQuest and C_QuestLog.GetSelectedQuest()
    if selected and selected > 0 then
        questID:SetText(selected)
        Notify("Selected quest ID: " .. selected)
    else
        Notify("Select a quest in the quest log first.")
    end
end)

local itemLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
itemLabel:SetPoint("TOPLEFT", 18, -163)
itemLabel:SetText("Item ID")
local itemID = EditBox(82, -156, "")

local qtyLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
qtyLabel:SetPoint("TOPLEFT", 162, -163)
qtyLabel:SetText("Qty")
local itemCount = EditBox(190, -156, "1")
StepButton("-", 274, -156, itemCount, -1, 1, 999)
StepButton("+", 306, -156, itemCount, 1, 1, 999)

ActionButton("ADD ITEM", 340, -156, 82, function()
    local id = PositiveNumber(itemID, "item ID")
    local count = PositiveNumber(itemCount, "quantity")
    if id and count then Run(".additem " .. id .. " " .. count) end
end)
ActionButton("REMOVE", 428, -156, 78, function()
    local id = PositiveNumber(itemID, "item ID")
    local count = PositiveNumber(itemCount, "quantity")
    if id and count then Run(".additem " .. id .. " -" .. count) end
end)
ActionButton("LOOKUP", 512, -156, 92, function()
    local id = PositiveNumber(itemID, "item ID")
    if id then Run(".lookup item " .. id) end
end)

local teleportAreas = {
    {
        world = "AZEROTH",
        name = "Broken Isles",
        destinations = {
            { text = "Dalaran (Legion)", command = "dalaranlegion" },
        },
    },
    {
        world = "AZEROTH",
        name = "Eastern Kingdoms",
        destinations = {
            { text = "Stormwind", command = "Stormwind" },
            { text = "Ironforge", command = "Ironforge" },
            { text = "Undercity", command = "Undercity" },
            { text = "Silvermoon City", command = "SilvermoonCity" },
            { text = "Booty Bay", command = "BootyBay" },
        },
    },
    {
        world = "AZEROTH",
        name = "Kalimdor",
        destinations = {
            { text = "Orgrimmar", command = "Orgrimmar" },
            { text = "Darnassus", command = "Darnassus" },
            { text = "The Exodar", command = "TheExodar" },
            { text = "Thunder Bluff", command = "ThunderBluff" },
            { text = "Gadgetzan", command = "Gadgetzan" },
        },
    },
    {
        world = "AZEROTH",
        name = "Kul Tiras",
        destinations = {
            { text = "Boralus", command = "Boralus" },
            { text = "Tiragarde Sound", command = "tiragardesoundsouth" },
            { text = "Drustvar", command = "drustvar" },
            { text = "Stormsong Valley", command = "stormsongvalley" },
            { text = "Freehold", command = "FreeholdTiragardeSound" },
        },
    },
    {
        world = "AZEROTH",
        name = "Nazjatar",
        destinations = {
            { text = "Nazjatar", command = "Nazjatar" },
        },
    },
    {
        world = "AZEROTH",
        name = "Northrend",
        destinations = {
            { text = "Dalaran", command = "Dalaran" },
        },
    },
    {
        world = "AZEROTH",
        name = "Pandaria",
        destinations = {
            { text = "Pandaria", command = "Pandaria" },
            { text = "The Jade Forest", command = "TheJadeForest" },
            { text = "Shrine of Seven Stars", command = "ShrineOfSevenStars" },
            { text = "Shrine of Two Moons", command = "ShrineOfTwoMoons" },
        },
    },
    {
        world = "AZEROTH",
        name = "The Maelstrom",
        destinations = {
            { text = "The Maelstrom", command = "TheMaelstrom" },
            { text = "Deepholm", command = "Deepholm" },
        },
    },
    {
        world = "AZEROTH",
        name = "Zandalar",
        destinations = {
            { text = "Dazar'alor", command = "Dazaralor" },
            { text = "Zuldazar", command = "zuldazar" },
            { text = "Nazmir", command = "nazmir" },
        },
    },
    {
        world = "DRAENOR",
        name = "Draenor",
        destinations = {
            { text = "Stormshield", command = "Stormshield" },
            { text = "Frostfire Ridge", command = "DraenorFrostfireRidge" },
            { text = "Gorgrond", command = "DraenorGorgrond" },
            { text = "Nagrand", command = "DraenorNagrand" },
            { text = "Shadowmoon Valley", command = "DraenorShadowmoonValley" },
            { text = "Shattrath", command = "DraenorShattrath" },
            { text = "Spires of Arak", command = "DraenorSpiresOfArak" },
        },
    },
    {
        world = "OUTLAND",
        name = "Outland",
        destinations = {
            { text = "Shattrath", command = "Shattrath" },
        },
    },
}

local mountLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mountLabel:SetPoint("TOPLEFT", 18, -204)
mountLabel:SetText("Mount")
local mountName = TextEditBox(82, -195, "")
ActionButton("SEARCH", 168, -195, 72, function()
    local name = strtrim(mountName:GetText() or "")
    if name == "" then
        Notify("Enter a mount name.")
        mountName:SetFocus()
        return
    end
    Run(".lookup spell " .. name)
end, "Searches HavenCore spell names. Use the mount spell ID from the result.")

local mountIDLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mountIDLabel:SetPoint("TOPLEFT", 252, -204)
mountIDLabel:SetText("Spell ID")
local mountID = EditBox(306, -195, "")
ActionButton("LEARN", 392, -195, 72, function()
    local id = PositiveNumber(mountID, "mount spell ID")
    if id then Run(".learn " .. id) end
end)
ActionButton("UNLEARN", 470, -195, 88, function()
    local id = PositiveNumber(mountID, "mount spell ID")
    if id then Run(".unlearn " .. id) end
end)

local levelLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
levelLabel:SetPoint("TOPLEFT", 18, -244)
levelLabel:SetText("Level")
local levelValue = EditBox(82, -235, tostring(UnitLevel("player") or 1))
StepButton("-", 168, -235, levelValue, -1, 1, 120)
StepButton("+", 200, -235, levelValue, 1, 1, 120)

local function SetExactLevel()
    local desired = PositiveNumber(levelValue, "level")
    if not desired or desired > 120 then
        Notify("Level must be between 1 and 120.")
        return
    end

    local current = UnitLevel("player")
    local difference = desired - current
    if difference == 0 then
        Notify("You are already level " .. desired .. ".")
        return
    end
    Run(".levelup " .. difference)
end

ActionButton("SET LEVEL", 234, -235, 92, SetExactLevel, "Sets an exact level by applying the difference from your current level.")
ActionButton("CURRENT", 332, -235, 84, function()
    levelValue:SetText(UnitLevel("player"))
end, "Reads your current character level into the field.")

local teleportLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
teleportLabel:SetPoint("TOPLEFT", 18, -284)
teleportLabel:SetText("Teleport")

local selectedTeleportArea = teleportAreas[2]
local selectedTeleport = selectedTeleportArea.destinations[1]

local destinationDropDown = CreateFrame("Frame", "HavenGMTeleportDestinationDropDown", frame, "UIDropDownMenuTemplate")
destinationDropDown:SetPoint("TOPLEFT", 235, -276)
UIDropDownMenu_SetWidth(destinationDropDown, 115)

local function RefreshTeleportSelection()
    selectedTeleport = selectedTeleportArea.destinations[1]
    UIDropDownMenu_SetText(destinationDropDown, selectedTeleport.text)
end

local areaDropDown = CreateFrame("Frame", "HavenGMTeleportAreaDropDown", frame, "UIDropDownMenuTemplate")
areaDropDown:SetPoint("TOPLEFT", 72, -276)
UIDropDownMenu_SetWidth(areaDropDown, 115)
UIDropDownMenu_SetText(areaDropDown, selectedTeleportArea.name)
UIDropDownMenu_Initialize(areaDropDown, function(_, level)
    local previousWorld
    for _, area in ipairs(teleportAreas) do
        if area.world ~= previousWorld then
            local heading = UIDropDownMenu_CreateInfo()
            heading.text = area.world
            heading.isTitle = true
            heading.notCheckable = true
            UIDropDownMenu_AddButton(heading, level)
            previousWorld = area.world
        end

        local info = UIDropDownMenu_CreateInfo()
        info.text = area.name
        info.checked = area == selectedTeleportArea
        info.func = function()
            selectedTeleportArea = area
            UIDropDownMenu_SetText(areaDropDown, area.name)
            RefreshTeleportSelection()
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end)

UIDropDownMenu_SetText(destinationDropDown, selectedTeleport.text)
UIDropDownMenu_Initialize(destinationDropDown, function(_, level)
    for _, destination in ipairs(selectedTeleportArea.destinations) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = destination.text
        info.checked = destination == selectedTeleport
        info.func = function()
            selectedTeleport = destination
            UIDropDownMenu_SetText(destinationDropDown, destination.text)
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end)

ActionButton("TELEPORT", 398, -275, 88, function()
    Run(".tele " .. selectedTeleport.command)
end, "Teleports to the selected HavenCore game_tele destination.")

ActionButton("BACK", 492, -275, 72, function()
    Run(".recall")
end, "Returns to the position stored by the server before teleporting.")

SLASH_HAVENINSTANTKILL1 = "/instantkill"
SlashCmdList.HAVENINSTANTKILL = function()
    killButton:Click()
end

SLASH_HAVENDAMAGE801 = "/80kill"
SLASH_HAVENDAMAGE802 = "/80%kill"
SLASH_HAVENDAMAGE803 = "/damage80"
SlashCmdList.HAVENDAMAGE80 = function()
    damage80Button:Click()
end

SLASH_HAVENGOD1 = "/hgod"
SlashCmdList.HAVENGOD = function()
    toggles.god:Click()
end

SLASH_HAVENFLY1 = "/hfly"
SlashCmdList.HAVENFLY = function()
    toggles.fly:Click()
end

SLASH_HAVENDEBUG1 = "/hdebug"
SlashCmdList.HAVENDEBUG = function()
    allButton:Click()
end

SLASH_HAVENSPEED1 = "/hspeed"
SlashCmdList.HAVENSPEED = function(message)
    local value = tonumber(strtrim(message or ""))
    if not value or value < 1 or value > 20 then
        Notify("Usage: /hspeed 1-20")
        return
    end
    value = math.floor(value)
    speed:SetText(value)
    Run(".modify speed all " .. value)
end

SLASH_HAVENLEVEL1 = "/hlevel"
SlashCmdList.HAVENLEVEL = function(message)
    local value = tonumber(strtrim(message or ""))
    if not value or value < 1 or value > 120 then
        Notify("Usage: /hlevel 1-120")
        return
    end
    levelValue:SetText(math.floor(value))
    SetExactLevel()
end

SLASH_HAVENGM1 = "/hgm"
SlashCmdList.HAVENGM = function(message)
    message = strtrim(message or ""):lower()
    if message == "reset" then
        HavenGMDB.position = nil
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 190)
    else
        frame:SetShown(not frame:IsShown())
    end
end

local function AddItemID(tooltip)
    local _, link = tooltip:GetItem()
    local id = link and tonumber(link:match("item:(%d+)"))
    if id then
        tooltip:AddLine("Item ID: " .. id, 0.83, 0.61, 0.20)
        tooltip:Show()
    end
end

GameTooltip:HookScript("OnTooltipSetItem", AddItemID)
ItemRefTooltip:HookScript("OnTooltipSetItem", AddItemID)

if ContainerFrameItemButton_OnModifiedClick then
    hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(self, button)
        if button ~= "RightButton" or not IsShiftKeyDown() then
            return
        end
        local bag = self:GetParent() and self:GetParent():GetID()
        local link = bag and GetContainerItemLink(bag, self:GetID())
        local id = link and tonumber(link:match("item:(%d+)"))
        if id then
            itemID:SetText(id)
        end
    end)
end

local function SetQuestID(id, source)
    id = tonumber(id)
    if not id or id <= 0 then
        return false
    end
    questID:SetText(id)
    if source then
        Notify(source .. " quest ID: " .. id)
    end
    return true
end

local function QuestIDFromLogIndex(index)
    index = tonumber(index)
    if not index then
        return nil
    end
    if C_QuestLog and C_QuestLog.GetInfo then
        local info = C_QuestLog.GetInfo(index)
        if info and info.questID then
            return info.questID
        end
    end
    if C_QuestLog and C_QuestLog.GetQuestIDForLogIndex then
        return C_QuestLog.GetQuestIDForLogIndex(index)
    end
    if GetQuestLogTitle then
        return select(8, GetQuestLogTitle(index))
    end
end

local function QuestIDFromButton(button)
    if not button then
        return nil
    end
    for _, key in ipairs({ "questID", "questId", "QuestID" }) do
        if tonumber(button[key]) then
            return tonumber(button[key])
        end
    end
    if button.questLogIndex then
        return QuestIDFromLogIndex(button.questLogIndex)
    end
    if button.GetID then
        local index = button:GetID()
        if button.type == "Available" and GetAvailableQuestInfo then
            local values = { GetAvailableQuestInfo(index) }
            return tonumber(values[5]) or tonumber(values[#values])
        elseif button.type == "Active" and GetActiveQuestID then
            return GetActiveQuestID(index)
        elseif not button.type then
            return QuestIDFromLogIndex(index)
        end
    end
end

local function CaptureQuestButton(button)
    if IsShiftKeyDown() then
        SetQuestID(QuestIDFromButton(button), "Selected")
    end
end

local function AddQuestLine(tooltip, id)
    id = tonumber(id)
    if id and id > 0 then
        tooltip:AddLine("Quest ID: " .. id, 0.83, 0.61, 0.20)
        tooltip:Show()
    end
end

local function AddQuestLinkID(tooltip, link)
    local id = link and tonumber(link:match("quest:(%d+)"))
    if id then
        AddQuestLine(tooltip, id)
    end
end

hooksecurefunc(GameTooltip, "SetHyperlink", AddQuestLinkID)
hooksecurefunc(ItemRefTooltip, "SetHyperlink", AddQuestLinkID)

if HandleModifiedItemClick then
    hooksecurefunc("HandleModifiedItemClick", function(link)
        if IsShiftKeyDown() then
            local id = link and tonumber(link:match("quest:(%d+)"))
            if id then
                SetQuestID(id, "Linked")
            end
        end
    end)
end

local installedQuestHooks = {}
local function InstallQuestHook(name, callback)
    if not installedQuestHooks[name] and type(_G[name]) == "function" then
        hooksecurefunc(name, callback)
        installedQuestHooks[name] = true
    end
end

local function InstallQuestHooks()
    for _, name in ipairs({
        "QuestMapLogTitleButton_OnClick",
        "QuestLogTitleButton_OnClick",
        "QuestTitleButton_OnClick",
        "GossipTitleButton_OnClick",
    }) do
        InstallQuestHook(name, CaptureQuestButton)
    end

    for _, name in ipairs({
        "QuestMapLogTitleButton_OnEnter",
        "QuestLogTitleButton_OnEnter",
        "QuestTitleButton_OnEnter",
        "GossipTitleButton_OnEnter",
    }) do
        InstallQuestHook(name, function(button)
            AddQuestLine(GameTooltip, QuestIDFromButton(button))
        end)
    end
end

local function AddIDToQuestTitle(fontString, id)
    if not fontString or not fontString.GetText or not fontString.SetText then
        return
    end
    local text = fontString:GetText()
    if text and not text:find("%[ID:%s*%d+%]") then
        fontString:SetText(text .. " |cffd59b32[ID: " .. id .. "]|r")
    end
end

local function ShowCurrentQuestID()
    local id = GetQuestID and GetQuestID()
    if not id or id <= 0 then
        return
    end
    for _, fontString in ipairs({
        _G.QuestInfoTitleHeader,
        _G.QuestProgressTitleText,
        _G.QuestRewardTitleText,
    }) do
        AddIDToQuestTitle(fontString, id)
    end
end

local function AddNpcQuest(quests, seen, id, title, state)
    id = tonumber(id)
    if id and id > 0 and not seen[id] then
        seen[id] = true
        table.insert(quests, { id = id, title = title or "Unknown", state = state })
    end
end

local function CollectNpcQuests()
    local quests, seen = {}, {}

    if C_GossipInfo and C_GossipInfo.GetAvailableQuests then
        for _, info in ipairs(C_GossipInfo.GetAvailableQuests() or {}) do
            AddNpcQuest(quests, seen, info.questID, info.title, "available")
        end
    end
    if C_GossipInfo and C_GossipInfo.GetActiveQuests then
        for _, info in ipairs(C_GossipInfo.GetActiveQuests() or {}) do
            AddNpcQuest(quests, seen, info.questID, info.title, "active")
        end
    end

    if GetNumAvailableQuests and GetAvailableQuestInfo then
        for index = 1, GetNumAvailableQuests() do
            local values = { GetAvailableQuestInfo(index) }
            AddNpcQuest(quests, seen, tonumber(values[5]) or tonumber(values[#values]), GetAvailableTitle and GetAvailableTitle(index), "available")
        end
    end
    if GetNumActiveQuests and GetActiveQuestID then
        for index = 1, GetNumActiveQuests() do
            AddNpcQuest(quests, seen, GetActiveQuestID(index), GetActiveTitle and GetActiveTitle(index), "active")
        end
    end

    table.sort(quests, function(a, b) return a.id < b.id end)
    return quests
end

local function ShowNpcQuestIDs()
    local quests = CollectNpcQuests()
    if #quests == 0 then
        Notify("This NPC did not advertise any quests for the current character.")
        return
    end

    SetQuestID(quests[1].id)
    local values = {}
    for _, quest in ipairs(quests) do
        table.insert(values, quest.id .. " (" .. quest.state .. ")")
    end
    Notify("NPC quest IDs: " .. table.concat(values, ", "))
end

local function DecorateNpcQuestButtons()
    for index = 1, 32 do
        for _, prefix in ipairs({ "QuestTitleButton", "GossipTitleButton" }) do
            local button = _G[prefix .. index]
            local id = QuestIDFromButton(button)
            if button and button:IsShown() and id and button.GetText and button.SetText then
                local text = button:GetText()
                if text and not text:find("%[ID:%s*%d+%]") then
                    button:SetText(text .. " |cffd59b32[ID: " .. id .. "]|r")
                end
            end
        end
    end
end

local shiftTargetGUID
local shiftTargetTime

local settings
local minimapButton = CreateFrame("Button", "HavenGMMinimapButton", Minimap)
minimapButton:SetSize(32, 32)
minimapButton:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", -3, -2)
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

local minimapIcon = minimapButton:CreateTexture(nil, "BACKGROUND")
minimapIcon:SetSize(20, 20)
minimapIcon:SetPoint("CENTER", 0, 1)
minimapIcon:SetTexture("Interface\\MINIMAP\\TRACKING\\FlightMaster")
minimapIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local minimapBorder = minimapButton:CreateTexture(nil, "OVERLAY")
minimapBorder:SetSize(54, 54)
minimapBorder:SetPoint("TOPLEFT")
minimapBorder:SetTexture("Interface\\MINIMAP\\MiniMap-TrackingBorder")

minimapButton:SetHighlightTexture("Interface\\MINIMAP\\UI-Minimap-ZoomButton-Highlight")
minimapButton:SetScript("OnClick", function(_, button)
    if button == "RightButton" then
        InterfaceOptionsFrame_OpenToCategory(settings)
        InterfaceOptionsFrame_OpenToCategory(settings)
    else
        frame:SetShown(not frame:IsShown())
    end
end)
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("GM Toolkit")
    GameTooltip:AddLine("Left-click: show or hide", 1, 1, 1)
    GameTooltip:AddLine("Right-click: addon settings", 1, 1, 1)
    GameTooltip:Show()
end)
minimapButton:SetScript("OnLeave", GameTooltip_Hide)

settings = CreateFrame("Frame", "HavenGMSettingsPanel")
settings.name = "Haven GM Toolkit"

local settingsTitle = settings:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
settingsTitle:SetPoint("TOPLEFT", 16, -16)
settingsTitle:SetText("GM Toolkit")

local settingsDescription = settings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
settingsDescription:SetPoint("TOPLEFT", settingsTitle, "BOTTOMLEFT", 0, -12)
settingsDescription:SetWidth(620)
settingsDescription:SetJustifyH("LEFT")
settingsDescription:SetText(
    "Local HavenCore quest-testing controls. Your character level is never changed.\n\n" ..
    "Runtime toggles\nA full client login starts with every toggle displayed as OFF. /reload preserves the displayed state. No GM commands are sent automatically.\n\n" ..
    "Quest IDs\nShift-click a quest title or quest link to fill the Quest ID field. Quest details, links and NPC quest lists display their IDs. Shift-click a quest NPC and interact with it to list the quests advertised for your character.\n\n" ..
    "Item IDs\nShift + Right-click a bag item to fill the Item ID field. Item IDs are also shown in tooltips.\n\n" ..
    "Action-bar macros\n/instantkill  •  /80kill  •  /hgod  •  /hfly  •  /hdebug  •  /hspeed 1-20  •  /hlevel 1-120\n\n" ..
    "Window\n/hgm toggles the toolkit. /hgm reset restores its default screen position."
)

local minimapCheck = CreateFrame("CheckButton", "HavenGMMinimapCheck", settings, "InterfaceOptionsCheckButtonTemplate")
minimapCheck:SetPoint("TOPLEFT", settingsDescription, "BOTTOMLEFT", -2, -18)
HavenGMMinimapCheckText:SetText("Show minimap button")
minimapCheck:SetScript("OnClick", function(self)
    HavenGMDB.showMinimap = self:GetChecked() == true
    minimapButton:SetShown(HavenGMDB.showMinimap)
end)
settings:SetScript("OnShow", function()
    minimapCheck:SetChecked(HavenGMDB and HavenGMDB.showMinimap ~= false)
end)
InterfaceOptions_AddCategory(settings)

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("GOSSIP_SHOW")
events:RegisterEvent("QUEST_GREETING")
events:RegisterEvent("QUEST_DETAIL")
events:RegisterEvent("QUEST_PROGRESS")
events:RegisterEvent("QUEST_COMPLETE")
events:SetScript("OnEvent", function(_, event, loaded)
    if event == "ADDON_LOADED" then
        if loaded == ADDON_NAME then
            HavenGMDB = HavenGMDB or {}
            HavenGMDB.toggles = HavenGMDB.toggles or {}
            if HavenGMDB.showMinimap == nil then
                HavenGMDB.showMinimap = true
            end
            if HavenGMDB.position then
                frame:ClearAllPoints()
                frame:SetPoint(HavenGMDB.position[1], UIParent, HavenGMDB.position[2], HavenGMDB.position[3], HavenGMDB.position[4])
            end

            allButton:Refresh()
            for _, button in pairs(toggles) do
                button:Refresh()
            end
            minimapButton:SetShown(HavenGMDB.showMinimap)
            Notify("Loaded. Type /hgm to show or hide the toolbar.")
        end

        InstallQuestHooks()
        return
    end

    if event == "PLAYER_LOGIN" then
        -- SavedVariables survive a full client restart, but GM runtime flags may
        -- not. On a real login, reset only the displayed state; never send
        -- automatic GM commands. /reload keeps the current display state.
        if type(IsInitialLogin) == "function" and IsInitialLogin() then
            SetRuntimeTogglesOff()
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        if IsShiftKeyDown() and UnitExists("target") and not UnitIsPlayer("target") then
            shiftTargetGUID = UnitGUID("target")
            shiftTargetTime = GetTime()
        end
    elseif event == "GOSSIP_SHOW" or event == "QUEST_GREETING" then
        InstallQuestHooks()
        C_Timer.After(0, function()
            DecorateNpcQuestButtons()
            if IsShiftKeyDown() or (shiftTargetGUID == UnitGUID("target") and shiftTargetTime and GetTime() - shiftTargetTime < 5) then
                ShowNpcQuestIDs()
            end
        end)
    elseif event == "QUEST_DETAIL" or event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" then
        C_Timer.After(0, ShowCurrentQuestID)
    end
end)
