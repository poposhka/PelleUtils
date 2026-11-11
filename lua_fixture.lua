local colors = {
    reset   = string.char(27).."[0m",
    red     = string.char(27).."[31m",
    green   = string.char(27).."[32m",
    yellow  = string.char(27).."[33m",
    blue    = string.char(27).."[34m",
    magenta = string.char(27).."[35m",
    cyan    = string.char(27).."[36m",
    white   = string.char(27).."[37m",
    bold    = string.char(27).."[1m",
}

local function colorize(color, text)
    return (colors[color] or "") .. tostring(text) .. colors.reset
end

SEX_UNKNOWN = 1
SEX_FEMALE = 2
SEX_MALE = 3

-- collection of Wow API frames we mock
mockFrames = {}

GameUnits = {}

function CreateUnit(name, sex, race, class, zone)
    GameUnits[name] = {
        name = name,
        sex = sex,
        race = race,
        class = class,
        zone = zone,
    }
end

CreateUnit("Bulbasaur", SEX_MALE, "Orc", "Dingus", "Netherworld")
CreateUnit("Mira", SEX_FEMALE, "Human", "Paladin", "Stormwind")

UnitStates = {
    player = GameUnits["Bulbasaur"],
    target = GameUnits["Mira"]
}

function SetUnitState(unit, name)
    UnitStates[unit] = GameUnits[name]
end


-- Mocked WOW API chat frame
DEFAULT_CHAT_FRAME = {
    AddMessage = function(self, msg)
        print(msg)
    end,
}

-- Mocked SavedVariable
PelleUtilsDB = {
    enabled = true,
    bless_triggerchance = 1.0,
    message = "PelleUtils ready.",
    color = "|cff00ccff",
    showHelp = true,
}

-- mocked API SlashCmdList
SlashCmdList = {}

-- Mocked WOW API
function debugstack(depth, ...)
    -- Level 2 = the function that called log_caller()
    local info = debug.getinfo(depth + 1, "nSl")
    local file = info.short_src or "unknown"
    local line = info.currentline or "?"
    local func = info.name or "anonymous"
    -- return a wow-like debug string
    return file..":"..line..": in function '".. func .."'."
end

-- Mocked WOW API function to get (name,zone) of unit
function UnitName(unit)
    local unit_state = UnitStates[unit]
    if unit_state then
        return unit_state.name, unit_state.zone
    end
    return nil, nil
end

-- Mocked WOW API function to create a frame
function CreateFrame(frameType, name, parent, template)
    local frame = {
        scripts = {},
        event = "",
        callback = nil
    }

    function frame:RegisterEvent(eventName)
        self.event = self.event .. "|" .. eventName .. "|"
    end

    function frame:RegisterUnitEvent(eventName, unitName)
        self.event = self.event .. "|" .. eventName .. "|"
    end

    -- used by the addon to establish callbacks for events from the frame to the addon
    function frame:SetScript(scriptName, callback)
        self.scripts[scriptName] = callback
    end

    -- simulate an event to fire
    function frame:SimulateFireEvent(eventName, ...)
        local callback = self.scripts.OnEvent
        if callback and string.find(self.event, "|" .. eventName .. "|") then
            callback(self, eventName, ...)
        end
    end
    table.insert(mockFrames, frame)
    return frame
end

-- mocked API
function UnitGUID(unit)
    if unit == "player" then
        return "_player_guid_"
    end
    return nil
end

-- mocked API
function UnitTokenFromGUID(guid)
    return "target"
end

function CombatLogGetCurrentEventInfo()
    -- timestamp, subEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool
    return 1234, "SPELL_CAST_SUCCESS", "hideCaster", "_player_guid_", "Player One", "sourceFlags", "sourceRaidFlags",
        "_dest_guid_", "John Warrior", "destFlags", "destRaidFlags", "spellID", "spellName", "spellSchool"
end

-- Mocked WOW API function to send a chat message
function SendChatMessage(message, channel)
    message = tostring(message)
    print(colors.yellow .. "[SAY] " .. message .. colors.reset)
end

-- Mocked WOW API function to check if unit exists
function UnitExists(unit)
    return UnitStates[unit] ~= nil
end

-- Mocked WOW API function checking if unitA is unitB
function UnitIsUnit(unitA, unitB)
    if UnitStates[unitA] == nil or UnitStates[unitB] == nil then
        return false
    end

    return UnitStates[unitA].name == UnitStates[unitB].name
end

-- Mocked WOW API function to check race of unit
-- returns: racename_localized, racename_english, raceid
function UnitRace(unit)
    local unit_state = UnitStates[unit]
    if unit_state then
        return unit_state.race, unit_state.race, 123
    end
    return nil, nil, nil
end

-- Mocked WOW API function to check sex of unit
-- returns: 1=unknown/neutral 2=male 3=female
function UnitSex(unit)
    local unit_state = UnitStates[unit]
    if unit_state then
        return unit_state.sex
    end
    return nil
end

function UnitClass(unit)
    local unit_state = UnitStates[unit]
    if unit_state then
        return unit_state.class
    end
    return nil
end

function GetTime()
    return os.time()
end

-- Keep the demo deterministic while respecting Lua's math.random ranges.
-- math.random = function(...)
--     local args = {...}
--     if #args == 0 then
--         return 0.8
--     end
--     if #args == 1 then
--         return 1
--     end
--     return args[1]
-- end

C_Spell = {
    GetSpellInfo = function(spellID)
        return {
            name = "Blessing of Protection"
        }
    end
}