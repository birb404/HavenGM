local _, HG = ...

local function formatCommand(template, arguments)
    local ok, result = pcall(string.format, template, unpack(arguments or {}))
    if not ok then
        HG:Notify("Could not build command: " .. tostring(result))
        return nil
    end
    return result
end

function HG:SendRaw(command, capture)
    if not command or command == "" then return end
    if capture and self.output then self.output:Begin(command) end
    SendChatMessage(command, "SAY")
    if not self.db or self.db.settings.echoCommands ~= false then
        self:Notify(command)
    end
end

function HG:Execute(key, ...)
    local definition = self.commandCatalog[key]
    if not definition then
        self:Notify("Unknown registered action: " .. tostring(key))
        return false
    end
    if definition.requiresTarget and not UnitExists("target") then
        self:Notify("Select a target first.")
        return false
    end
    local arguments = { ... }
    if definition.commands then
        local state = arguments[1]
        for _, template in ipairs(definition.commands) do
            self:SendRaw(formatCommand(template, { state }), false)
        end
    else
        self:SendRaw(formatCommand(definition.template, arguments), definition.capture)
    end
    return true
end

function HG:ExecuteConfirmed(key, title, ...)
    local definition = self.commandCatalog[key]
    if not definition then return self:Execute(key, ...) end
    local arguments = { ... }
    local command = definition.template and formatCommand(definition.template, arguments) or key
    self:Confirm(title or "Run this command?", command, function()
        HG:Execute(key, unpack(arguments))
    end)
end
