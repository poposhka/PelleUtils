local addonName, BlessMeisterAddon = ...

-- Spell phrases are in the following format
--      Exclamation! Main Phrase. Conclusion, and final bit.
--  Exclamation:
--      This is optional and should represent the caster's race and class and the action
--          e.g. "By the light!", "Stone and Steel!", "By Cenarius Fur!", "For Orgrim!"
--  Main Phrase:
--      This is mandatory, and should describe the action.
--          e.g. "This will strenghten you, Paladin", "Go with the Light, Mira", "You will not die on my watch"


local emotes = {
    "seems (focused|deep|concentrated) in prayer",
    "(stretches|reaches|lifts|holds) {possessive_pronoun:player} (head|shield|weapon) towards the (heavens|light|sky)",
    "(chants|mumbles|says|whispers) a prayer[ under {possessive_pronoun:player} breath][ for {pronoun:player}self]",
    "touches (the ground|{possessive_pronoun:player} (heart|shield|sword))",
    "(focuses|closes) {possessive_pronoun:player} eyes"
}

local exclamations = {
    "by (the light|the [ancestors ](forge|brew|mountain)|my [ancestors ][long ]beard)",
    "by [dwarves and |earth and |mountain and |stone and ](steel|light|hearth)",
    "(stone and steel|hammer and hearth|storm and sky)",
    "(hear me|listen up), (gods|ancestors)",
    "by the (ancestors|forge|mountain|iron|steel)",
    "for (the High Seat|Khaz Modan|Bronzebeard|The Alliance|Falstad's Gryphon)",
    "by {dwarf_legends}['s (hammer|beard|shield)]"
}

local blessings_self = {
    "may this {strengthen} me[ in battle| against the sourge]!",
    "{strengthen} my (steel|hand|arm|shield|weapon), {light}!",
    "i must (hold fast|be strong|have courage|press on)!"
}

BlessMeisterAddon:RegisterLexicon("Dwarf", "Paladin",
{

    { -- generic blessing type
        name = "Generic Blessings",
        matches = {"Blessing of"},
        emotes = emotes,
        exclamations = exclamations,
        main_text_self = blessings_self

    },
    { -- specific for Blessing of Protection
        name = "Blessing of Protection",
        matches = {"Blessing of Protection"},
        emotes = emotes,
        exclamations = exclamations,
        main_text_self = blessings_self
    }
})