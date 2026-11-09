local addonName, addon = ...

addon.Name = addonName
addon.Version = "0.1.0"
addon.Defaults = {
    enabled = true,
    message = "Generic Addon ready.",
    color = "|cff00ccff",
}

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
        GenericAddonDB = addon.db
    end
end

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage((addon.db and addon.db.color or "|cff00ccff") .. "[Generic Addon]|r " .. tostring(message))
end

local function HandleSlashCommand(msg)
    local command = Trim(msg or ""):lower()

    if command == "toggle" then
        addon.db.enabled = not addon.db.enabled
        Save()
        Print(addon.db.enabled and "Enabled." or "Disabled.")
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

    Print("Usage: /ga toggle | /ga status | /ga say")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event ~= "PLAYER_LOGIN" then
        return
    end

    GenericAddonDB = GenericAddonDB or {}
    addon.db = MergeDefaults(addon.Defaults, GenericAddonDB)
    addon.db.message = addon.db.message or addon.Defaults.message
    addon.db.enabled = addon.db.enabled ~= false
    GenericAddonDB = addon.db

    Print("Version " .. addon.Version .. " loaded.")
    Print(addon.db.message)
end)

SLASH_GENERICADDON1 = "/ga"
SLASH_GENERICADDON2 = "/genericaddon"
SlashCmdList["GENERICADDON"] = HandleSlashCommand

addon.Print = Print
addon.HandleSlashCommand = HandleSlashCommand
