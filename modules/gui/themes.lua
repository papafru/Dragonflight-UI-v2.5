-- Themes is an existing-GUI extension, NOT a NewMod. The 24-slot Modules
-- settings grid must remain unchanged.
DFRL.InitThemeSettings = function(Base)
    if DFRL.themeSettingsReady or not Base or not Base.scrollChildren[16] then return end
    if not DFRL.theme or not DFRL.themeUI then return end
    local page = Base.scrollChildren[16]

    local intro = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    intro:SetPoint("TOPLEFT", page, "TOPLEFT", 34, -30)
    intro:SetText("Choose a visual style")

    local description = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT", intro, "BOTTOMLEFT", 0, -11)
    description:SetText("Your layout, bindings, profiles and unrelated settings are preserved.")

    local cards = {}
    cards.fantasy = DFRL.themeUI.CreateCard(page, "fantasy", 335, 246, function(id) DFRL.theme:Select(id) end)
    cards.modern = DFRL.themeUI.CreateCard(page, "modern", 335, 246, function(id) DFRL.theme:Select(id) end)
    cards.fantasy:SetPoint("TOPLEFT", page, "TOPLEFT", 34, -100)
    cards.modern:SetPoint("LEFT", cards.fantasy, "RIGHT", 18, 0)

    local active = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    active:SetPoint("TOPLEFT", page, "TOPLEFT", 34, -372)
    active:SetText("")

    local restore = DFRL.tools.CreateButton(page, "Restore Theme Defaults", 196, 30)
    restore:SetPoint("TOPLEFT", active, "BOTTOMLEFT", 0, -23)
    restore:SetScript("OnClick", function() DFRL.theme:RequestRestoreDefaults() end)

    local original = DFRL.tools.CreateButton(page, "Use Existing Appearance", 196, 30)
    original:SetPoint("LEFT", restore, "RIGHT", 16, 0)
    original:SetScript("OnClick", function() DFRL.theme:UseExistingAppearance() end)

    local note = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", restore, "BOTTOMLEFT", 0, -18)
    note:SetWidth(680)
    note:SetJustifyH("LEFT")
    note:SetText("Restore Theme Defaults always asks for confirmation. It clears only custom appearance settings for the selected theme. Switch back at any time to keep each theme's separate adjustments.")

    local function Sync()
        local selected = DFRL.theme:GetSelected()
        for k, card in pairs(cards) do card:MarkSelected(k == selected) end
        if selected == "fantasy" then
            active:SetText("Current appearance: Dragonflight Fantasy")
        elseif selected == "modern" then
            active:SetText("Current appearance: Modern Dark")
        else
            active:SetText("Current appearance: Existing custom configuration")
        end
        if selected then restore:Enable() else restore:Disable() end
    end
    DFRL.theme:AddListener(Sync)
    page:SetScript("OnShow", Sync)
    Sync()
    DFRL.themeSettingsReady = true
end
