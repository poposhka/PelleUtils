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
frame:SetScript("OnEvent", function(self, event)
    if event ~= "PLAYER_LOGIN" then
        return
    end

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
    elseif variable == "name" then
        return UnitName("target") or "friend"
    elseif variable == "race" then
        return UnitRace("target") or "stranger"
    elseif variable == "protection" then
        return "guide|bless|protect|guard|shield|watch over"
    else
        return variable
    end
end

local function handleFragment(fragment, start, endchar)
    start = start or 1
    endchar = endchar or nil
    endindex = #fragment
    local result = ""
    local i = start
    while i <= #fragment do
        local char = string.sub(fragment, i, i)
        if char == "(" then
            local innerfragment, endfrag = handleFragment(fragment, i + 1, ")")
            local options = split(innerfragment, "|")
            local choice = RandomChoice(options)
            result = result .. choice
            i = endfrag
        elseif char == "{" then
            local options, endfrag = handleFragment(fragment, i + 1, "}")
            local choice = RandomChoice(options)
            options = handleVariable(choice)
            choice = RandomChoice(options)
            result = result .. choice
            i = endfrag
        elseif char == endchar then
            endindex = i
            break
        else
            result = result .. char
        end
        i = i + 1
    end
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

    -- may the Light guide you Human
    a = "(may the |eternal |Glory of |)light {protection} you(, {sibling}|, {race}|, {name}|)."
    a = "(blessed |holy |sacred |eternal |)light, {protection} (this {race}|our {sibling} {name})(, and guide their hand in battle|)."
    result = handleFragment(a)


    if true then return capitalize(result) end

    local descriptor = RandomChoice({
        "the steadfast " .. race,
        "this noble " .. race,
        "the brave " .. race,
        "the " .. race .. " soul",
    })

    local blessing = RandomChoice({
        "with courage and mercy.",
        "with purpose and resolve.",
        "toward a brighter dawn.",
        "and keep your heart true.",
    })

    local dwarfQuip = RandomChoice({
        "I, a dwarf paladin of the Light, call this blessing in your name.",
        "The Light is my vow, and I offer it gladly.",
        "By my faith and my forge, may the Light stand with you.",
        "A dwarf of the Light speaks for honor and mercy.",
    })

    local classFragment = RandomChoice(addon.ClassBlessingFragments)
    local quip
    if classFragment and classFragment ~= "" then
        quip = classFragment
    else
        quip = dwarfQuip
    end

    if gender == "woman" then
        gender = "sister"
    elseif gender == "man" then
        gender = "brother"
    else
        gender = "friend"
    end

    return string.format("%s %s, my %s, %s, %s %s", intro, name, gender, descriptor, blessing, quip)
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