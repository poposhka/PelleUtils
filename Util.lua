-- Util.lua
-- Helper functions and defines

WARRIOR     = "WARRIOR"
PRIEST      = "PRIEST"
PALADIN     = "PALADIN"
ROGUE       = "ROGUE"
WARLOCK     = "WARLOCK"
MAGE        = "MAGE"
DRUID       = "DRUID"
HUNTER      = "HUNTER"
SHAMAN      = "SHAMAN"
OTHER       = "OTHER"

NEUTRUM     = 1
MALE        = 2
FEMALE      = 3


ZONE_INFO = {
    ["Dun Morogh"] = {
        tavern = "Thunderbrew Distillery"
    },
    ["Elwynn Forest"] = {
        tavern = "Lion's Pride Inn",
    },
    ["Westfall"] = {
        tavern = "Sentinel Hill Inn"
    },
    ["Redridge Mountains"] = {
        tavern = "Lakeshire Inn"
    },
    ["Duskwood"] = {
        tavern = "Scarlet Raven Tavern"
    },
    ["Loch Modan"] = {
        tavern = "Stoutlager Inn"
    },
    ["Wetlands"] = {
        tavern = "Deepwater Tavern"
    },
    ["Arathi Highlands"] = {
        tavern = "Refuge Pointe"
    },
    ["Hillsbrad Foothills"] = {
        tavern = "Southshore Tavern"
    },
    ["The Hinterlands"] = {
        tavern = "Wildhammer Inn"
    },
    ["Western Plaguelands"] = {
        tavern = "Chillwind Camp"
    },
    ["Eastern Plaguelands"] = {
        tavern = "Light's Hope Chapel"
    },
    ["Stranglethorn Vale"] = {
        tavern = "Salty Sailor Tavern"
    },
    ["Teldrassil"] = {
        tavern = "Dolanaar Inn"
    },
    ["Darkshore"] = {
        tavern = "Auberdine Tavern"
    },
    ["Ashenvale"] = {
        tavern = "Astranaar Inn"
    },
    ["Felwood"] = {
        tavern = "Whisperwind Grove"
    },
    ["Moonglade"] = {
        tavern = "Moonglade Tavern"
    },
    ["Silithus"] = {
        tavern = " ... wait, can ye even get a drink here? ... "
    },
    ["The Barrens"] = {
        tavern = "Broken Keel Tavern"
    },
    ["Tanaris"] = {
        tavern = "Gadgetzan Inn"
    },
}

function printInfo(key, info, depth)
    result = ""
    depth = depth or 0
    if type(info) == "table" then
        result = string.rep(" ", depth) .. key .. " = {\n"
        for k, v in pairs(info) do
            result = result .. printInfo(k, v, depth + 2)
        end
        result = result .. string.rep(" ", depth) .. "}\n"
    else
        result = string.rep(" ", depth) .. key .. " = " .. tostring(info) .. "\n"
    end
    return result
end

function UnitInfoQuery(unit)
    local result = nil

    local funcs = {
        "UnitAuraSlots",
        "UnitBattlePetLevel",
        "UnitBattlePetSpeciesID",
        "UnitBattlePetType",
        "UnitBuff",
        "UnitCanAssist",
        "UnitCanAttack",
        "UnitCanCooperate",
        "UnitCanPetBattle",
        "UnitCastingDuration",
        "UnitCastingInfo",
        "UnitChannelDuration",
        "UnitChannelInfo",
        "UnitCharacterPoints",
        "UnitChromieTimeID",
        "UnitClass",
        "UnitClassBase",
        "UnitClassFromGUID",
        "UnitClassification",
        "UnitControllingVehicle",
        "UnitCreatureFamily",
        "UnitCreatureID",
        "UnitCreatureType",
        "UnitDamage",
        "UnitDebuff",
        "UnitDefense",
        "UnitDefenseSkill",
        "UnitDetailedThreatSituation",
        "UnitDistanceSquared",
        "UnitEffectiveLevel",
        "UnitEmpoweredChannelDuration",
        "UnitEmpoweredStageDurations",
        "UnitEmpoweredStagePercentages",
        "UnitExists",
        "UnitFacing",
        "UnitFactionGroup",
        "UnitFullName",
        "UnitGetAvailableRoles",
        "UnitGetDetailedHealPrediction",
        "UnitGetGuildXP",
        "UnitGetIncomingHeals",
        "UnitGetTotalAbsorbs",
        "UnitGetTotalHealAbsorbs",
        "UnitGroupRolesAssigned",
        "UnitGroupRolesAssignedEnum",
        "UnitGUID",
        "UnitHasEffectivelyTankAura",
        "UnitHasIncomingResurrection",
        "UnitHasLFGDeserter",
        "UnitHasLFGRandomCooldown",
        "UnitHasLootInteraction",
        "UnitHasMouseoverHighlight",
        "UnitHasPowerType",
        "UnitHasRelicSlot",
        "UnitHasVehiclePlayerFrameUI",
        "UnitHasVehicleUI",
        "UnitHealth",
        "UnitHealthMax",
        "UnitHealthMissing",
        "UnitHealthPercent",
        "UnitHonor",
        "UnitHonorLevel",
        "UnitHonorMax",
        "UnitHPPerStamina",
        "UnitInAnyGroup",
        "UnitInBattleground",
        "UnitInOtherParty",
        "UnitInParty",
        "UnitInPartyIsAI",
        "UnitInPartyShard",
        "UnitInPhase",
        "UnitInRaid",
        "UnitInRange",
        "UnitInSubgroup",
        "UnitInVehicle",
        "UnitInVehicleControlSeat",
        "UnitInVehicleHidesPetFrame",
        "UnitIsAFK",
        "UnitIsBattlePet",
        "UnitIsBattlePetCompanion",
        "UnitIsBossMob",
        "UnitIsCharmed",
        "UnitIsCivilian",
        "UnitIsConnected",
        "UnitIsControlling",
        "UnitIsCorpse",
        "UnitIsDead",
        "UnitIsDeadOrGhost",
        "UnitIsDND",
        "UninviteUnit",
        "UnitAffectingCombat",
        "UnitAlliedRaceInfo",
        "UnitArmor",
        "UnitAttackBothHands",
        "UnitAttackPower",
        "UnitAttackSpeed",
        "UnitAura",
        "UnitAuraBySlot",
        "UnitIsEnemy",
        "UnitIsFeignDeath",
        "UnitIsFriend",
        "UnitIsGameObject",
        "UnitIsGhost",
        "UnitIsGroupAssistant",
        "UnitIsGroupLeader",
        "UnitIsHumanPlayer",
        "UnitIsInInteractRange",
        "UnitIsInMyGuild",
        "UnitIsInteractable",
        "UnitIsLieutenant",
        "UnitIsMercenary",
        "UnitIsMinion",
        "UnitIsNPCAsPlayer",
        "UnitIsOtherPlayersBattlePet",
        "UnitIsOtherPlayersPet",
        "UnitIsOwnerOrControllerOfUnit",
        "UnitIsPartyLeader",
        "UnitIsPlayer",
        "UnitIsPlayerControlledOrGroupMember",
        "UnitIsPlusMob",
        "UnitIsPossessed",
        "UnitIsPVP",
        "UnitIsPVPFreeForAll",
        "UnitIsPVPSanctuary",
        "UnitIsQuestBoss",
        "UnitIsRaidOfficer",
        "UnitIsSameServer",
        "UnitIsSpellTarget",
        "UnitIsTapDenied",
        "UnitIsTapped",
        "UnitIsTappedByAllThreatList",
        "UnitIsTappedByPlayer",
        "UnitIsTrivial",
        "UnitIsUnconscious",
        "UnitIsUnit",
        "UnitIsVisible",
        "UnitIsWarModeActive",
        "UnitIsWarModeDesired",
        "UnitIsWarModePhased",
        "UnitIsWildBattlePet",
        "UnitLeadsAnyGroup",
        "UnitLevel",
        "UnitName",
        "UnitNameFromGUID",
        "UnitNameplateShowsWidgetsOnly",
        "UnitNameUnmodified",
        "UnitNumPowerBarTimers",
        "UnitOnTaxi",
        "UnitOwnerGUID",
        "UnitPartialPower",
        "UnitPercentHealthFromGUID",
        "UnitPhaseReason",
        "UnitPlayerControlled",
        "UnitPlayerOrPetInParty",
        "UnitPlayerOrPetInRaid",
        "UnitPosition",
        "UnitPower",
        "UnitPowerBarID",
        "UnitPowerBarTimerInfo",
        "UnitPowerDisplayMod",
        "UnitPowerMax",
        "UnitPowerMissing",
        "UnitPowerPercent",
        "UnitPowerType",
        "UnitPvpClassification",
        "UnitPVPName",
        "UnitPVPRank",
        "UnitQuestTrivialLevelRange",
        "UnitQuestTrivialLevelRangeScaling",
        "UnitRace",
        "UnitRangedAttack",
        "UnitRangedAttackPower",
        "UnitRangedDamage",
        "UnitReaction",
        "UnitRealmRelationship",
        "UnitResistance",
        "UnitSelectionColor",
        "UnitSelectionType",
        "UnitSetRole",
        "UnitSetRoleEnum",
        "UnitSex",
        "UnitSexBase",
        "UnitShouldDisplayName",
        "UnitShouldDisplaySpellTargetName",
        "UnitSpellHaste",
        "UnitSpellTargetClass",
        "UnitSpellTargetName",
        "UnitStagger",
        "UnitStat",
        "UnitSwitchToVehicleSeat",
        "UnitTargetsVehicleInRaidUI",
        "UnitThreatLeadSituation",
        "UnitThreatPercentageOfLead",
        "UnitThreatSituation",
        "UnitTokenFromGUID",
        "UnitTreatAsPlayerForDisplay",
        "UnitTrialBankedLevels",
        "UnitTrialXP",
        "UnitUsesAmmo",
        "UnitUsingVehicle",
        "UnitVehicleSeatCount",
        "UnitVehicleSeatInfo",
        "UnitVehicleSkin",
        "UnitWeaponAttackPower",
        "UnitWidgetSet",
        "UnitXP",
        "UnitXPMax",
    }
    local error_funcs = {}
    for _,func_name in pairs(funcs) do
        func = _G[func_name]
        if func == nil then
            table.insert(error_funcs, func_name .. " is not defined")
        elseif type(func) ~= "function" then
            table.insert(error_funcs, func_name .. " is not a function (" .. type(func) .. ")")
        else
            local result = nil
            local success = true
            xpcall(function()
                result = func(unit)
            end,
            function(err)
                table.insert(error_funcs, func_name .. " failed call: " .. err)
                success = false
            end)

            if success then
                local info_str = printInfo(func_name, result)
                io.write(info_str)
            end
        end
    end
    print("-- errors --")
    for k,v in pairs(error_funcs) do
        print(v)
    end
end

-- Helper to find chat frame by name
function GetChatFrameByName(targetName)
    for i = 1, NUM_CHAT_WINDOWS do
        local name = GetChatWindowInfo(i)
        if name and name:lower() == targetName:lower() then
            return _G["ChatFrame" .. i]
        end
    end
    return DEFAULT_CHAT_FRAME
end

-- Helper to format a string
function strfmt(message, ...)
    -- force replace arguments with strings
    for i = 1, select("#", ...) do
        local arg = select(i, ...)
        message = message:gsub("%%[^ ]*[sdfuil]", tostring(arg), 1)
    end
    return message
end

-- Helper to get line in file
function FileLine(text)
    return text:match("([^\\/:]+):(%d+):(.*)")
end

-- Helper to get caller function name
function FuncName()
    -- Start at stack depth 3 (1 = this function, 2 = current function, 3 = caller)
    local stack = debugstack(3, 1, 0)
    -- Extract the function name inside single quotes: in function 'FunctionName'
    local file, line, func = stack:match("([^\\/:]+):(%d+): in function '([^']+)'")
    if not line then
        file, line = FileLine(stack)
        func = "anonymous"
    end
    return file..":"..line..":"..func
end

function printTable(table)
    for key, value in pairs(table) do
        print(key, " = ", value)
    end
end

function join(tab, sep)
    sep = sep or " "
    if type(tab) ~= "table" then
        return tostring(tab)
    end

    local result = ""
    for _, i in pairs(tab) do
        local val = tostring(i)
        if result ~= "" then
            result = result .. sep
        end
        result = result .. val
    end
    return result
end

-- Helper function to split a string
function split(text, separator)
    if type(text) == "table" then
        -- already a table, return it as is
        return text
    end
    separator = separator or " "
    local parts = {}
    local start = 1
    while start < #text do
        local _, endpos = text:find(separator, start, true)
        if not endpos then
            break
        end
        table.insert(parts, string.sub(text, start, endpos - 1))
        start = endpos + 1
    end
    table.insert(parts, string.sub(text, start, #text))

    return parts
end

function concat(front, back, sep)
    if back == nil or back == "" then return front end
    if front == nil or front == "" then return back end
    sep = sep or " "
    return front .. sep .. back
end

-- Helper function to capitalize the first letter in a string
function capitalize(str)
    if str == nil then return nil end
    if str == "" then return "" end
    return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2)
end

-- Helper function to trim whitespace from a string
function Trim(value)
    if value == nil then
        return ""
    end
    return tostring(value):match("^%s*(.-)%s*$")
end

-- Helper function to merge defaults into a saved table
function MergeDefaults(defaults, saved)
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
function RandomChoice(list, nil_chance)

    if nil_chance ~= nil then
        if math.random() < nil_chance then
            return nil
        end
    end

    if type(list) == "string" then
        local options = split(list, "|")
        return options[math.random(1, #options)]
    end

    if type(list) ~= "table" or #list == 0 then
        return nil
    end

    local weightedChoices = {}
    local totalWeight = 0

    for _, entry in ipairs(list) do
        local weight = 1
        local value = entry

        if type(entry) == "table" then
            if #entry == 0 then
                -- this is a table but a nil choice
                value = nil
            elseif type(entry[1]) == "number" then
                -- this entry has a weight associated with it, the weight will be deleted
                weight = math.abs(entry[1])
                entry[1] = nil
            end
        end

        totalWeight = totalWeight + weight
        table.insert(weightedChoices, { weight = weight, value = value })

    end

    if #weightedChoices == 0 then
        return nil
    end


    local result = weightedChoices[#weightedChoices].value

    local roll = math.random() * totalWeight
    local cursor = 0
    for _, choice in ipairs(weightedChoices) do
        cursor = cursor + choice.weight
        if roll <= cursor then
            result = choice.value
            break
        end
    end


    if type(result) == "table" then
        return unpack(result)
    else
        return result
    end
end
