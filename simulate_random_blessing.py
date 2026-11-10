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
        self.lua = lupa.LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(open("lua_fixture.lua").read())
        load_core(self.lua)
    mock_UnitName_TargetName = "Mira"
    mock_UnitName_TargetZone = "Stormwind"
    mock_UnitExists_target = True
    mock_UnitIsUnit_target_is_player = True
    mock_UnitRace_racename = "Human"
    mock_UnitSex_target = 2 # 1: Unknown, 2: Man, 3: Woman
    mock_UnitClass_target = "Paladin"
    def configureLua(self):
        self.lua.globals().mock_UnitName_TargetName = LuaFixture.mock_UnitName_TargetName
        self.lua.globals().mock_UnitName_TargetZone = LuaFixture.mock_UnitName_TargetZone
        self.lua.globals().mock_UnitExists_target = LuaFixture.mock_UnitExists_target
        self.lua.globals().mock_UnitIsUnit_target_is_player = LuaFixture.mock_UnitIsUnit_target_is_player
        self.lua.globals().mock_UnitRace_racename = LuaFixture.mock_UnitRace_racename
        self.lua.globals().mock_UnitSex_target = LuaFixture.mock_UnitSex_target
        self.lua.globals().mock_UnitClass_target = LuaFixture.mock_UnitClass_target

    def randomBlessing(self):
        self.lua.globals().randomBlessing()

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
    lua = LuaFixture()
    

    # This prints a few example calls so you can see how the Lua function behaves.
    # demonstrate_self_blessing(lua, count=3)
    # demonstrate_target_blessing(lua, count=3)

    lua.mock_UnitExists_target = True
    lua.mock_UnitIsUnit_target_is_player = True
    lua.mock_UnitRace_racename = "Human"
    lua.configureLua()

    lua.randomBlessing()
    


if __name__ == "__main__":
    main()
