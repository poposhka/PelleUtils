local addonName, BlessMeisterAddon = ...


-- Note that we use the SavedVariable PelleUtilsDB

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
    self.last_emote = nil
    self.last_sentence = nil
    self.last_sentence_timeout = 0
    -- map pattern (string) -> sentence builder (function)
    self.spell_maps = {}


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


    self.spell_maps["Blessing of .+"] = self.OnDwarfPaladinBlessing
    self.spell_maps["Holy Light"] = self.OnDwarfPaladinBlessing

    self.frame = CreateFrame("Frame")
    self.frame:RegisterEvent("PLAYER_LOGIN")
    self.frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    self.frame:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")
    self.frame:SetScript("OnEvent", function(frame, ...)
        xpcall(function(...) self:OnEvent(...) end, self.Catch, ...)
    end)
end

-- STATIC function
function BlessMeisterAddon.Catch(err)
    file, line, rest = FileLine(err)
    if file and line and rest then
        err = "[" .. file .. ":" .. line .. "]:" .. rest
    end
    err = err .. ":\n" .. debugstack(2)

    local frame = GetChatFrameByName("error")
    frame:AddMessage(err)
    return err
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

    self.short_slash = "/pu"
    SLASH_PELLEUTILS1 = self.short_slash
    SLASH_PELLEUTILS2 = "/pelleutils"
    SlashCmdList["PELLEUTILS"] = function(...)
        xpcall(function(...) self:HandleSlashCommand(...) end, self.Catch, ...)
    end

    self:Print("Version " .. self.Version .. " loaded.")
    self:Print(self.db.message)
end

-- Helper to identify a unit token by name
function BlessMeisterAddon:whichUnit(unit_name)
    if unit_name == nil then
        return nil
    end

    for _, token in ipairs(self.UNIT_TOKENS) do
        local token_unit_name, token_unit_last = UnitName(token)
        if token_unit_name ~= nil then

            if token_unit_last ~= nil then
                token_unit_name = token_unit_name .." ".. token_unit_last
            end

            self:debug("Is token %s (name %s) = %s ? %s", token, token_unit_name, unit_name, unit_name == token_unit_name)
            if token_unit_name == unit_name then
                return token
            end
        end
    end
    return nil
end

-- Helper function to print debug info text to the user
function BlessMeisterAddon:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage((self.db and self.db.color or "|cff00ccff") .. "[".. self.Name .."]|r " .. tostring(message))
end

function BlessMeisterAddon:debug(message, ...)
    message = strfmt(message, ...)
    local frame = GetChatFrameByName("debug")
    frame:AddMessage("["..FuncName().."] " .. message)
end

function BlessMeisterAddon:error(message, ...)
    message = strfmt(message, ...)
    local frame = GetChatFrameByName("error")
    frame:AddMessage("["..FuncName().."] " .. message)
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

function BlessMeisterAddon:SendChatMessage(message, channel)
    if C_ChatInfo ~= nil then
        C_ChatInfo.SendChatMessage(message, channel)
    else
        SendChatMessage(message, channel)
    end
end

function BlessMeisterAddon:HandleSlashCommand(msg)
    -- normalize it, and split on spaces
    local input = Trim(msg or ""):lower()
    local params = split(input)
    local command = table.remove(params, 1) or "<none>"

    self:debug("Command: " .. command)

    if command == "toggle" then
        self:ToggleEnabled()
        return
    end

    if command == "status" then
        self:Print("Status: " .. (self.db.enabled and "enabled" or "disabled"))
        return
    end

    if command == "say" then

        -- if no sentence is created, we simply hold our piece
        if self.last_sentence == nil and self.last_emote == nil then
            self:debug("No sentence ready to say or emote")
            return
        end

        -- check if the timeout has expired, if so, don't speak
        local stale_time = GetTime() - self.last_sentence_timeout
        if stale_time > 0 then
            self:debug("Sentence was %d sec stale: %s, %s", stale_time, self.last_sentence, self.last_emote)
            self.last_sentence = nil
            self.last_emote = nil
            return
        end

        -- seems all conditions hold, speak up, then clear it
        if self.last_emote then
            self:SendChatMessage(self.last_emote, "EMOTE")
        end

        if self.last_sentence then
            self:SendChatMessage(self.last_sentence, "SAY")
        end

        self.last_sentence = nil
        self.last_emote = nil
        return
    end

    if command == "trigger" then
        if #params > 0 then
            self.db.bless_triggerchance = tonumber(params[1])
            self:Print("Trigger chance now set to " .. self.db.bless_triggerchance)
        else
            self:Print("Trigger chance currently set to " .. self.db.bless_triggerchance)
        end
        return
    end

    if command == "help" or command == "" then
        self:Print("Usage: "..self.short_slash.." toggle | "..self.short_slash.." status | "..self.short_slash.." say | "..self.short_slash.." blessing | "..self.short_slash.." help")
        return
    end

    self:Print("Unknown command. Use "..self.short_slash.." help")
end

function BlessMeisterAddon:OnUnitSpellcastSucceeded(unitCaster, castGUID, spellID, castBarID)
    -- not used
end

function BlessMeisterAddon:OnUnitSpellcastSent(unitCaster, target_name, castGUID, spellID)
    -- OnUnitSpellcastSent
    --  If we detect a spell being sent by the player we will generate something to say that can be
    --  triggered by the `say` slash command. Since we don't know if the spell will be successful at this point
    --  and we don't have the means to reliably delay without spamming `say`, we will make some rudimentary checks on the
    --  target to guess if we can assume it's reasonable that (and what) we should speak.
    --
    -- Arguments:
    --  unitCaster:     the person who cast the spell
    --  target_name:    the NAME of the target
    --  castGUID:       unique ephemeral ID of the spellcast
    --  spellID:        unique identifier of the spell
    self:debug("unitCaster=%s, target_name='%s', castGUID=%s, spellID=%d", unitCaster, target_name, castGUID, spellID)

    -- only consider my own spells
    if unitCaster ~= "player" then
        return
    end

    -- clear the last blessing
    self.last_sentence = nil
    self.last_emote = nil
    self.current_target = nil

    if target_name == nil then
        -- this is a non-targetted spell which reflects back to the player
        self:debug("target is nil, assuming self-target")
        self.current_target = "player"
        target_name = UnitName("player")
    else
        -- can we resolve target?
        self.current_target = self:whichUnit(target_name)
        if self.current_target == nil then
            self:debug("Unable to resolve target name %s", target_name)
            return
        end
    end

    -- is this a real spell?
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if spellInfo == nil then
        self:debug("Unable to resolve spellID %d", spellID)
        return
    end

    -- Is the spell in our spellmapping?
    local spell_handler = nil
    for pattern, handler in pairs(self.spell_maps) do
        local matched = spellInfo.name:find(pattern)
        self:debug("Check '%s' against pattern '%s': %s", spellInfo.name, pattern, matched ~= nil)
        if matched ~= nil then
            spell_handler = handler
            break
        end
    end

    -- bail if no handler for this message exists
    if spell_handler == nil then
        self:debug("No handler for %s found", spellInfo.name)
        return
    end

    if math.random() > self.db.bless_triggerchance then
        self:debug("Spellspeak not triggered (random chance %.2f > trigger chance %.2f)", math.random(), self.db.bless_triggerchance)
        return
    end

    self.current_spell_name = spellName
    self:debug("Blessing triggered on '%s' (%s) with spell '%s'", target_name, self.current_target, spellName)


    -- invoke the handler
    self:debug("Invoking handler '%s'", spell_handler)
    spell_handler(self)

    self.last_sentence_timeout = GetTime() + 999

end

function BlessMeisterAddon:ClassChoice(target, choices, default)
    local class = (UnitClass(target) or OTHER):lower()
    return choices[class] or default
end

function BlessMeisterAddon:handleVariable(variable)

    local parameters = {}
    if variable:find(":") then
        parameters = split(variable, ":")
        parameters, variable = removeAt(parameters, 1)
    end

    if variable == "sibling" then
        local target = parameters[1] or self.current_target
        local gender = UnitSex(target)
        if gender == FEMALE then
            return "sister"
        elseif gender == MALE then
            return "brother"
        else
            return "friend"
        end

    elseif variable == "pronoun" then
        local target = parameters[1] or self.current_target
        local gender = UnitSex(target)
        if gender == FEMALE then
            return "her"
        elseif gender == MALE then
            return "him"
        else
            return "them"
        end

    elseif variable == "possessive_pronoun" then
        local target = parameters[1] or self.current_target
        local gender = UnitSex(target)
        if gender == FEMALE then
            return "her"
        elseif gender == MALE then
            return "his"
        else
            return "their"
        end

    elseif variable == "3p_pronoun" then
        local target = parameters[1] or self.current_target
        local gender = UnitSex(target)
        if gender == FEMALE then
            return "her"
        elseif gender == MALE then
            return "him"
        else
            return "them"
        end

    elseif variable == "3p_pronoun_poss" then
        local target = parameters[1] or self.current_target
        local gender = UnitSex(target)
        if gender == FEMALE then
            return "hers"
        elseif gender == MALE then
            return "his"
        else
            return "their"
        end

    elseif variable == "possessive_adjective" then
        return "(your|yer)"

    elseif variable == "dwarf_legends" then
        return "(High King Magni|Muradin|Madoran|King Khardros|Modgud)"

    elseif variable == "name" then
        local target = parameters[1] or self.current_target
        return UnitName(target) or "friend"

    elseif variable == "race" then
        local target = parameters[1] or self.current_target
        return UnitRace(target) or "stranger"

    elseif variable == "protection_active" then
        return "(guide|bless|protect|guard|shield|watch over)"

    elseif variable == "class" then
        local target = parameters[1] or self.current_target
        local classinfo = UnitClass(target)
        classinfo = split(classinfo)
        return GetClassInfo(tonumber(classinfo[#classinfo])) or "Hero"

    elseif variable == "title" then
        return "([{sibling} ]{name}|{race}|{class})"

    elseif variable == "local_tavern" then
        local info = ZONE_INFO[GetZoneText()]
        if info ~= nil then return info.tavern else return "the tavern" end

    elseif variable == "light" then
        return "[blessed |holy |sacred |eternal |glorious ]light"

    elseif variable == "blessing" then
        return "(boon|blessing|benediction|grace|gift|favor|grace|mercy)"

    elseif variable == "strengthen" then
        return "(bless|strengthen|bolster|lead)"

    elseif variable == "class_asset" then
        local target = parameters[1] or self.current_target
        return self:ClassChoice(target, {
            [WARRIOR] = "(arm|fist|blade)",
            [PRIEST] = "soul",
            [PALADIN] = "heart",
            [ROGUE] = "senses",
            [WARLOCK] = "ways",
            [MAGE] = "mind",
            [DRUID] = "spirit",
            [HUNTER] = "step",
            [SHAMAN] = "ancestors"
        }, "courage")

    elseif variable == "class_attribute" then
        local target = parameters[1] or self.current_target
        return self:ClassChoice(target, {
            [WARRIOR] = "(true|courageous|brave|strong|fierce|unyielding|honorable)",
            [PRIEST] = "(true|faithful|with the light)",
            [PALADIN] = "(true|courageous|brave|strong|fierce|unyielding|faithful|with the light)",
            [ROGUE] = "(cunning|fierce|deadly)",
            [WARLOCK] = "(cunning|courageous)",
            [MAGE] = "(brilliant|courageous)",
            [DRUID] = "(true|resolute)",
            [HUNTER] = "(swift|true|straight)",
            [SHAMAN] = "(true|faithful|honorable)",
        }, "true")

    elseif variable == "class_weapon" then
        local target = parameters[1] or self.current_target
        return self:ClassChoice(target, {
            [WARRIOR] = "(axe|sword|hammer)",
            [PRIEST] = "(faith|healing|heart)",
            [PALADIN] = "(courage|pure heart|hammer)",
            [ROGUE] = "(blades|cunning ways|instincts)",
            [WARLOCK] = "(magicks|unholy acts|connection to the nether)",
            [MAGE] = "(brilliance|magicks|arcana|fire and frost)",
            [DRUID] = "(connection to nature|strength of spirit|bond with nature)",
            [HUNTER] = "(sharp arrows|bow and companion|instincts)",
            [SHAMAN] = "(ancestors|ancestral bond|connection to the earth)",
        }, "courage")

    else
        return variable
    end
end

function BlessMeisterAddon:handleFragment(fragment, start, endchar)
    if fragment == nil then
        return nil
    end
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
        elseif char == "[" then
            -- Optiontext (choice|choice) is evaluated on options once
            -- we advance i to the end of the subfragment
            local inner, inner_end = self:handleFragment(fragment, i + 1, "]")
            inner = RandomChoice(inner .. "|")
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

function BlessMeisterAddon:OnDwarfPaladinBlessing()

    local targetted_emotes = {}
    if self.current_target == "player" then
        self:BuildSelfBlessing()
    else
        self:BuildTargetBlessing()
        targetted_emotes = {
            "(turns toward|reaches for) {name}",
            "(stretches|reaches|gazes|lifts {possessive_pronoun:player} head) towards the (heavens|light|sky)",
            "(chants|mumbles|says|whispers) a prayer[ under {possessive_pronoun:player} breath][ for {name}]",
        }
    end

    local emotes = extend(targetted_emotes, {
        "seems (focused|deep|concentrated) in prayer",
        "(stretches|reaches|gazes|lifts {possessive_pronoun:player} head) towards the (heavens|light|sky)",
        "(chants|mumbles|says|whispers) a prayer[ under {possessive_pronoun:player} breath][ for {pronoun:player}self]",
        "touches (the ground|his shield|{possessive_pronoun:player} heart|)",
        "(focuses|closes) {possessive_pronoun:player} eyes"
    })
    local emote_string = RandomChoice(emotes, 0.5)
    self.last_emote = capitalize(self:handleFragment(emote_string))

end

function BlessMeisterAddon:BuildSelfBlessing()
    local self_blessing = ""

    local opener = RandomChoice({
        "by (the light|the [ancestors ](forge|brew|mountain)|my [ancestors ][long ]beard),",
        "by [dwarves and |earth and |mountain and |stone and ](steel|light|hearth),",
    }, 0.3)

    local quip = RandomChoice({
        "may this {strengthen} me[ in battle| against the sourge]!",
        "{strengthen} my (steel|hand|arm|shield|weapon), {light}!",
        "i must (hold fast|be strong|have courage|press on)!"
    })

    self_blessing = concat(opener, quip, " ")
    self_blessing = capitalize(self:handleFragment(self_blessing))

    self.last_sentence = self_blessing
end

function BlessMeisterAddon:BuildTargetBlessing()


    -- [Quip.] Main. [Middle][,and ][End.]

    local quip = RandomChoice({
        "(stone and steel|hammer and hearth|storm and sky)!",
        "(hear me|listen up), ye lot!",
        "by the (ancestors|forge|mountain|iron|steel)!",
        "for (the High Seat|Khaz Modan|Bronzebeard|The Alliance|Falstad's Gryphon)!",
        "by {dwarf_legends}['s (hammer|beard|shield)]!"
    }, 0.5)

    -- pick a main phrase + pronoun
    local main, pronoun = RandomChoice({
        {"{light}, {protection_active} (this {race}|our {sibling} {name}|this {class}|{name} the {class})", "{3p_pronoun}"},
        {"{title}, take (this|my|a) {blessing} of [the |our ]{light}", "{possessive_adjective}"},
        {"Let me {bless|benedict|pray for} you, {title}, for (glory|victory)", "{possessive_adjective}"}
    })

    -- pick a middle 0 is none
    local middle = RandomChoice({
        "give 'em no quarter",
        "show 'em what {race}s are made of",
        "stand yer ground",
        "drive 'em back",
        "make {dwarf_legends} proud",
        "[always |forever ]stand {class_attribute}[, {name}]",
        "never (relent|surrender|lose faith|buckle|lose hope|give up|kneel|hesitate|yield)[, {name}]",
        "(i|we|you must) (can feel|trust|believe) the {light} in you[, {name}]"
    }, 0.75)

    -- pick an ending
    local ending = RandomChoice({
        "(make it|let it|allow it to|to) (bolster|aid|guide|lead|help|strengthen) " .. pronoun .. " {class_asset} (to victory|in battle|against the Horde)",
        "(never stray from|have faith in|trust) the {light}",
        "may your {class_weapon} bring (death to|victory over|devastation to) (the horde|our enemies)",
        "keep yer feet on the ground",
        "may yer (tankard|mug|glass|cup) (always be full|never run dry|flow over)",
        "the (roast hog|first round) at {local_tavern} will be on (you|me)",
        "tonight we (feast|drink|celebrate)[ like kings] at ({local_tavern}|under the mountain)",
    }, 0.6)

    -- concat middle and end with ", and" if both appear
    middle = concat(middle, ending, ", and ")
    middle = capitalize(self:handleFragment(middle))

    -- Assemble quip and main
    local result = capitalize(self:handleFragment(quip))
    result = concat(result, capitalize(self:handleFragment(main)))

    -- tag on middle
    self.last_sentence = concat(result, middle, ". ") .. "!"

end

-- initialize
BlessMeisterAddon:init(addonName)

