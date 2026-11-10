local addonName, addon = ...

addon.Name = addonName
addon.Version = "0.1.0"
addon.Defaults = {
    enabled = true,
    bless_triggerchance = 0.5,
    message = "PelleUtils ready.",
    color = "|cff00ccff",
    showHelp = true,
}


local function split(text, separator)
    local parts = {}
    -- Escape punctuation characters to treat them as literal characters
    local pattern = "(.-)" .. separator:gsub("%p", "%%%0")

    -- Append the separator to guarantee the trailing empty string is caught
    for part in (text .. separator):gmatch(pattern) do
        table.insert(parts, part)
    end
    return parts
end


local function Trim(value)
    if value == nil then
        return ""
    end

    return tostring(value):match("^%s*(.-)%s*$")
end

local function MergeDefaults(defaults, saved)
    local merged = {}

    for key, value in pairs(defaults) do
        merged[key] = value
    end

    if type(saved) == "table" then
        for key, value in pairs(saved) do
            merged[key] = value
        end
    end

    return merged
end

local function Save()
    if type(addon.db) == "table" then
        PelleUtilsDB = addon.db
    end
end

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage((addon.db and addon.db.color or "|cff00ccff") .. "[PelleUtils]|r " .. tostring(message))
end

local function ToggleEnabled()
    addon.db.enabled = not addon.db.enabled
    Save()
    Print(addon.db.enabled and "Enabled." or "Disabled.")
end

local function HandleSlashCommand(msg)
    local command = Trim(msg or ""):lower()

    if command == "toggle" then
        ToggleEnabled()
        return
    end

    if command == "status" then
        Print("Status: " .. (addon.db.enabled and "enabled" or "disabled"))
        return
    end

    if command == "say" then
        Print(addon.db.message)
        return
    end

    if command == "blessing" then
        randomBlessing()
        return
    end

    if command == "help" or command == "" then
        Print("Usage: /pu toggle | /pu status | /pu say | /pu blessing | /pu help")
        return
    end

    Print("Unknown command. Use /pu help")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
--frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

frame:SetScript("OnEvent", function(self, event)
    

    print(self)
    if event == "PLAYER_LOGIN" then

        PelleUtilsDB = PelleUtilsDB or {}
        addon.db = MergeDefaults(addon.Defaults, PelleUtilsDB)
        addon.db.message = addon.db.message or addon.Defaults.message
        addon.db.enabled = addon.db.enabled ~= false
        addon.db.bless_triggerchance = addon.db.bless_triggerchance or addon.Defaults.bless_triggerchance
        addon.db.color = addon.db.color or addon.Defaults.color
        addon.db.showHelp = addon.db.showHelp ~= false
        PelleUtilsDB = addon.db

        Print("Version " .. addon.Version .. " loaded.")
        Print(addon.db.message)

    -- Filter: Only run if a spell successfully finished casting
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID = CombatLogGetCurrentEventInfo()
        if subEvent == "SPELL_CAST_SUCCESS" then

            -- Filter: Ensure the player is the one who cast it, AND it wasn't cast on themselves
            if sourceGUID == UnitGUID("player") and destGUID ~= UnitGUID("player") then

                -- Filter: Verify the spell cast is your specific buff/boon
                local spellInfo = C_Spell.GetSpellInfo(spellID)
                local spellName = spellInfo and spellInfo.name

                -- Replace "Power Infusion" with whatever boon/blessing spell you track
                if spellName == "Power Infusion" or spellName == "Blessing of Protection" then

                    randomBlessing()
                end
            end
        end -- subEvent == "SPELL_CAST_SUCCESS"
    end -- event COMBAT_LOG_EVENT_UNFILTERED
end)


SLASH_PELLEUTILS1 = "/pu"
SLASH_PELLEUTILS2 = "/pelleutils"
SlashCmdList["PELLEUTILS"] = HandleSlashCommand

addon.ClassBlessingFragments = addon.ClassBlessingFragments or {}

function addon:RegisterClassBlessingFragments(fragments)
    if type(fragments) ~= "table" then
        return
    end

    for _, fragment in ipairs(fragments) do
        if type(fragment) == "string" and fragment ~= "" then
            table.insert(self.ClassBlessingFragments, fragment)
        end
    end
end

function RegisterClassBlessingFragments(fragments)
    return addon:RegisterClassBlessingFragments(fragments)
end

-- 
local function RandomChoice(list)

    if type(list) == "string" then
        local options = split(list, "|")
        return options[math.random(1, #options)]
    end

    if type(list) ~= "table" or #list == 0 then
        return ""
    end

    local weightedChoices = {}
    local totalWeight = 0

    for _, entry in ipairs(list) do
        local weight = 1
        local value = ""

        if type(entry) == "string" then
            value = entry
        elseif type(entry) == "table" then
            if type(entry.weight) == "number" then
                weight = entry.weight
            elseif type(entry[1]) == "number" then
                weight = entry[1]
            end

            if type(entry.text) == "string" then
                value = entry.text
            elseif type(entry.value) == "string" then
                value = entry.value
            elseif type(entry[2]) == "string" then
                value = entry[2]
            elseif type(entry[1]) == "string" then
                value = entry[1]
            end
        end

        if type(value) == "string" then
            weight = tonumber(weight) or 1
            if weight <= 0 then
                weight = 1
            end

            totalWeight = totalWeight + weight
            table.insert(weightedChoices, { weight = weight, value = value })
        end
    end

    if #weightedChoices == 0 then
        return ""
    end

    if totalWeight <= 0 then
        return weightedChoices[math.random(1, #weightedChoices)].value
    end

    local roll = math.random() * totalWeight
    local cursor = 0

    for _, choice in ipairs(weightedChoices) do
        cursor = cursor + choice.weight
        if roll <= cursor then
            return choice.value
        end
    end

    return weightedChoices[#weightedChoices].value
end

local function GetTargetProfile()
    if not UnitExists("target") then
        return nil
    end

    local race = UnitRace("target") or "unknown"
    local gender = "person"
    if UnitSex("target") == 2 then
        gender = "woman"
    elseif UnitSex("target") == 3 then
        gender = "man"
    end

    return {
        race = race,
        gender = gender,
        name = UnitName("target") or "friend",
    }
end

local function BuildSelfBlessing()
    local opening = RandomChoice({
        "By the Light,",
        "In the name of the Light,",
        "The Light keeps me steadfast,",
        "With the Light in my heart,",
    })

    local action = RandomChoice({
        "I stand stronger",
        "I feel my courage rise",
        "my spirit grows steadier",
        "my faith burns brighter",
    })

    local closure = RandomChoice({
        "and the hammer of my vows is true.",
        "and I am ready to defend the innocent.",
        "and the fury of my conviction is guided by mercy.",
        "and the path ahead is clear.",
    })

    local dwarfQuip = RandomChoice({
        "I am a dwarf paladin of the Light.",
        "A dwarf heart beats true in service to the Light.",
        "The Light has shaped my steel and my soul.",
        "I stand as a dwarf defender, unwavering in the Light.",
    })

    local classFragment = RandomChoice(addon.ClassBlessingFragments)
    if classFragment and classFragment ~= "" then
        return string.format("%s %s %s %s", opening, action, closure, classFragment)
    end

    return string.format("%s %s %s %s", opening, action, closure, dwarfQuip)
end

local function isParen(text)
    return string.match(text, "^%(.+%)$")
end


local function isBracket(text)
    if string.match(text, "^%{.+%}$") then
        return true
    end
end

local function capitalize(str)
    if str == nil or str == "" then return "" end
    return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2)
end

local function handleVariable(variable)
    if variable == "sibling" then
        local gender = UnitSex("target")
        if gender == 2 then
            return "sister"
        elseif gender == 3 then
            return "brother"
        else
            return "friend"
        end
    elseif variable == "3p_pronoun" then
        local gender = UnitSex("target")
        if gender == 2 then
            return "her"
        elseif gender == 3 then
            return "him"
        else
            return "them"
        end
    elseif variable == "3p_pronoun_poss" then
        local gender = UnitSex("target")
        if gender == 2 then
            return "hers"
        elseif gender == 3 then
            return "his"
        else
            return "their"
        end
    elseif variable == "possessive_adjective" then
        return "(your|thine)"
    elseif variable == "name" then
        return UnitName("target") or "friend"
    elseif variable == "race" then
        return UnitRace("target") or "stranger"
    elseif variable == "protection_active" then
        return "(guide|bless|protect|guard|shield|watch over)"
    elseif variable == "class" then
        return UnitClass("target") or "Hero"
    elseif variable == "title" then
        return "(({sibling} |){name}|{race}|{class})"
    elseif variable == "light" then
        return "(blessed |holy |sacred |eternal |glorious |)light"
    elseif variable == "blessing" then
        return "(boon|blessing|benediction|grace|gift|favor|grace|mercy)"
    elseif variable == "class_asset" then
        local class = (UnitClass("target") or "Hero"):lower()
        local switch = {
            ["warrior"] = "(arm|fist|blade)",
            ["priest"] = "soul",
            ["paladin"] = "heart",
            ["rogue"] = "senses",
            ["warlock"] = "ways",
            ["mage"] = "mind",
            ["druid"] = "spirit",
            ["hunter"] = "step",
            ["shaman"] = "ancestors",
        }
        return switch[class] or "body"
    elseif variable == "class_attribute" then
        local class = (UnitClass("target") or "Hero"):lower()
        local switch = {
            ["warrior"] = "(true|courageous|brave|strong|fierce|unyielding|honorable)",
            ["priest"] = "(true|faithful|with the light)",
            ["paladin"] = "(true|courageous|brave|strong|fierce|unyielding|faithful|with the light)",
            ["rogue"] = "(cunning|fierce|deadly)",
            ["warlock"] = "(cunning|courageous)",
            ["mage"] = "(brilliant|courageous)",
            ["druid"] = "(true|resolute)",
            ["hunter"] = "(swift|true|straight)",
            ["shaman"] = "(true|faithful|honorable)",
        }
        return switch[class] or "true"
    elseif variable == "class_weapon" then
        local class = (UnitClass("target") or "Hero"):lower()
        local switch = {
            ["warrior"] = "(axe|sword|hammer)",
            ["priest"] = "(faith|healing|heart)",
            ["paladin"] = "(courage|pure heart|hammer)",
            ["rogue"] = "(blades|cunning ways|instincts)",
            ["warlock"] = "(magicks|unholy acts|connection to the nether)",
            ["mage"] = "(brilliance|magicks|arcana|fire and frost)",
            ["druid"] = "(connection to nature|strength of spirit|bond with nature)",
            ["hunter"] = "(sharp arrows|bow and companion|instincts)",
            ["shaman"] = "(ancestors|ancestral bond|connection to the earth)",
        }
        return switch[class] or "courage"
    else
        return variable
    end
end
tabs = 0
local function handleFragment(fragment, start, endchar)
    tabs = tabs + 1
    start = start or 1
    endchar = endchar or nil
    endindex = #fragment
    local result = ""
    local i = start
    while i <= #fragment do
        local char = string.sub(fragment, i, i)
        if char == "(" then
            -- Optiontext (choice|choice) is evaluated on options once
            -- we advance i to the end of the subfragment
            local inner, inner_end = handleFragment(fragment, i + 1, ")")
            inner = RandomChoice(inner)
            result = result .. inner
            i = inner_end
        elseif char == "{" then
            -- evaluating a variable must be evaluated again as its contents may be formatting
            local inner, inner_end = handleFragment(fragment, i + 1, "}")
            -- first select optional variable {foo|bar|baz}
            inner = RandomChoice(inner)
            -- now evaluated the chosen variable
            inner = handleVariable(inner)
            -- now, handle that as a unique fragment in case the variable yielded nested fragments
            inner = handleFragment(inner)
            -- finally it will have been recursively resolved
            result = result .. inner
            i = inner_end
        elseif char == endchar then
            tabs = tabs - 1
            return result, i
        else
            result = result .. char
        end
        i = i + 1
    end
    tabs = tabs - 1
    return result, endindex
end

local function BuildTargetBlessing(target)
    local race = target.race or "unknown"
    local gender = target.gender or "person"
    local name = target.name or "friend"

    -- (text) 50% chance to occur
    -- {sibling} sister/brother/""
    -- {name} name of target
    -- {race} race of target
    -- | in {race|name} will pick one 50/50
    local phrases = {}
    -- may the Light guide you Human
    --table.insert(phrases, "(may the |eternal |Glory of |)light {protection_active} you(, {sibling}|, {race}|, {name}|).")


    local result = ""

    -- Intro - the character bestows a blessing --
    local intro = math.random(1,3)
    pronoun = ""
    if intro == 1 then
        result = capitalize(handleFragment("{light}, {protection_active} (this {race}|our {sibling} {name}|this {class}|{name} the {class})"))
        pronoun = "{3p_pronoun}"
    elseif intro == 2 then
        result = capitalize(handleFragment("{title}, take (this|my|a) {blessing} of (the |our |){light}"))
        pronoun = "{possessive_adjective}"
    else
        result = capitalize(handleFragment("Let me {bless|benedict|pray for} you, {title}, for victory"))
        pronoun = "{possessive_adjective}"
    end


    -- pick a middle 0 is none
    local middle = math.random(0, 3)
    -- pick an ending
    local ending = math.random(0, 3)

    -- join with "and" if we have middle and ending
    local join = "."
    if middle ~= 0 and ending ~= 0 then
        join = ", and "
    elseif middle == 0 then
        join = ""
    end

    if middle == 1 then
        result = result .. ". " .. capitalize(handleFragment("(always |forever |)stand {class_attribute}(, {name}|)"))
    elseif middle == 2 then
        result = result .. ". " ..capitalize(handleFragment("never (relent|surrender|lose faith|buckle|lose hope|give up|kneel|hesitate)(, {name}|)"))
    elseif middle == 3 then
        result = result .. ". " ..capitalize(handleFragment("(i|we|you must) (feel|trust|believe) the {light} in you(, {name}|)"))
    end

    result = result .. join

    local endtext = ""
    if ending == 1 then
        endtext = handleFragment("(make it|let it|allow it to|to) (bolster|aid|guide|lead|help|strengthen) " .. pronoun .. " {class_asset} (to victory|in battle|against the Horde)!")
    elseif ending == 2 then
        endtext = handleFragment("(never stray from|have faith in|trust) the {light}!")
    elseif ending == 3 then
        endtext = handleFragment("may your {class_weapon} bring (death to|victory over|devastation to) (the horde|our enemies)!")
    end

    if endtext and join == "" then
        endtext = ". " .. capitalize(endtext)
    end

    result = result .. endtext

    return result
end

function randomBlessing()
    if addon.db and addon.db.enabled == false then
        return
    end

    if math.random() > addon.db.bless_triggerchance then
        return
    end

    local target = GetTargetProfile()

    if UnitIsUnit("target", "player") then
        local sentence = BuildSelfBlessing()
        SendChatMessage(sentence, "SAY")
        return
    end

    if target then
        local sentence = BuildTargetBlessing(target)
        SendChatMessage(sentence, "SAY")
    end
end

addon.Print = Print
addon.ToggleEnabled = ToggleEnabled
addon.HandleSlashCommand = HandleSlashCommand
addon.randomBlessing = randomBlessing

if addon.db then
    addon.db.enabled = addon.db.enabled ~= false
end