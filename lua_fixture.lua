mockFrames = {}
mock_UnitName_TargetName = "Mira"
mock_UnitName_TargetZone = "Stormwind"
mock_UnitExists_target = true
mock_UnitIsUnit_target_is_player = true
mock_UnitRace_racename = "Human"
mock_UnitSex_target = 2 -- 1: Unknown, 2: Man, 3: Woman
mock_UnitClass_target = "Warrior"


-- Mocked WOW API chat frame
DEFAULT_CHAT_FRAME = {
    AddMessage = function(self, msg)
        print(msg)
    end,
}

PelleUtilsDB = {
    enabled = true,
    bless_triggerchance = 1.0,
    message = "PelleUtils ready.",
    color = "|cff00ccff",
    showHelp = true,
}

SlashCmdList = {}

-- Mocked WOW API function to get (name,zone) of unit
function UnitName(unit)
    if unit == "target" then
        return mock_UnitName_TargetName, mock_UnitName_TargetZone
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

    function frame:SetScript(scriptName, callback)
        self.scripts[scriptName] = callback
    end

    function frame:FireEvent(eventName)
        local callback = self.scripts.OnEvent
        if callback and string.find(self.event, "|" .. eventName .. "|") then
            callback(self, eventName)
        end
    end
    table.insert(mockFrames, frame)
    return frame
end

function UnitGUID(unit)
    if unit == "player" then
        return "_player_guid_"
    end
    return nil
end

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
    print("[SAY] " .. tostring(message))
end

-- Mocked WOW API function to check if unit exists
function UnitExists(unit)
    if unit == "target" then
        return mock_UnitExists_target
    elseif unit == "player" then
        return true
    end
    return false
end

-- Mocked WOW API function checking if unitA is unitB
function UnitIsUnit(unitA, unitB)
    if unitA == "target" and UnitB == "player" then
        return mock_UnitIsUnit_target_is_player
    else
        return false
    end
end

-- Mocked WOW API function to check race of unit
-- returns: racename_localized, racename_english, raceid
function UnitRace(unit)
    if unit == "target" then
        return mock_UnitRace_racename, "Human", 123
    end
    return nil, nil, nil
end

-- Mocked WOW API function to check sex of unit
-- returns: 1=unknown/neutral 2=male 3=female
function UnitSex(unit)
    if unit == "target" then
        return mock_UnitSex_target
    end
    return nil
end

function UnitClass(unit)
    if unit == "target" then
        return mock_UnitClass_target, "fake/filename", 123
    end
    return nil
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