#!/usr/bin/env python3
from pathlib import Path

try:
    import lupa
except ImportError as exc:
    raise SystemExit(
        "This script requires the 'lupa' package. Install it with: python -m pip install lupa"
    ) from exc


ROOT = Path(__file__).resolve().parent
CORE_PATH = ROOT / "Core.lua"
UTIL_PATH = ROOT / "Util.lua"

def error(text : str):
    print("\033[31m" + text + "\033[0m")


def executeLua(lua, code):
    try:
        lua.execute(code)
    except BaseException as e:
        error("==== UNHANDLED LUA EXCEPTION ===")
        print(e)
        error("================================")
        exit()

class LuaFixture:
    def __init__(self) -> None:
        self.LoadAddon()

    def LoadAddon(self):
        self.lua = lupa.LuaRuntime(unpack_returned_tuples=True)
        executeLua(self.lua, open("lua_fixture.lua").read())
        load_core(self.lua)

    def SetUnitState(self, unit : str, name : str):
        try:
            self.lua.globals().SetUnitState(unit, name)
        except BaseException as e:
            error("==== UNHANDLED LUA EXCEPTION ===")
            print(e)
            error("================================")
            exit()


    def SimulateEvent(self, event_name : str, *args):
        argument_string = [f'"{event_name}"']
        for arg in args:
            if isinstance(arg, str):
                argument_string += [f'"{arg}"']
            else:
                argument_string += [f'{arg}']

        argument_string = ", ".join(argument_string)
        print("Simulating Event: ", argument_string)

        executeLua(self.lua,
            f'''
            for _, frame in ipairs(mockFrames) do
                frame:SimulateFireEvent({argument_string})
            end
            ''')

    def randomBlessing(self):
        #self.lua.globals().randomBlessing()
        executeLua(self.lua,
            f'''
            for _, frame in ipairs(mockFrames) do
                frame:SimulateFireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "spell-guid-lol", 12345, "cast-bar-id")
            end
            ''')

def load_core(lua):
    util_path = str(UTIL_PATH).replace('\\', '\\\\')
    core_path = str(CORE_PATH).replace('\\', '\\\\')
    executeLua(lua,
        f'''
        local addonName = "PelleUtils"
        local addon = {{}}

        local chunk = assert(loadfile("{util_path}"))
        chunk(addonName, addon)

        chunk = assert(loadfile("{core_path}"))
        chunk(addonName, addon)

        for _, frame in ipairs(mockFrames) do
            frame:SimulateFireEvent("PLAYER_LOGIN", "player", "Mira", "spell-guid-lol", 12345)
        end
        '''
    )


def main():
    lua = LuaFixture()

    lua.SetUnitState("target", "Mira")

    # test untracked event
    lua.SimulateEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "spell-guid-lol", 12345, "cast-bar-id")

    # test sent to valid
    lua.SimulateEvent("UNIT_SPELLCAST_SENT", "player", "Mira", "spell-guid-lol", 12345)

    # wrong spell landed
    lua.SimulateEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "wrong-guid-lol", 12345, "cast-bar-id")

    # correct spell landed
    print("=== this should work ==")
    lua.SimulateEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "spell-guid-lol", 12345, "cast-bar-id")

    # correct spell, but already triggered
    lua.SimulateEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "spell-guid-lol", 12345, "cast-bar-id")

    # target nothing and cast (self)
    lua.SetUnitState("target", None)
    lua.SimulateEvent("UNIT_SPELLCAST_SENT", "player", "Bulbasaur", "spell-guid-lolz", 12345)
    lua.SimulateEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "spell-guid-lolz", 12345, "cast-bar-id")


if __name__ == "__main__":
    main()
