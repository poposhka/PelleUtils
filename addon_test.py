#!/usr/bin/env python3
from pathlib import Path
import argparse


TEST_FIXTURE_CODE = '''


local function generateGuid()
    -- Default to 40 characters (SHA-1 length); use 64 for SHA-256
    length = 40
    local result = {}
    for i = 1, length do
        -- %x formats a random integer (0-15) as a lowercase hex character (0-9, a-f)
        -- Use "%X" if you prefer uppercase hex characters
        result[i] = string.format("%x", math.random(0, 15))
    end
    return table.concat(result)
end

local CLASS_INFO = {
    {"Warrior","WARRIOR", 1},
    {"Paladin","PALADIN", 2},
    {"Hunter","HUNTER", 3},
    {"Rogue","ROGUE", 4},
    {"Priest","PRIEST", 5},
    {"Death Knight","DEATHKNIGHT", 6},
    {"Shaman","SHAMAN", 7},
    {"Mage","MAGE", 8},
    {"Warlock","WARLOCK", 9},
    {"Monk","MONK", 10},
    {"Druid","DRUID", 11},
    {"Demon Hunter","DEMONHUNTER", 12},
    {"Evoker","EVOKER", 13}
}

SEX_UNKNOWN = 1
SEX_FEMALE = 3
SEX_MALE = 2

GameUnits = {}

UnitStates = {
    player = nil,
    target = nil
}

function SetUnitState(unit, name)
    UnitStates[unit] = GameUnits[name]
end


function CreateUnit(name, sex, race, class, zone)
    GameUnits[name] = {
        name = name,
        last = nil,
        sex = sex,
        race = race,
        class = class,
        zone = zone,
        guid = generateGuid()
    }
end


-- mocked API
function UnitTokenFromGUID(guid)
    for unitToken, unit_info in pairs(UnitStates) do
        if unit_info.guid == guid then
            return unitToken
        end
    end
    return nil
end

-- mocked API
function UnitGUID(unit)
    local unit_info = UnitStates[unit]
    if unit_info then
        return unit_info.guid
    end
    return nil
end

-- fake to see printout
function UnitBattlePetSpeciesID(unit)
    return {
        alpha = {
            bravo = 123,
            charlie = "hello there"
        },
        delta = {
            epsilon = {
                pi = 3.14
            },
            tau = 6.28
        },
        gamma = 12.23
    }
end

-- mocked false API
function UnitAuraSlots(a, b)
    b.c = 12
end


-- Mocked WOW API debugging
function debugstack(start, count1, count2)
    start = (start or 1) + 1 -- +1 to skip debugstack itself
    count1 = count1 or 12
    count2 = count2 or 10

    local frames = {}
    local level = start

    while true do
        local info = debug.getinfo(level, "nSl")
        if not info then break end

        local location
        if info.what == "C" then
            location = "[C]"
        elseif info.currentline and info.currentline > 0 then
            location = string.format("%s:%d", info.short_src, info.currentline)
        else
            location = info.short_src
        end

        local func_desc
        if info.name and info.name ~= "" then
            func_desc = string.format("in function '%s'", info.name)
        elseif info.what and info.what ~= "" then
            func_desc = "in <" .. info.what .. "> chunk"
        elseif info.linedefined and info.linedefined > 0 then
            func_desc = string.format("in function <%s:%d>", info.short_src, info.linedefined)
        else
            func_desc = "in ?"
        end

        local frame_text = string.format("%s: %s", location, func_desc)
        -- print("*** " .. frame_text)
        -- print("*** " .. tostring(info.name) .. ", " .. tostring(info.what) .. ", " .. tostring(info.linedefined) )
        frames[#frames + 1] = frame_text
        level = level + 1
    end

    local total = #frames
    if total == 0 then
        return ""
    end

    -- Emulate WoW's top (count1) and bottom (count2) truncation
    if total <= (count1 + count2) then
        return table.concat(frames, "\\n") .. "\\n"
    end

    local out = {}
    for i = 1, count1 do
        out[#out + 1] = frames[i]
    end
    out[#out + 1] = "..."
    for i = total - count2 + 1, total do
        out[#out + 1] = frames[i]
    end

    -- for k,v in ipairs(out) do
    --     print(">>> " .. v)
    -- end

    return table.concat(out, "\\n") .. "\\n"
end


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


-- mocked API SlashCmdList
SlashCmdList = {}

-- Mocked WOW API chat frame
DEFAULT_CHAT_FRAME = {
    AddMessage = function(self, msg)
        print(colors.bold .. colors.yellow .. "[ChatFrame1] " .. colors.reset .. msg)
    end,
    name = "CHAT"
}

-- Mocked globals
ChatFrame1 = DEFAULT_CHAT_FRAME
ChatFrame2 = {
    AddMessage = function(self, msg)
        print(colors.red .. "[ChatFrame2] " .. colors.reset .. msg)
    end,
    name = "ERROR"
}
ChatFrame3 = {
    AddMessage = function(self, msg)
        print(colors.blue .. "[ChatFrame3] " .. colors.reset .. msg)
    end,
    name = "DEBUG"
}

NUM_CHAT_WINDOWS = 3

-- Mocked chat info
function GetChatWindowInfo(index)
    local chat_frame = _G["ChatFrame"..tostring(index)]
    if chat_frame ~= nil then
        return chat_frame.name
    end
    return nil
end

-- Mocked WOW API function to send a chat message
function SendChatMessage(message, channel)
    local sentence = "Player"
    if channel == "SAY" then
        sentence = sentence .. " says:"
    end
    sentence = sentence .. " " .. tostring(message)
    DEFAULT_CHAT_FRAME:AddMessage( colors.yellow .. sentence .. colors.reset)
end

-- get class of the unit
function UnitClass(unit)
    local unit_state = UnitStates[unit]
    if unit_state then
        for i, info in pairs(CLASS_INFO) do
            if info[1] == unit_state.class then
                return unpack(info)
            end
        end
    end
    return nil, nil, nil
end

-- Mocked WOW API function to get (name,zone) of unit
function UnitName(unit)
    local unit_state = UnitStates[unit]
    if unit_state then
        return unit_state.name, unit_state.last
    end
    return nil, nil
end

function GetZoneText()
    return UnitStates.player.zone
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

function UnitFullName(unit)
    local unit_state = UnitStates[unit]
    if unit_state then
        return unit_state.name, unit_state.last
    end
    return nil, nil
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

-- collection of Wow API frames we mock
mockFrames = {}

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

-- event simulator
function SimulateFireEvent(eventName, ...)
    for _, frame in ipairs(mockFrames) do
        frame:SimulateFireEvent(eventName, ...)
    end
end

-- Helper to unpack on older lua
function unpack(table_object)
    return table.unpack(table_object)
end

function GetTime()
    return os.time()
end

function GetClassInfo(class_id)
    return unpack((CLASS_INFO)[class_id] or {nil})
end

C_Spell = {
    GetSpellInfo = function(spellID)
        return ({
            ["12345"] = {
                name = "Blessing of Protection"
            }
        })[tostring(spellID)]
    end
}

-- Lua Simulated WOW entrypoint
local addon = {}
local chunk = nil

'''

try:
    import lupa
except ImportError as exc:
    raise SystemExit(
        "This script requires the 'lupa' package. Install it with: python -m pip install lupa"
    ) from exc

def error(text : str):
    print("\033[31m" + text + "\033[0m")

class LuaFixture:
    def __init__(self) -> None:
        ap = argparse.ArgumentParser()
        ap.add_argument("addon_path", help="Path to folder where addon is installed")
        ap.add_argument("--fixture", help="The test fixture file to use")
        args = ap.parse_args()
        self.addon_path = Path(args.addon_path).resolve()
        self.addon_name = self.addon_path.name
        self.fixture_path = Path(args.fixture).resolve()  if args.fixture else self.addon_path / "test_fixture.lua"
        self.LoadAddon()

    def LoadAddon(self):
        self.lua = lupa.LuaRuntime(unpack_returned_tuples=True)
        self.executeLua(open(self.fixture_path).read())
        code = TEST_FIXTURE_CODE

        toc_path = self.addon_path / f"{self.addon_name}.toc"
        print(f"Loading TOC at '{toc_path}'")
        for line in open(toc_path).readlines():
            if "#" in line:
                line = line[:line.find("#")]
            line = line.strip()
            if not line:
                continue
            file_path = str(self.addon_path / line).replace('\\', '\\\\')
            code += f'''
            chunk = assert(loadfile("{file_path}"))
            chunk("{self.addon_name}", addon)
            '''

        # execute the initialization code based on files found
        self.executeLua(code)

        # run the test fixture main code
        self.lua.globals().main()

    def SimulateLogin(self):
        self.SimulateEvent("PLAYER_LOGIN", "player")

    def executeLua(self, code : str):
        try:
            self.lua.execute(code)
        except BaseException as e:
            error("==== UNHANDLED LUA EXCEPTION ===")
            print(e)
            error("================================")
            exit()

    def SetUnitState(self, unit : str, name : str):
        try:
            self.lua.globals().SetUnitState(unit, name)
        except BaseException as e:
            error("==== UNHANDLED LUA EXCEPTION ===")
            print(e)
            error("================================")
            exit()

    def SimulateEvent(self, event_name : str, *args : list[str]):
        try:
            self.lua.globals().SimulateFireEvent(event_name, *args)
        except BaseException as e:
            error("==== UNHANDLED LUA EXCEPTION ===")
            print(e)
            error("================================")
            exit()

    def randomBlessing(self):
        self.SimulateEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "spell-guid-lol", 12345, "cast-bar-id")


if __name__ == "__main__":
    lua = LuaFixture()
