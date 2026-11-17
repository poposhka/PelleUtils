#!/usr/bin/env python3
import addon_test



def main():
    lua = addon_test.LuaFixture()

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
    main()
