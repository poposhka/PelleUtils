local addonName, addon = ...

local function CreateConfigFrame()
    local configFrame = CreateFrame("Frame", "PelleUtilsConfigFrame", UIParent, "BackdropTemplate")
    configFrame:SetSize(340, 200)
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
    title:SetText("PelleUtils")

    local message = configFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    message:SetPoint("TOP", 0, -42)
    message:SetText("Utility toggles and status for PelleUtils.")

    local toggleButton = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    toggleButton:SetSize(120, 28)
    toggleButton:SetPoint("BOTTOMLEFT", 18, 18)
    toggleButton:SetText("Toggle")
    toggleButton:SetScript("OnClick", function()
        if addon.db then
            addon.ToggleEnabled()
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
        addon.Print(addon.db and addon.db.message or "PelleUtils ready.")
    end)

    return configFrame
end

addon.ConfigFrame = CreateConfigFrame()

SLASH_PELLEUTILS_CONFIG1 = "/puconfig"
SlashCmdList["PELLEUTILS_CONFIG"] = function()
    if addon.ConfigFrame then
        if addon.ConfigFrame:IsShown() then
            addon.ConfigFrame:Hide()
        else
            addon.ConfigFrame:Show()
        end
    end
end
