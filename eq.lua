local addonName, BlessMeisterAddon = ...


-- Note that we use the SavedVariable EverQuestDb
-- Our AddOn Class

-- STATIC function
function BlessMeisterAddon.Catch(err)
    file, line, rest = FileLine(err)
    if file and line and rest then
        err = "[" .. file .. ":" .. line .. "]:" .. rest
    end
    err = err .. ":\n" .. debugstack(2)

    local frame = GetChatFrameByName("error")
    frame:AddMessage(err)
    return err
end


function BlessMeisterAddon:init(addonName)
    self.Name = addonName
    self.Version = "0.1.0"
    self.Defaults = {
        enabled = true,
        debug = false,
        bless_triggerchance = 0.5,
        message = "EverQuest ready.",
        color = "|cff00ccff",
        showHelp = true,
    }
    self.tabs = 0
    self.current_target = "target"
    self.current_spell_info = nil
    self.last_emote = nil
    self.last_sentence = nil
    self.last_sentence_timeout = 0
    -- map pattern (string) -> sentence builder (function)
    self.spell_maps = {}
    self.player_race = nil
    self.player_class = nil


    self.UNIT_TOKENS = {
        "target", "mouseover", "focus", "player"
    }
    for n = 1, 4 do
        table.insert(self.UNIT_TOKENS, "party" .. n)
    end
    for n = 1, 40 do
        table.insert(self.UNIT_TOKENS, "raid" .. n)
    end
    for n = 1, 4 do
        table.insert(self.UNIT_TOKENS, "arena" .. n)
    end



    self.phrases = {}

    self.frame = CreateFrame("Frame")
    self.frame:RegisterEvent("PLAYER_LOGIN")
    self.frame:SetScript("OnEvent", function(frame, ...)
        xpcall(function(...) self:OnEvent(...) end, self.Catch, ...)
    end)
end

function BlessMeisterAddon:OnEvent(event, ...)

    if event == "PLAYER_LOGIN" then
        self:OnPlayerLoginEvent(...)

    elseif event == "UNIT_SPELLCAST_SENT" then
        self:OnUnitSpellcastSent(...)

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        self:OnUnitSpellcastSucceeded(...)

    end

end

function BlessMeisterAddon:OnPlayerLoginEvent(...)

    -- intialize the savedvariable
    EverQuestDb = EverQuestDb or {}
    self.db = MergeDefaults(self.Defaults, EverQuestDb)
    self.db.message = self.db.message or self.Defaults.message
    self.db.enabled = self.db.enabled ~= false
    self.db.debug = self.db.debug ~= false
    self.db.bless_triggerchance = self.db.bless_triggerchance or self.Defaults.bless_triggerchance
    self.db.color = self.db.color or self.Defaults.color
    self.db.showHelp = self.db.showHelp ~= false
    EverQuestDb = self.db

    self.player_race = UnitRace("player")
    self.player_class = split(UnitClass("player"))[1]
    self:debug("Player is a '%s' '%s'", self.player_race, self.player_class)

    self.short_slash = "/eq"
    SLASH_EVERQUEST1 = self.short_slash
    SlashCmdList["EVERQUEST"] = function(...)
        xpcall(function(...) self:HandleSlashCommand(...) end, self.Catch, ...)
    end

    self:Print("Version " .. self.Version .. " loaded.")
    self:Print(self.db.message)
end

-- Helper to identify a unit token by name
function BlessMeisterAddon:whichUnit(unit_name)
    if unit_name == nil then
        return nil
    end

    for _, token in ipairs(self.UNIT_TOKENS) do
        local token_unit_name, token_unit_last = UnitName(token)
        if token_unit_name ~= nil then

            if token_unit_last ~= nil then
                token_unit_name = token_unit_name .." ".. token_unit_last
            end

            self:debug("Is token %s (name %s) = %s ? %s", token, token_unit_name, unit_name, unit_name == token_unit_name)
            if token_unit_name == unit_name then
                return token
            end
        end
    end
    return nil
end

-- Helper function to print debug info text to the user
function BlessMeisterAddon:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage((self.db and self.db.color or "|cff00ccff") .. "[".. self.Name .."]|r " .. tostring(message))
end

function BlessMeisterAddon:debug(message, ...)
    message = strfmt(message, ...)
    local frame = GetChatFrameByName("debug")
    frame:AddMessage("["..FuncName().."] " .. message)
end

function BlessMeisterAddon:error(message, ...)
    message = strfmt(message, ...)
    local frame = GetChatFrameByName("error")
    frame:AddMessage("["..FuncName().."] " .. message)
end

-- Helper function to save our settings
function BlessMeisterAddon:Save()
    if type(self.db) == "table" then
        EverQuestDb = self.db
    end
end

-- Toggle the enabled value
function BlessMeisterAddon:ToggleEnabled()
    self.db.enabled = not self.db.enabled
    self:Save()
    self:Print(self.db.enabled and "Enabled." or "Disabled.")
end

function BlessMeisterAddon:SendChatMessage(message, channel)
    if C_ChatInfo ~= nil then
        C_ChatInfo.SendChatMessage(message, channel)
    else
        SendChatMessage(message, channel)
    end
end

function BlessMeisterAddon:HandleSlashCommand(msg)
    -- normalize it, and split on spaces
    local input = Trim(msg or ""):lower()
    local params = split(input)
    local command = table.remove(params, 1) or "<none>"

    self:debug("Command: " .. command)

    if command == "toggle" then
        self:ToggleEnabled()
        return
    end

    if command == "debug" then
        self.db.debug = not self.db.debug
        self:Save()
        self:Print("Deugging " .. (self.db.debug and "Enabled." or "Disabled."))
        return
    end

    if command == "status" then
        self:Print("Status: " .. (self.db.enabled and "enabled" or "disabled"))
        self:Print("Deugging " .. (self.db.debug and "Enabled." or "Disabled."))
        return
    end


    self:Print("Unknown command. Use "..self.short_slash.." help")
end


-- initialize
BlessMeisterAddon:init(addonName)

