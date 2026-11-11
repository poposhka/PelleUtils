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

-- Helper to get caller function name
function FuncName()
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
function split(text, separator)
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
function capitalize(str)
    if str == nil or str == "" then return "" end
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
function RandomChoice(list)

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
