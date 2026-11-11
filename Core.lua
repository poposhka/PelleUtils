local addonName, BlessMeisterAddon = ...

-- Note that we use the SavedVariable PelleUtilsDB

-- Helper to get caller function name
local function FuncName()
    -- Start at stack depth 3 (1 = this function, 2 = current function, 3 = caller)
    local stack = debugstack(3, 1, 0)
    -- Extract the function name inside single quotes: in function 'FunctionName'
    local file, line, func = stack:match("([^\\/:]+):(%d+): in function '([^']+)'")
    if not line then
        file, line = stack:match("([^\\/:]+):(%d+):")
        func = "anonymous"
    end
    return file..":"..line..":"..func
    
end

-- Helper function to split a string
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

-- Helper function to capitalize the first letter in a string
local function capitalize(str)
    if str == nil or str == "" then return "" end
    return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2)
end

-- Helper function to trim whitespace from a string
local function Trim(value)
    if value == nil then
        return ""
    end
    return tostring(value):match("^%s*(.-)%s*$")
end

-- Helper function to merge defaults into a saved table
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

-- Choose randomly from the items in the list or string
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


-- Our AddOn Class

function BlessMeisterAddon:init(addonName)
    self.Name = addonName
    self.Version = "0.1.0"
    self.Defaults = {
        enabled = true,
        bless_triggerchance = 0.5,
        message = "PelleUtils ready.",
        color = "|cff00ccff",
        showHelp = true,
    }
    self.tabs = 0
    self.current_target = "target"
    self.spell_queue = {}

    self.UNIT_TOKENS = {
        "target", "mouseover", "focus", "player"
    }
    for n = 1, 4 do
        table.insert(self.UNIT_TOKENS, "party" .. n)
    end
    for n = 1, 40 do
        table.insert(self.UNIT_TOKENS, "raid" .. n)
    end
    for n = 1, 4 do
        table.insert(self.UNIT_TOKENS, "arena" .. n)
    end


    self.frame = CreateFrame("Frame")
    self.frame:RegisterEvent("PLAYER_LOGIN")
    self.frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    self.frame:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")
    self.frame:SetScript("OnEvent", function(frame, ...) self:OnEvent(...) end)
end

function BlessMeisterAddon:OnEvent(event, ...)
    self:debug(event)

    if event == "PLAYER_LOGIN" then
        self:OnPlayerLoginEvent(...)

    elseif event == "UNIT_SPELLCAST_SENT" then
        self:OnUnitSpellcastSent(...)

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        self:OnUnitSpellcastSucceeded(...)

    end
end

function BlessMeisterAddon:OnPlayerLoginEvent(...)
    -- intialize the savedvariable
    PelleUtilsDB = PelleUtilsDB or {}
    self.db = MergeDefaults(self.Defaults, PelleUtilsDB)
    self.db.message = self.db.message or self.Defaults.message
    self.db.enabled = self.db.enabled ~= false
    self.db.bless_triggerchance = self.db.bless_triggerchance or self.Defaults.bless_triggerchance
    self.db.color = self.db.color or self.Defaults.color
    self.db.showHelp = self.db.showHelp ~= false
    PelleUtilsDB = self.db


    SLASH_PELLEUTILS1 = "/pu"
    SLASH_PELLEUTILS2 = "/pelleutils"
    SlashCmdList["PELLEUTILS"] = HandleSlashCommand

    self:Print("Version " .. self.Version .. " loaded.")
    self:Print(self.db.message)
end

-- Helper to identify a unit token by name
function BlessMeisterAddon:whichUnit(unit_name)
    if unit_name == nil then
        return nil
    end

    for _, token in ipairs(self.UNIT_TOKENS) do
        if UnitName(token) == unit_name then
            return token
        end
    end
    return nil
end

-- Helper function to print debug info text to the user
function BlessMeisterAddon:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage((self.db and self.db.color or "|cff00ccff") .. "[".. self.Name .."]|r " .. tostring(message))
end

function BlessMeisterAddon:debug(message, ...)
    local text = tostring(message):format(...)
    DEFAULT_CHAT_FRAME:AddMessage("["..FuncName().."] " .. text)
end

-- Helper function to save our settings
function BlessMeisterAddon:Save()
    if type(self.db) == "table" then
        PelleUtilsDB = self.db
    end
end

-- Toggle the enabled value
function BlessMeisterAddon:ToggleEnabled()
    self.db.enabled = not self.db.enabled
    self:Save()
    self:Print(self.db.enabled and "Enabled." or "Disabled.")
end

function BlessMeisterAddon:HandleSlashCommand(msg)
    -- normalize it
    local command = Trim(msg or ""):lower()

    if command == "toggle" then
        self:ToggleEnabled()
        return
    end

    if command == "status" then
        self:Print("Status: " .. (self.db.enabled and "enabled" or "disabled"))
        return
    end

    if command == "say" then
        self:Print(self.db.message)
        return
    end

    if command == "blessing" then
        self:randomBlessing("target")
        return
    end

    if command == "help" or command == "" then
        self:Print("Usage: /pu toggle | /pu status | /pu say | /pu blessing | /pu help")
        return
    end

    self:Print("Unknown command. Use /pu help")
end

function BlessMeisterAddon:OnUnitSpellcastSucceeded(unitCaster, castGUID, spellID, castBarID)

    if unitCaster ~= "player" then
        self:debug("invalid caster %s", unitCaster)
        return
    end

    -- are we expecting a cast?
    local spell_item = self.spell_queue[castGUID]
    if spell_item == nil then
        self:debug("untracked spell GUID %s", castGUID)
        return
    end

    -- clear it
    self.spell_queue[castGUID] = nil

    -- is this a real spell?
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if spellInfo == nil then
        return
    end

    local spellName = spellInfo and spellInfo.name

    -- check for spell name
    if string.find(spellName, "Blessing of") == 1 then
        self:randomBlessing(spell_item.unitTarget, spellName)
    end

end

function BlessMeisterAddon:OnUnitSpellcastSent(unitCaster, target_name, castGUID, spellID)
    -- Arguments:
    --  unitCaster:     the person who cast the spell
    --  target_name:    the NAME of the target
    --  castGUID:       unique ephemeral ID of the spellcast
    --  spellID:        unique identifier of the spell

    -- only consider my spells
    if unitCaster ~= "player" then
        return
    end

    -- resolve target and only consider valid tokens
    local unitTarget = self:whichUnit(target_name)

    -- if successful, store the cast
    if unitTarget ~= nil then
        -- Store the target's name
        self:debug("Enqueueing spell '%s' (%d) on '%s' (%s)", castGUID, spellID, target_name, unitTarget)
        self.spell_queue[castGUID] = {
            timestamp = GetTime(),
            unitTarget = unitTarget,
            spellID = spellID
        }
    else
        self:debug("Unable to identify target '%s'", target_name)
    end
end

function BlessMeisterAddon:handleVariable(variable)
    if variable == "sibling" then
        local gender = UnitSex(self.current_target)
        if gender == 2 then
            return "sister"
        elseif gender == 3 then
            return "brother"
        else
            return "friend"
        end
    elseif variable == "3p_pronoun" then
        local gender = UnitSex(self.current_target)
        if gender == 2 then
            return "her"
        elseif gender == 3 then
            return "him"
        else
            return "them"
        end
    elseif variable == "3p_pronoun_poss" then
        local gender = UnitSex(self.current_target)
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
        return UnitName(self.current_target) or "friend"
    elseif variable == "race" then
        return UnitRace(self.current_target) or "stranger"
    elseif variable == "protection_active" then
        return "(guide|bless|protect|guard|shield|watch over)"
    elseif variable == "class" then
        return UnitClass(self.current_target) or "Hero"
    elseif variable == "title" then
        return "(({sibling} |){name}|{race}|{class})"
    elseif variable == "light" then
        return "(blessed |holy |sacred |eternal |glorious |)light"
    elseif variable == "blessing" then
        return "(boon|blessing|benediction|grace|gift|favor|grace|mercy)"
    elseif variable == "strengthen" then
        return "(bless|strengthen|bolster|lead)"
    elseif variable == "class_asset" then
        local class = (UnitClass(self.current_target) or "Hero"):lower()
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
        local class = (UnitClass(self.current_target) or "Hero"):lower()
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
        local class = (UnitClass(self.current_target) or "Hero"):lower()
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

function BlessMeisterAddon:handleFragment(fragment, start, endchar)
    self.tabs = self.tabs + 1
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
            local inner, inner_end = self:handleFragment(fragment, i + 1, ")")
            inner = RandomChoice(inner)
            result = result .. inner
            i = inner_end
        elseif char == "{" then
            -- evaluating a variable must be evaluated again as its contents may be formatting
            local inner, inner_end = self:handleFragment(fragment, i + 1, "}")
            -- first select optional variable {foo|bar|baz}
            inner = RandomChoice(inner)
            -- now evaluated the chosen variable
            inner = self:handleVariable(inner)
            -- now, handle that as a unique fragment in case the variable yielded nested fragments
            inner = self:handleFragment(inner)
            -- finally it will have been recursively resolved
            result = result .. inner
            i = inner_end
        elseif char == endchar then
            self.tabs = self.tabs - 1
            return result, i
        else
            result = result .. char
        end
        i = i + 1
    end
    self.tabs = self.tabs - 1
    return result, endindex
end

function BlessMeisterAddon:BuildSelfBlessing()

    local quip = RandomChoice({
        "(By (the light|the (ancestors |)forge|my (ancestors |)beard)), may this {strengthen} me!",
        "{strengthen} my (hand|arm|shield|weapon), {light}!",
        "(stone and |)light, hold fast!"
    })

    return capitalize(self:handleFragment(quip))
end

function BlessMeisterAddon:BuildTargetBlessing()


    -- quip : short, sometimes there, ends in !
    -- intro : always there, ends in .
    -- middle : encouragment sometimes. ends in ", and" if an ending exists
    -- ending : sometimes. capitalized if no middle

    local result = ""

    local quip = RandomChoice({
        "By the (ancestors|forge|mountain|iron|steel)!",
        "For (Khaz Modan|Bronzebeard|The Alliance)!",
        "Not today, shadow!",
        "", "", ""
    })

    if quip ~= "" then
        result = result .. capitalize(self:handleFragment(quip)) .. " "
    end

    -- Intro - the character bestows a blessing --
    local intro = math.random(1,3)
    pronoun = ""
    if intro == 1 then
        result = result .. capitalize(self:handleFragment("{light}, {protection_active} (this {race}|our {sibling} {name}|this {class}|{name} the {class})."))
        pronoun = "{3p_pronoun}"
    elseif intro == 2 then
        result = result .. capitalize(self:handleFragment("{title}, take (this|my|a) {blessing} of (the |our |){light}."))
        pronoun = "{possessive_adjective}"
    else
        result = result .. capitalize(self:handleFragment("Let me {bless|benedict|pray for} you, {title}, for (glory|victory)."))
        pronoun = "{possessive_adjective}"
    end

    -- pick a middle 0 is none
    local middle = RandomChoice({
        "(always |forever |)stand {class_attribute}(, {name}|)",
        "never (relent|surrender|lose faith|buckle|lose hope|give up|kneel|hesitate)(, {name}|)",
        "(i|we|you must) (feel|trust|believe) the {light} in you(, {name}|)",
        "", ""
    })

    -- pick an ending
    local ending = RandomChoice({
        "(make it|let it|allow it to|to) (bolster|aid|guide|lead|help|strengthen) " .. pronoun .. " {class_asset} (to victory|in battle|against the Horde)",
        "(never stray from|have faith in|trust) the {light}",
        "may your {class_weapon} bring (death to|victory over|devastation to) (the horde|our enemies)",
        "", "", "", ""
    })


    if middle ~= "" then
        result = result .. " " .. capitalize(self:handleFragment(middle))
    end

    if middle ~= "" and ending ~= "" then
        result = result .. ", and"
    end

    if ending ~= "" then
        ending = self:handleFragment(ending)
        if middle == "" then
            ending = capitalize(ending)
        end
        result = result .. " " .. ending
    end

    if middle ~= "" or ending ~= "" then
        result = result .. "!"
    end


    return result
end

function BlessMeisterAddon:randomBlessing(unit, spellName)

    if math.random() > self.db.bless_triggerchance then
        return
    end

    self.current_target = unit
    self.current_spell_name = spellName

    if UnitIsUnit(unit, "player") then
        local sentence = self:BuildSelfBlessing()
        SendChatMessage(sentence, "SAY")
    else
        local sentence = self:BuildTargetBlessing()
        SendChatMessage(sentence, "SAY")
    end
end


-- initialize
BlessMeisterAddon:init(addonName)
