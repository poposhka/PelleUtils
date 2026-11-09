local addonName, addon = ...

local function CreateConfigFrame()
    local configFrame = CreateFrame("Frame", "GenericAddonConfigFrame", UIParent, "BackdropTemplate")
    configFrame:SetSize(320, 180)
    configFrame:SetPoint("CENTER")
    configFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    configFrame:SetBackdropColor(0.08, 0.08, 0.10, 0.95)
    configFrame:SetBackdropBorderColor(0.60, 0.60, 0.70, 1)
    configFrame:Hide()

    local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("Generic Addon")

    local message = configFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    message:SetPoint("TOP", 0, -42)
    message:SetText("Toggle the addon or change your status message.")

    local toggleButton = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    toggleButton:SetSize(120, 28)
    toggleButton:SetPoint("BOTTOMLEFT", 18, 18)
    toggleButton:SetText("Toggle")
    toggleButton:SetScript("OnClick", function()
        if addon.db then
            addon.db.enabled = not addon.db.enabled
            GenericAddonDB = addon.db
            addon.Print(addon.db.enabled and "Enabled." or "Disabled.")
        end
    end)

    local closeButton = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    closeButton:SetSize(120, 28)
    closeButton:SetPoint("BOTTOMRIGHT", -18, 18)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        configFrame:Hide()
    end)

    local testButton = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    testButton:SetSize(180, 28)
    testButton:SetPoint("BOTTOM", 0, 60)
    testButton:SetText("Print Sample Message")
    testButton:SetScript("OnClick", function()
        addon.Print(addon.db and addon.db.message or "Generic Addon ready.")
    end)

    return configFrame
end

addon.ConfigFrame = CreateConfigFrame()

SLASH_GENERICADDON_CONFIG1 = "/gacfg"
SlashCmdList["GENERICADDON_CONFIG"] = function()
    if addon.ConfigFrame then
        if addon.ConfigFrame:IsShown() then
            addon.ConfigFrame:Hide()
        else
            addon.ConfigFrame:Show()
        end
    end
end
