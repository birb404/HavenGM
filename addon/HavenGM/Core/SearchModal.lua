local _, HG = ...

local function plainText(text)
    text = tostring(text or "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:gsub("|H.-|h%[(.-)%]|h", "%1")
    return strtrim(text)
end

local function resultID(commandKey, line)
    local patterns = {
        lookupItem = "|Hitem:(%d+)",
        lookupSpell = "|Hspell:(%d+)",
        lookupQuest = "|Hquest:(%d+)",
        lookupCreature = "|Hcreature[^:]*:(%d+)",
        lookupObject = "|Hgameobject[^:]*:(%d+)",
    }
    local pattern = patterns[commandKey]
    local id = pattern and line:match(pattern)
    if not id then id = line:match("%[ID:%s*(%d+)%]") end
    if not id then id = line:match("^%s*(%d+)%s") end
    return tonumber(id)
end

function HG:EnsureLookupModal()
    if self.lookupModal then return self.lookupModal end

    local modal = CreateFrame("Frame", "HavenGMLookupModal", self.frame or UIParent)
    modal:SetSize(650, 410)
    modal:SetPoint("CENTER", self.frame or UIParent, "CENTER")
    modal:SetFrameStrata("DIALOG")
    modal:EnableMouse(true)
    modal:SetMovable(true)
    modal:RegisterForDrag("LeftButton")
    modal:SetScript("OnDragStart", modal.StartMoving)
    modal:SetScript("OnDragStop", modal.StopMovingOrSizing)
    modal:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 24, edgeSize = 24,
        insets = { left = 7, right = 7, top = 7, bottom = 7 },
    })
    modal:Hide()
    modal:SetScript("OnHide", function() HG.output.lookupModalActive = false end)

    local title = modal:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -18)
    title:SetText("LOOKUP RESULTS")
    modal.title = title
    local close = CreateFrame("Button", nil, modal, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    local help = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", 28, -48)
    help:SetText("Mouse wheel scrolls. Single-click selects. Double-click fills the destination ID field.")

    local list = CreateFrame("Frame", nil, modal)
    list:SetPoint("TOPLEFT", 24, -72)
    list:SetSize(602, 292)
    list:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    list:SetBackdropColor(0.015, 0.025, 0.04, 0.98)
    list:SetBackdropBorderColor(0.45, 0.24, 0.03, 1)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, delta)
        local maximum = math.max(0, #modal.results - 10)
        modal.offset = math.max(0, math.min(maximum, modal.offset - delta))
        modal:RefreshRows()
    end)

    modal.rows = {}
    for index = 1, 10 do
        local row = CreateFrame("Button", nil, list)
        row:SetPoint("TOPLEFT", 8, -8 - ((index - 1) * 27))
        row:SetSize(586, 25)
        local background = row:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        row.background = background
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("LEFT", 8, 0)
        label:SetPoint("RIGHT", -8, 0)
        label:SetJustifyH("LEFT")
        row.label = label
        row:SetScript("OnEnter", function(self)
            if self.result then self.background:SetColorTexture(0.20, 0.13, 0.03, 1) end
        end)
        row:SetScript("OnLeave", function() modal:RefreshRows() end)
        row:SetScript("OnClick", function(self)
            if not self.result then return end
            local now = GetTime()
            local isDouble = modal.selected == self.result and modal.lastClick and now - modal.lastClick < 0.45
            modal.selected = self.result
            modal.lastClick = now
            modal:RefreshRows()
            if isDouble then modal:UseSelected() end
        end)
        modal.rows[index] = row
    end

    local previous = self:Button(modal, "PREVIOUS", 24, -374, 94, function()
        modal.offset = math.max(0, modal.offset - 10)
        modal:RefreshRows()
    end)
    local page = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    page:SetPoint("LEFT", previous, "RIGHT", 14, 0)
    modal.page = page
    self:Button(modal, "NEXT", 214, -374, 76, function()
        if modal.offset + 10 < #modal.results then modal.offset = modal.offset + 10 end
        modal:RefreshRows()
    end)
    self:Button(modal, "USE SELECTED", 472, -374, 154, function() modal:UseSelected() end)

    function modal:RefreshRows()
        for rowIndex, row in ipairs(self.rows) do
            local result = self.results[self.offset + rowIndex]
            row.result = result
            row:SetShown(result ~= nil)
            if result then
                row.label:SetText(result.label)
                if self.selected == result then
                    row.background:SetColorTexture(0.12, 0.30, 0.16, 1)
                else
                    row.background:SetColorTexture(0.04, 0.07, 0.11, rowIndex % 2 == 0 and 0.92 or 0.72)
                end
            end
        end
    local pages = math.max(1, math.ceil(#self.results / 10))
        if #self.results == 0 then
            self.page:SetText("No results yet")
        else
            local first = self.offset + 1
            local last = math.min(#self.results, self.offset + 10)
            self.page:SetText("Results " .. first .. "-" .. last .. " of " .. #self.results)
        end
    end

    function modal:UseSelected()
        if not self.selected then HG:Notify("Select a result first.") return end
        if not self.selected.id then HG:Notify("That result has no numeric ID.") return end
        if not self.fieldKey then HG:Notify("That result has no destination field.") return end
        HG:SetField(self.fieldKey, self.selected.id)
        local searchFields = {
            itemID = "itemSearch",
            spellID = "spellSearch",
            questID = "questSearch",
            creatorEntry = "creatorSearch",
            objectEntry = "objectSearch",
        }
        local searchField = searchFields[self.fieldKey]
        if searchField and self.selected.name then HG:SetField(searchField, self.selected.name) end
        HG:Notify("Loaded " .. self.selected.id .. " into " .. tostring(self.fieldKey) .. ".")
        self:Hide()
    end

    self.lookupModal = modal
    return modal
end

function HG:OpenLookupModal(commandKey, query, fieldKey, categoryText)
    query = strtrim(query or "")
    if query == "" then self:Notify("Enter a search term.") return end
    local modal = self:EnsureLookupModal()
    modal.commandKey = commandKey
    modal.fieldKey = fieldKey
    modal.results = {}
    modal.seen = {}
    modal.selected = nil
    modal.lastClick = nil
    modal.offset = 0
    modal.title:SetText((categoryText or "LOOKUP") .. ': "' .. query .. '"')
    modal:RefreshRows()
    modal:Show()
    self.output.lookupModalActive = true
    self:Execute(commandKey, query)
end

function HG:AddLookupResult(line)
    local modal = self.lookupModal
    if not modal or not modal:IsShown() or not self.output.lookupModalActive then return end
    for resultLine in tostring(line):gmatch("[^\r\n]+") do
        local id = resultID(modal.commandKey, resultLine)
        if id then
            local key = tostring(id)
            if not modal.seen[key] then
                modal.seen[key] = true
                local name = resultLine:match("|h%[([^%]]+)%]|h")
                modal.results[#modal.results + 1] = {
                    id = id,
                    name = name,
                    label = "[" .. id .. "]  " .. plainText(resultLine),
                }
            end
        end
    end
    modal:RefreshRows()
end
