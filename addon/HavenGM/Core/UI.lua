local _, HG = ...

function HG:ShowTab(key)
    local selected = self.tabByKey[key] or self.tabs[1]
    if not selected then return end
    self.db.lastTab = selected.key
    for tabKey, panel in pairs(self.tabPanels) do panel:SetShown(tabKey == selected.key) end
    for tabKey, button in pairs(self.tabButtons) do
        if tabKey == selected.key then
            button.label:SetTextColor(1, 0.82, 0.25)
            button:SetRestingColor({ 0.16, 0.20, 0.28, 1 })
        else
            button.label:SetTextColor(0.72, 0.78, 0.88)
            button:SetRestingColor({ 0.03, 0.05, 0.08, 1 })
        end
    end
end

function HG:BuildUI()
    table.sort(self.tabs, function(a, b) return a.order < b.order end)
    local frame = CreateFrame("Frame", "HavenGMFrame", UIParent)
    frame:SetSize(790, 520)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        HG.db.position = { point, relativePoint, x, y }
    end)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 24, edgeSize = 24,
        insets = { left = 7, right = 7, top = 7, bottom = 7 },
    })
    if self.db.position then
        frame:ClearAllPoints()
        frame:SetPoint(self.db.position[1], UIParent, self.db.position[2], self.db.position[3], self.db.position[4])
    end
    frame:SetScale(self.db.settings.scale or 1)
    frame:SetMovable(self.db.settings.lockFrame ~= true)
    self.frame = frame

    local headerIcon = frame:CreateTexture(nil, "ARTWORK")
    headerIcon:SetSize(32, 32)
    headerIcon:SetPoint("TOPLEFT", 18, -14)
    headerIcon:SetTexture("Interface\\AddOns\\HavenGM\\Media\\HavenIcon.tga")
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", headerIcon, "RIGHT", 4, 0)
    title:SetText("HAVEN  |cff8fb8e8GM TOOLKIT|r")
    local version = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    version:SetPoint("TOPRIGHT", -42, -18)
    version:SetText("v" .. self.version)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)

    self.tabPanels, self.tabButtons = {}, {}
    local tabGap = 4
    local tabWidth = 89
    local tabRowWidth = (#self.tabs * tabWidth) + (math.max(0, #self.tabs - 1) * tabGap)
    local tabX = math.floor((frame:GetWidth() - tabRowWidth) / 2)
    for _, definition in ipairs(self.tabs) do
        local button = self:Button(frame, definition.title, tabX, -49, tabWidth, function() HG:ShowTab(definition.key) end)
        button:SetSize(tabWidth, 28)
        self.tabButtons[definition.key] = button
        tabX = tabX + tabWidth + tabGap

        local panel = CreateFrame("Frame", nil, frame)
        panel:SetPoint("TOPLEFT", 15, -85)
        panel:SetSize(760, 430)
        self.tabPanels[definition.key] = panel
        definition.build(panel)
    end

    local minimap = CreateFrame("Button", "HavenGMMinimapButton", Minimap)
    minimap:SetSize(32, 32)
    minimap:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", -3, -2)
    minimap:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local icon = minimap:CreateTexture(nil, "BACKGROUND")
    -- Slightly oversize the artwork inside the stock tracking border. The
    -- source icon has transparent edge pixels which otherwise expose a bright
    -- crescent along the bottom of the minimap button.
    icon:SetSize(22, 22); icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture("Interface\\AddOns\\HavenGM\\Media\\HavenMinimapIcon.tga")
    icon:SetTexCoord(0, 1, 0, 1)
    local border = minimap:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54); border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\MINIMAP\\MiniMap-TrackingBorder")
    minimap:SetHighlightTexture("Interface\\MINIMAP\\UI-Minimap-ZoomButton-Highlight")
    minimap:SetScript("OnClick", function() frame:SetShown(not frame:IsShown()) end)
    minimap:SetShown(self.db.settings.showMinimap ~= false)
    self.minimapButton = minimap

    self:ShowTab(self.db.lastTab)
    self:RefreshRuntimeButtons()
end
