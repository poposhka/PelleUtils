#!/usr/bin/env python3
from pathlib import Path
import argparse

try:
    import lupa
except ImportError as exc:
    raise SystemExit(
        "This script requires the 'lupa' package. Install it with: python -m pip install lupa"
    ) from exc


ROOT = Path(__file__).resolve().parent

def error(text : str):
    print("\033[31m" + text + "\033[0m")

class LuaFixture:
    def __init__(self, addon_path : str, fixture_path : str = None) -> None:
        self.addon_path = Path(addon_path).resolve()
        self.addon_name = self.addon_path.name
        self.fixture_path = Path(fixture_path) if fixture_path else Path(addon_path) / "test_fixture.lua"
        self.LoadAddon()

    def LoadAddon(self):
        self.lua = lupa.LuaRuntime(unpack_returned_tuples=True)
        self.executeLua(open(self.fixture_path).read())
        code = f'''
            -- Lua Simulated WOW entrypoint
            local addonName = "PelleUtils"
            local addon = {{}}
            local chunk = nil
        '''
        toc_path = self.addon_path / f"{self.addon_name}.toc"
        print(f"Loading TOC at '{toc_path}'")
        for line in open(toc_path).readlines():
            if "#" in line:
                line = line[:line.find("#")]
            line = line.strip()
            if not line:
                continue
            file_path = str(ROOT / line).replace('\\', '\\\\')
            code += f'''
            chunk = assert(loadfile("{file_path}"))
            chunk(addonName, addon)
            '''

        # execute the initialization code based on files found
        self.executeLua(code)
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


def main(addon_path : str):
    lua = LuaFixture(addon_path)


    lua.SetUnitState("target", "Mira")


    print("Test sent to valid")
    lua.SimulateEvent("UNIT_SPELLCAST_SENT", "player", "Mira", "spell-guid-lol", 12345)
    lua.executeLua(f'''SlashCmdList["PELLEUTILS"]("say")''')
    lua.executeLua(f'''SlashCmdList["PELLEUTILS"]("say")''')

    print("Test self cast")
    lua.SimulateEvent("UNIT_SPELLCAST_SENT", "player", None, "spell-guid-lol", 12345)
    lua.executeLua(f'''SlashCmdList["PELLEUTILS"]("say")''')

    print("Test unknown cast")
    lua.SimulateEvent("UNIT_SPELLCAST_SENT", "player", None, "spell-guid-lol", 1)
    lua.executeLua(f'''SlashCmdList["PELLEUTILS"]("say")''')

    return

    print("Test untracked event")
    lua.SimulateEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "spell-guid-lol", 12345, "cast-bar-id")

    print("Test sent to valid")
    lua.SimulateEvent("UNIT_SPELLCAST_SENT", "player", "Mira", "spell-guid-lol", 12345)

    print("Test wrong spell landed")
    lua.SimulateEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "wrong-guid-lol", 12345, "cast-bar-id")

    print("Test correct spell landed")
    print("=== this should work ==")
    lua.SimulateEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "spell-guid-lol", 12345, "cast-bar-id")

    print("Test correct spell, but already triggered")
    lua.SimulateEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "spell-guid-lol", 12345, "cast-bar-id")

    print("Test target nothing and cast (self)")
    lua.SetUnitState("target", None)
    lua.SimulateEvent("UNIT_SPELLCAST_SENT", "player", "Bulbasaur", "spell-guid-lolz", 12345)
    lua.SimulateEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "spell-guid-lolz", 12345, "cast-bar-id")

    print("Test triggerset")
    lua.executeLua( f'''
        SlashCmdList["PELLEUTILS"]("trigger")
    ''')

    print("Test triggerset")
    lua.executeLua( f'''
        SlashCmdList["PELLEUTILS"]("trigger 0.7")
    ''')

    print("Test slash")
    lua.executeLua( f'''
        SlashCmdList["PELLEUTILS"]("status")
    ''')

    print("Test slash bad")
    lua.executeLua( f'''
        SlashCmdList["PELLEUTILS"]("ngkjsdlbfg")
    ''')

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("addon_path", help="Path to folder where addon is installed")
    args = ap.parse_args()
    main(args.addon_path)
