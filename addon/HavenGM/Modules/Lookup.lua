local _, HG = ...

HG:RegisterTab("lookup", "LOOKUP", 5, function(parent)
    local search = HG:Section(parent, "SEARCH", 12, -12, 736, 404)
    local selected = HG.lookupCategories[1]
    local dropdown = HG:DropDown(search, "HavenGMLookupDropDown", 2, -54, 128, HG.lookupCategories, selected, function(item) selected = item end)
    local query = HG:Edit(search, "lookupQuery", 184, -55, 300, false, "")
    HG:ClearButton(search, query, 494, -55)
    local function execute()
        local value = strtrim(query:GetText() or "")
        if value == "" then HG:Notify("Enter a search term.") return end
        selected = dropdown:GetSelected()
        HG:OpenLookupModal(selected.key, value, selected.field, selected.text:upper())
    end
    HG:Button(search, "SEARCH", 532, -55, 94, execute)

    local status = HG:Edit(search, "lookupStatus", 26, -111, 430, false, HG.lastLookupStatus or "No result loaded yet.")
    status:SetTextColor(0.72, 0.78, 0.88)
    status:SetAutoFocus(false)
    HG.lookupStatusLabel = status

    function HG:SetLookupStatus(result, fieldKey)
        if not result or not result.id then return end
        local destinations = {
            itemID = "Item ID",
            spellID = "Spell ID",
            questID = "Quest ID",
            creatorEntry = "NPC ID",
            objectEntry = "GameObject ID",
        }
        local name = result.name and strtrim(result.name) or ""
        local destination = destinations[fieldKey] or tostring(fieldKey or "ID")
        if name ~= "" then
            self.lastLookupStatus = name .. "\nID " .. result.id .. " loaded into " .. destination
        else
            self.lastLookupStatus = "ID " .. result.id .. " loaded into " .. destination
        end
        if self.lookupStatusLabel then self.lookupStatusLabel:SetText(self.lastLookupStatus) end
    end

    HG:Button(search, "OPEN MATCHING TOOL", 466, -111, 160, function()
        selected = dropdown:GetSelected()
        if selected.key == "lookupQuest" then HG:ShowTab("quests")
        elseif selected.key == "lookupCreature" or selected.key == "lookupObject" then HG:ShowTab("creator")
        else HG:ShowTab("character") end
    end, "Opens the tab where the selected result type is normally used.")

    HG.SetLookup = function(_, commandKey, value)
        for _, item in ipairs(HG.lookupCategories) do
            if item.key == commandKey then
                selected = item
                dropdown:SetItems(HG.lookupCategories, item)
                break
            end
        end
        query:SetText(value or "")
        execute()
    end
end)
