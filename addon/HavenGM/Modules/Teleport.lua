local _, HG = ...

local function shortLabel(text)
    text = tostring(text or "")
    if #text > 17 then return string.sub(text, 1, 15) .. ".." end
    return text
end

HG:RegisterTab("teleport", "TELEPORT", 4, function(parent)
    local section = HG:Section(parent, "DESTINATIONS", 12, -12, 736, 270)
    local selectedArea = HG.teleportAreas[2]
    local selectedDestination = selectedArea.destinations[1]
    local destinationDrop
    local favoriteButton
    local favoriteButtons = {}
    local emptyFavorites

    local function findFavorite(command)
        for index, favorite in ipairs(HG.db.teleportFavorites) do
            if favorite.command == command then return index, favorite end
        end
    end

    local function rememberAndTeleport(destination)
        if not destination or not destination.command then return end
        HG:Execute("teleport", destination.command)
        table.insert(HG.db.teleportRecent, 1, {
            text = destination.text,
            command = destination.command,
        })
        while #HG.db.teleportRecent > 8 do table.remove(HG.db.teleportRecent) end
    end

    local function refreshFavoriteState()
        if not favoriteButton then return end
        local isFavorite = selectedDestination and findFavorite(selectedDestination.command) ~= nil
        favoriteButton:SetRestingColor(isFavorite and HG.colors.on or HG.colors.gold)
    end

    local function renderFavorites()
        for _, button in ipairs(favoriteButtons) do button:Hide() end
        favoriteButtons = {}

        if #HG.db.teleportFavorites == 0 then
            emptyFavorites:Show()
            return
        end
        emptyFavorites:Hide()

        for index, saved in ipairs(HG.db.teleportFavorites) do
            if index > 10 then break end
            local favorite = saved
            local column = (index - 1) % 5
            local row = math.floor((index - 1) / 5)
            local button = HG:Button(
                section,
                shortLabel(favorite.text),
                14 + column * 140,
                -168 - row * 36,
                132,
                function() rememberAndTeleport(favorite) end,
                favorite.text .. "\nLeft-click: teleport\nRight-click: remove favorite"
            )
            button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            button:SetScript("OnClick", function(_, mouseButton)
                if mouseButton == "RightButton" then
                    local favoriteIndex = findFavorite(favorite.command)
                    if favoriteIndex then
                        table.remove(HG.db.teleportFavorites, favoriteIndex)
                        HG:Notify("Favorite removed: " .. favorite.text)
                        renderFavorites()
                        refreshFavoriteState()
                    end
                else
                    rememberAndTeleport(favorite)
                end
            end)
            favoriteButtons[#favoriteButtons + 1] = button
        end
    end

    local areaDrop = HG:DropDown(section, "HavenGMAreaDropDown", 2, -38, 190, HG.teleportAreas, selectedArea, function(area)
        selectedArea = area
        selectedDestination = area.destinations[1]
        destinationDrop:SetItems(area.destinations, selectedDestination)
        refreshFavoriteState()
    end)
    destinationDrop = HG:DropDown(section, "HavenGMDestinationDropDown", 214, -38, 210, selectedArea.destinations, selectedDestination, function(destination)
        selectedDestination = destination
        refreshFavoriteState()
    end)

    HG:Button(section, "TELEPORT", 458, -40, 104, function()
        selectedArea = areaDrop:GetSelected()
        selectedDestination = destinationDrop:GetSelected()
        rememberAndTeleport(selectedDestination)
    end)

    favoriteButton = HG:Button(section, "FAVORITE", 572, -40, 38, function()
        selectedDestination = destinationDrop:GetSelected()
        local index = findFavorite(selectedDestination.command)
        if index then
            table.remove(HG.db.teleportFavorites, index)
            HG:Notify("Favorite removed: " .. selectedDestination.text)
        else
            if #HG.db.teleportFavorites >= 10 then
                HG:Notify("You can save up to 10 teleport favorites. Right-click one below to remove it.")
                return
            end
            table.insert(HG.db.teleportFavorites, {
                text = selectedDestination.text,
                command = selectedDestination.command,
            })
            HG:Notify("Favorite added: " .. selectedDestination.text)
        end
        renderFavorites()
        refreshFavoriteState()
    end, "Add or remove the selected destination from favorites.")
    favoriteButton.label:Hide()
    local favoriteIcon = favoriteButton:CreateTexture(nil, "ARTWORK")
    favoriteIcon:SetSize(20, 20)
    favoriteIcon:SetPoint("CENTER")
    favoriteIcon:SetTexture("Interface\\COMMON\\ReputationStar")
    favoriteButton.icon = favoriteIcon
    favoriteButton:SetScript("OnLeave", function()
        refreshFavoriteState()
        GameTooltip_Hide()
    end)

    HG:Button(section, "RETURN TO LAST LOCATION", 14, -88, 210, function() HG:Execute("recall") end,
        "Returns to the location stored by HavenCore before the last relevant teleport.")
    HG:Button(section, "LAST USED", 238, -88, 110, function()
        local recent = HG.db.teleportRecent[1]
        if recent then rememberAndTeleport(recent)
        else HG:Notify("No recent teleport in this session.") end
    end)

    HG:Label(section, "FAVORITES", 14, -138)
    emptyFavorites = HG:Label(section, "Select a destination and click ☆ to add it here.", 14, -170, 500)

    renderFavorites()
    refreshFavoriteState()
end)
