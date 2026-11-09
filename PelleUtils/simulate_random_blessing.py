from pathlib import Path
import random

try:
    import lupa
except ImportError as exc:
    raise SystemExit(
        "This script requires the 'lupa' package. Install it with: python -m pip install lupa"
    ) from exc


ROOT = Path(__file__).resolve().parent
CORE_PATH = ROOT / "Core.lua"


def build_lua_runtime():
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)

    lua.execute(
        r'''
        -- Mock API functions used by Core.lua
        
        function UnitName(unit)
            names = {"Borin", "Aeliana", "Tarek", "Mira", "Thorn", "Lysa", "Gorath", "Elandra", "Kael", "Sylvara"}
            realms = {"Stormwind", "Ironforge", "Darnassus", "Orgrimmar", "Undercity", "Thunder Bluff", "Silvermoon", "Exodar"}
            rindex = math.random(1, #realms)
            index = math.random(1, #names)
            return names[index], realms[rindex]
        end

        -- Mock WoW globals used by Core.lua
        DEFAULT_CHAT_FRAME = {
            AddMessage = function(self, msg)
                print(msg)
            end,
        }

        PelleUtilsDB = {
            enabled = true,
            message = "PelleUtils ready.",
            color = "|cff00ccff",
            showHelp = true,
        }

        SlashCmdList = {}

        function CreateFrame(frameType, name, parent, template)
            local frame = {}
            function frame:RegisterEvent(eventName)
                return true
            end
            function frame:SetScript(scriptName, callback)
                return true
            end
            return frame
        end

        function SendChatMessage(message, channel)
            print("[SAY] " .. tostring(message))
        end

        function UnitExists(unit)
            if unit == "target" or unit == "player" then
                return math.random() < 0.5
            end
            return false
        end

        function UnitIsUnit(unitA, unitB)
            return unitA == "target" and unitB == "player"
        end

        function UnitRace(unit)
            if unit == "target" then
                local races = {"Human", "Dwarf", "Night Elf", "Gnome", "Blood Elf", "Orc", "Undead", "Tauren"}
                local idx = math.random(1, #races)
                return races[idx], "dummy\filename", 123
            end
            return "Human"
        end

        function UnitSex(unit)
            if unit == "target" then
                return math.random(1, 3)
            end
            return 2
        end

        -- Make the random roll deterministic enough for simple testing.
        local pyRandom = math.random
        math.random = function(...)
            local args = {...}
            if #args == 0 then
                return 0.8
            end
            if #args == 1 then
                return math.floor(args[1])
            end
            return args[1] + (args[2] - args[1]) * pyRandom()
        end
        '''
    )
    return lua


def load_core(lua):
    code_path = str(CORE_PATH).replace('\\', '\\\\')
    lua.execute(
        f'''
        local chunk = assert(loadfile("{code_path}"))
        local addonName = "PelleUtils"
        local addon = {{}}
        chunk(addonName, addon)
        '''
    )


def demonstrate_self_blessing(lua, count=5):
    
    print("\n=== self blessing demo ===")
    for _ in range(count):
        lua.globals().randomBlessing()


def demonstrate_target_blessing(lua, count=5):
    
    print("\n=== target blessing demo ===")
    for _ in range(count):
        lua.globals().randomBlessing()


def main():
    lua = build_lua_runtime()
    load_core(lua)

    # This prints a few example calls so you can see how the Lua function behaves.
    demonstrate_self_blessing(lua, count=3)
    demonstrate_target_blessing(lua, count=3)


if __name__ == "__main__":
    main()
