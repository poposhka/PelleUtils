
EverQuestDb = {
    enabled = true,
    bless_triggerchance = 1.0,
    message = "EverQuest ready.",
    color = "|cff00ccff",
    showHelp = true,
}


function main()

    print("running main")

    CreateUnit("Bulbasaur", SEX_MALE, "Dwarf", "Paladin", "Dun Morogh")
    SetUnitState("player", "Bulbasaur")

    SimulateFireEvent("PLAYER_LOGIN", "player")

end