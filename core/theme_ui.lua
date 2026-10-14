-- Shared visual theme choice cards. All artwork is drawn with stock 1.12
-- textures, so neither choice requires SuperWoW or extra dependencies.
DFRL.themeUI = {}
local ui = DFRL.themeUI
local WHITE = "Interface\\Buttons\\WHITE8X8"

local palette = {
    fantasy = {accent = {1, .82, .20}, surface = {.17, .14, .10}, label = "Dragonflight Fantasy",
        description = "Warm gold, familiar Warcraft ornamentation."},
    modern = {accent = {.43, .72, .90}, surface = {.08, .12, .17}, label = "Modern Dark",
        description = "Graphite, cool highlights and reduced clutter."},
}
ui.palette = palette

local function Font(parent, text, size, x, y, color)
    local f = parent:CreateFontString(nil, "OVERLAY")
    f:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    f:SetText(text)
    f:SetTextColor(color[1], color[2], color[3])
    return f
end

local function Bar(parent, width, height, x, y, color, layer)
    -- 1.12 has named drawing layers but no texture sublevel parameter.
    -- Keep each preview's background in its own child Frame and its fills
    -- in ARTWORK, so neither unit can cover the other's contents.
    local texture = parent:CreateTexture(nil, layer or "ARTWORK")
    texture:SetTexture(WHITE)
    texture:SetWidth(width)
    texture:SetHeight(height)
    texture:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    texture:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
    return texture
end

-- Returns a clickable card. The caller owns selection policy: the first-run
-- screen commits only on Continue; the settings tab commits immediately.
function ui.CreateCard(parent, id, width, height, onChoose)
    local p = palette[id]
    if not p then return nil end
    local card = CreateFrame("Button", nil, parent)
    card:SetWidth(width)
    card:SetHeight(height)
    card:SetBackdrop({
        bgFile = WHITE,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 13,
        insets = {left = 4, right = 4, top = 4, bottom = 4},
    })
    card:SetBackdropColor(p.surface[1], p.surface[2], p.surface[3], .98)
    card:SetBackdropBorderColor(.34, .35, .38, 1)

    local title = Font(card, p.label, 15, 16, -15, p.accent)
    local note = Font(card, p.description, 10, 16, -41, {.85, .85, .85})
    note:SetWidth(width - 32)
    note:SetJustifyH("LEFT")

    local mockTop = -75
    -- Paired unit frames: abstract visual previews, not actual game screenshots.
    local unitWidth = math.floor((width - 44) / 2)
    for i = 0, 1 do
        local unitX = 14 + i * (unitWidth + 16)
        -- Each unit has its own frame and opaque BACKGROUND backdrop.
        -- This avoids unstable draw ordering when all preview textures
        -- share the card's ARTWORK layer on the legacy client.
        local unit = CreateFrame("Frame", nil, card)
        unit:SetWidth(unitWidth)
        unit:SetHeight(39)
        unit:SetPoint("TOPLEFT", card, "TOPLEFT", unitX, mockTop)
        unit:EnableMouse(false) -- clicks must still reach the theme card
        unit:SetBackdrop({bgFile = WHITE})
        unit:SetBackdropColor(.035, .04, .045, 1)
        Bar(unit, unitWidth - 14, 9, 7, -16, p.accent, "ARTWORK")
        Bar(unit, unitWidth - 25, 5, 7, -28, {.21, .41, .72}, "ARTWORK")
        Font(unit, i == 0 and "PLAYER" or "TARGET", 9, 7, -4, {1, 1, 1})
        if id == "fantasy" then
            Bar(unit, 4, 39, 0, 0, p.accent, "OVERLAY")
            Bar(unit, 4, 39, unitWidth - 4, 0, p.accent, "OVERLAY")
        end
    end

    local total = 8
    local spacing = 5
    local tile = math.floor((width - 32 - (total - 1) * spacing) / total)
    local startX = math.floor((width - total * tile - (total - 1) * spacing) / 2)
    local buttonsY = mockTop - 59
    for i = 0, total - 1 do
        local x = startX + i * (tile + spacing)
        Bar(card, tile, tile, x, buttonsY, {.055, .06, .07})
        Bar(card, tile - 6, tile - 6, x + 3, buttonsY - 3,
            i % 3 == 0 and {.29, .43, .63} or i % 3 == 1 and {.40, .30, .26} or {.28, .40, .30})
        Bar(card, tile, 2, x, buttonsY, id == "fantasy" and p.accent or {.28, .32, .38})
        if id == "fantasy" then
            Bar(card, 2, tile, x, buttonsY, p.accent)
        end
    end

    Font(card, id == "fantasy" and "ORNATE  /  GOLD" or "MINIMAL  /  GRAPHITE", 9,
        16, -(height - 25), p.accent)
    local selectedLabel = Font(card, "SELECTED", 10, width - 85, -(height - 24), p.accent)
    selectedLabel:Hide()

    function card:MarkSelected(selected)
        if selected then
            self:SetBackdropBorderColor(p.accent[1], p.accent[2], p.accent[3], 1)
            selectedLabel:Show()
        else
            self:SetBackdropBorderColor(.34, .35, .38, 1)
            selectedLabel:Hide()
        end
    end
    card:SetScript("OnClick", function() if onChoose then onChoose(id) end end)
    card:SetScript("OnEnter", function()
        if not selectedLabel:IsShown() then
            card:SetBackdropBorderColor(.67, .69, .73, 1)
        end
    end)
    card:SetScript("OnLeave", function()
        if not selectedLabel:IsShown() then
            card:SetBackdropBorderColor(.34, .35, .38, 1)
        end
    end)
    return card
end
