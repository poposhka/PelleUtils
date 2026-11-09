from pathlib import Path

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
        mockFrames = {}
        mockTargetExists = false
        mockTargetIsPlayer = false
        mockTargetName = "Mira"
        mockTargetRace = "Human"
        mockTargetSex = 2

        function UnitName(unit)
            if unit == "target" then
                return mockTargetName, "Stormwind"
            end
            return "Borin", "Stormwind"
        end

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
            local frame = { scripts = {} }
            function frame:RegisterEvent(eventName)
                self.event = eventName
            end
            function frame:SetScript(scriptName, callback)
                self.scripts[scriptName] = callback
            end
            function frame:FireEvent(eventName)
                local callback = self.scripts.OnEvent
                if callback and eventName == self.event then
                    callback(self, eventName)
                end
            end
            table.insert(mockFrames, frame)
            return frame
        end

        function SendChatMessage(message, channel)
            print("[SAY] " .. tostring(message))
        end

        function UnitExists(unit)
            if unit == "target" then
                return mockTargetExists
            elseif unit == "player" then
                return true
            end
            return false
        end

        function UnitIsUnit(unitA, unitB)
            return unitA == "target" and unitB == "player" and mockTargetIsPlayer
        end

        function UnitRace(unit)
            if unit == "target" then
                return mockTargetRace, "Human", 123
            end
            return "Human"
        end

        function UnitSex(unit)
            if unit == "target" then
                return mockTargetSex
            end
            return 2
        end

        -- Keep the demo deterministic while respecting Lua's math.random ranges.
        math.random = function(...)
            local args = {...}
            if #args == 0 then
                return 0.8
            end
            if #args == 1 then
                return 1
            end
            return args[1]
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
        for _, frame in ipairs(mockFrames) do
            frame:FireEvent("PLAYER_LOGIN")
        end
        '''
    )


def demonstrate_self_blessing(lua, count=5):
    print("\n=== self blessing demo ===")
    lua.globals().mockTargetExists = True
    lua.globals().mockTargetIsPlayer = True
    for _ in range(count):
        lua.globals().randomBlessing()


def demonstrate_target_blessing(lua, count=5):
    print("\n=== target blessing demo ===")
    lua.globals().mockTargetExists = True
    lua.globals().mockTargetIsPlayer = False
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
