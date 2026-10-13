-- Fresh-character theme choice. Deliberately no auto-apply: the player must
-- select one of the two cards, then confirm with Continue.
local frame

function DFRL.ShowThemeWelcome()
    if not DFRL.theme or not DFRL.theme:NeedsFirstRunChoice() then return false end
    if frame then frame:Show(); return true end
    if not DFRL.tools.CreateButton or not DFRL.themeUI then return false end

    frame = CreateFrame("Frame", "DFRLThemeWelcome", UIParent)
    frame:SetWidth(744)
    frame:SetHeight(422)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 5, right = 5, top = 5, bottom = 5},
    })
    frame:SetBackdropColor(.02, .025, .04, .98)
    frame:SetBackdropBorderColor(.75, .61, .32, 1)

    local heading = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOP", frame, "TOP", 0, -18)
    heading:SetText("WELCOME TO fruUI")
    heading:SetTextColor(1, .82, .2)

    local subheading = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    subheading:SetPoint("TOP", heading, "BOTTOM", 0, -10)
    subheading:SetText("Choose your preferred visual style. You can switch anytime in Settings > Themes.")

    local pending
    local cards = {}
    local function Choose(id)
        pending = id
        for k, card in pairs(cards) do card:MarkSelected(k == id) end
    end
    cards.fantasy = DFRL.themeUI.CreateCard(frame, "fantasy", 337, 246, Choose)
    cards.modern = DFRL.themeUI.CreateCard(frame, "modern", 337, 246, Choose)
    cards.fantasy:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -93)
    cards.modern:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -93)

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 25, 17)
    hint:SetText("Only appearance is changed. Your keybindings and layout are safe.")

    local go = DFRL.tools.CreateButton(frame, "Continue", 124, 30)
    go:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -24, 12)
    go:Disable()
    -- Enable Continue only after an explicit card selection.
    local function SelectCard(id)
        Choose(id)
        go:Enable()
    end
    cards.fantasy:SetScript("OnClick", function() SelectCard("fantasy") end)
    cards.modern:SetScript("OnClick", function() SelectCard("modern") end)
    go:SetScript("OnClick", function()
        if not pending then return end
        if not DFRL.theme:Select(pending) then return end
        DFRL_CUR_PROFILE[UnitName("player") .. "_firstRun"] = true
        frame:Hide()
    end)
    return true
end
