
-- Mocked SavedVariable with triggerchance at 1.0
PelleUtilsDB = {
    enabled = true,
    bless_triggerchance = 1.0,
    message = "PelleUtils ready.",
    color = "|cff00ccff",
    showHelp = true,
}


function main()

    print("running main")

    CreateUnit("Bulbasaur", SEX_MALE, "Dwarf", "Paladin", "Dun Morogh")
    CreateUnit("Mira", SEX_FEMALE, "Human", "Warlock", "Stormwind City")
    SetUnitState("player", "Bulbasaur")

    SimulateFireEvent("PLAYER_LOGIN", "player")

end