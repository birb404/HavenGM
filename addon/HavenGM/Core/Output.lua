local _, HG = ...

local Output = { lines = {}, activeUntil = 0 }
HG.output = Output

function Output:Begin(command)
    self.lines = { "|cffd59b32> " .. command .. "|r" }
    self.activeUntil = GetTime() + (self.lookupModalActive and 15 or 4)
    self.suppressChat = true
    if self.Refresh then self:Refresh() end
end

function Output:Add(message)
    if GetTime() > self.activeUntil then return end
    local clean = tostring(message or "")
    self.lines[#self.lines + 1] = clean
    if HG.AddLookupResult then HG:AddLookupResult(clean) end
    if #self.lines > 80 then table.remove(self.lines, 1) end
    if self.pendingField then
        local id = self:FirstID(self.pendingField)
        if id then
            HG:SetField(self.pendingField, id)
            HG:Notify("Lookup selected ID " .. id .. ".")
            self.pendingField = nil
        end
    end
    if self.Refresh then self:Refresh() end
end

function Output:GetText()
    return table.concat(self.lines, "\n")
end

function HG:LookupInto(commandKey, query, fieldKey)
    query = strtrim(query or "")
    if query == "" then
        self:Notify("Enter a search name or ID.")
        return
    end
    local title = commandKey:gsub("^lookup", ""):upper()
    self:OpenLookupModal(commandKey, query, fieldKey, title)
end

function Output:FirstID(fieldKey)
    for _, line in ipairs(self.lines) do
        local id
        if fieldKey == "objectEntry" or fieldKey == "creatorEntry" then
            id = line:match("[Ee]ntry%s*[Ii]?[Dd]?%s*[:=]%s*(%d+)")
                or line:match("[Ee]ntry%s+(%d+)")
        end
        id = id or
            line:match("|Hitem:(%d+)") or
            line:match("|Hspell:(%d+)") or
            line:match("|Hquest:(%d+)") or
            line:match("|Hcreature[^:]*:(%d+)") or
            line:match("|Hgameobject[^:]*:(%d+)") or
            line:match("%[ID:%s*(%d+)%]") or
            line:match("^%s*(%d+)%s")
        if id then return tonumber(id) end
    end
end

local function capture(_, _, message)
    local suppress = GetTime() <= Output.activeUntil and Output.suppressChat == true
    Output:Add(message)
    return suppress
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", capture)
