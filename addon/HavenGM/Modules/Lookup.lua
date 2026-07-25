local _, HG = ...

HG:RegisterTab("lookup", "LOOKUP", 5, function(parent)
    local search = HG:Section(parent, "SEARCH", 12, -12, 736, 118)
    local selected = HG.lookupCategories[1]
    local dropdown = HG:DropDown(search, "HavenGMLookupDropDown", 2, -38, 150, HG.lookupCategories, selected, function(item) selected = item end)
    local query = HG:Edit(search, "lookupQuery", 184, -39, 310, false, "")
    HG:ClearButton(search, query, 500, -39)
    local function execute()
        local value = strtrim(query:GetText() or "")
        if value == "" then HG:Notify("Enter a search term.") return end
        selected = dropdown:GetSelected()
        HG:OpenLookupModal(selected.key, value, selected.field, selected.text:upper())
    end
    HG:Button(search, "SEARCH", 538, -39, 94, execute)
    HG:Button(search, "OPEN MATCHING TOOL", 184, -75, 160, function()
        selected = dropdown:GetSelected()
        if selected.key == "lookupQuest" then HG:ShowTab("quests")
        elseif selected.key == "lookupCreature" or selected.key == "lookupObject" then HG:ShowTab("creator")
        else HG:ShowTab("character") end
    end, "Opens the tab where the selected result type is normally used.")
    HG:Label(search,
        "Search results open inside HavenGM. Double-click a result to fill its matching ID and name fields.",
        360, -82, 350)

    local guide = HG:Section(parent, "HOW IT WORKS", 12, -142, 736, 118)
    HG:Label(guide,
        "1. Choose a category and search by name.\n2. Single-click a result to inspect it.\n3. Double-click to load its ID into the matching Character, Quest or Creator field.",
        14, -44, 690)

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
