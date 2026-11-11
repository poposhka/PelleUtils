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
    self.spell_queue = {}
    self.bless_channel = "EMOTE"

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
    self.frame:SetScript("OnEvent", function(frame, ...) self:SafeOnEvent(...) end)
end

function BlessMeisterAddon:SafeOnEvent(...)
    local ok, result = xpcall(self.OnEvent, function(err)
        return err .. ":\n" .. debugstack(2)
    end,
    self, ...)

    if not ok then
        self:error(result)
    end
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
    SlashCmdList["PELLEUTILS"] = function(msg)
        self:HandleSlashCommand(msg)
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

            self:debug("Is token '"..tostring(token).."' name "..tostring(token_unit_name).." = "..tostring(unit_name).." ?")
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
    local text = tostring(message):format(...)
    local frame = GetChatFrameByName("debug")
    frame:AddMessage("["..FuncName().."] " .. text)
end

function BlessMeisterAddon:error(message, ...)
    local text = tostring(message):format(...)
    local frame = GetChatFrameByName("error")
    frame:AddMessage("["..FuncName().."] " .. text)
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
        self:randomBlessing("target", "Blessing of Might")
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
    self:debug("dequeueing spell '%s' (%d) on '%s' (%s)", castGUID, spellID, UnitName(spell_item.unitTarget), spell_item.unitTarget)
    self.spell_queue[castGUID] = nil

    -- is this a real spell?
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if spellInfo == nil then
        self:debug("Unable to resolve spellID %d", spellID)
        return
    end

    local spellName = spellInfo and spellInfo.name

    -- check for spell name
    if string.find(spellName, "Blessing of") == 1 then
        self:debug("Spell '%s' (%d) is a blessing - invoking random blessing", spellName, spellID)
        self:randomBlessing(spell_item.unitTarget, spellName)
    else
        self:debug("Spell '%s' (%d) is not a blessing", spellName, spellID)
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

function BlessMeisterAddon:ClassChoice(choices, default)
    local class = (UnitClass(self.current_target) or OTHER):lower()
    return choices[class] or default
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
        return self:ClassChoice({
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
        return self:ClassChoice({
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
        return self:ClassChoice({
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
        self:debug("Blessing not triggered (random chance %.2f > trigger chance %.2f)", math.random(), self.db.bless_triggerchance)
        return
    end

    self.current_target = unit
    self.current_spell_name = spellName
    self:debug("Blessing triggered on '%s' (%s) with spell '%s'", UnitName(unit), unit, spellName)

    if UnitIsUnit(unit, "player") then
        local sentence = self:BuildSelfBlessing()
        self:debug("%s self blessing: %s", self.bless_channel, sentence)
        self:SendChatMessage(sentence, self.bless_channel)
    else
        local sentence = self:BuildTargetBlessing()
        self:debug("%s target blessing: %s", self.bless_channel, sentence)
        self:SendChatMessage(sentence, self.bless_channel)
    end
end


-- initialize
BlessMeisterAddon:init(addonName)
