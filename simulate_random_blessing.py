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


class LuaFixture:
    def __init__(self) -> None:
        self.LoadAddon()

    def LoadAddon(self):
        self.lua = lupa.LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(open("lua_fixture.lua").read())
        load_core(self.lua)

    def SetUnitState(self, unit : str, name : str):
        self.lua.globals().SetUnitState(unit, name)


    def SimulateEvent(self, event_name : str, *args):
        argument_string = [f'"{event_name}"']
        for arg in args:
            if isinstance(arg, str):
                argument_string += [f'"{arg}"']
            else:
                argument_string += [f'{arg}']

        argument_string = ", ".join(argument_string)
        print("Simulating Event: ", argument_string)
        self.lua.execute(
            f'''
            for _, frame in ipairs(mockFrames) do
                frame:SimulateFireEvent({argument_string})
            end
            ''')

    def randomBlessing(self):
        #self.lua.globals().randomBlessing()
        self.lua.execute(
            f'''
            for _, frame in ipairs(mockFrames) do
                frame:SimulateFireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "spell-guid-lol", 12345, "cast-bar-id")
            end
            ''')

def load_core(lua):
    code_path = str(CORE_PATH).replace('\\', '\\\\')
    lua.execute(
        f'''
        local chunk = assert(loadfile("{code_path}"))
        local addonName = "PelleUtils"
        local addon = {{}}
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
    lua.SimulateEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "spell-guid-lol", 12345, "cast-bar-id")

    # correct spell, but already triggered
    lua.SimulateEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "spell-guid-lol", 12345, "cast-bar-id")

    # target nothing and cast (self)
    lua.SetUnitState("target", None)
    lua.SimulateEvent("UNIT_SPELLCAST_SENT", "player", "Bulbasaur", "spell-guid-lolz", 12345)
    lua.SimulateEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "spell-guid-lolz", 12345, "cast-bar-id")


if __name__ == "__main__":
    main()
