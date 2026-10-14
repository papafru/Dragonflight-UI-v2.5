-- fruUI Milestone 3B: decorative Modern Dark player/target bar treatment.
-- Does not register a NewMod or replace combat, targeting, status bar,
-- classification, portrait, mouse, keyboard or movement handlers.
local Style = {
    entries = {},
    listening = false,
}
DFRL.unitFrameSkins = Style

local WHITE = "Interface\\Buttons\\WHITE8X8"

local function MakeLine(frame, a, x1, y1, b, x2, y2, horizontal)
    local tex = frame:CreateTexture(nil, "OVERLAY")
    tex:SetTexture(WHITE)
    tex:SetPoint(a, frame, a, x1, y1)
    tex:SetPoint(b, frame, b, x2, y2)
    if horizontal then tex:SetHeight(1) else tex:SetWidth(1) end
    return tex
end

local function MakeBarSkin(bar, isHealth)
    -- Child frames inherit the status bar's position, scale and visibility.
    -- The graphic region sits above the bar border but does not accept clicks.
    local outline = CreateFrame("Frame", nil, bar)
    outline:SetAllPoints(bar)
    outline:SetFrameLevel(bar:GetFrameLevel() + 1)
    outline:EnableMouse(false)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetAllPoints(bar)
    bg:SetVertexColor(.035, .055, .08, .9)
    bg:Hide()

    local top = MakeLine(outline, "TOPLEFT", -1, 1, "TOPRIGHT", 1, 1, true)
    local bottom = MakeLine(outline, "BOTTOMLEFT", -1, -1, "BOTTOMRIGHT", 1, -1, true)
    local left = MakeLine(outline, "TOPLEFT", -1, 1, "BOTTOMLEFT", -1, -1, false)
    local right = MakeLine(outline, "TOPRIGHT", 1, 1, "BOTTOMRIGHT", 1, -1, false)
    outline:Hide()
    return {bar = bar, outline = outline, matte = bg,
        lines = {top, bottom, left, right}, isHealth = isHealth}
end

function Style:Apply(themeId)
    local modern = themeId == "modern"
    local pal = DFRL.themeUI and DFRL.themeUI.palette and DFRL.themeUI.palette.modern
    local accent = pal and pal.accent or {.43, .72, .90}
    for _, entry in pairs(self.entries) do
        for i = 1, table.getn(entry.bars) do
            local bar = entry.bars[i]
            if modern then
                local r, g, b = accent[1], accent[2], accent[3]
                if not bar.isHealth then r, g, b = r * .55, g * .55, b * .55 end
                for j = 1, table.getn(bar.lines) do
                    bar.lines[j]:SetVertexColor(r, g, b, .95)
                end
                bar.outline:Show()
                bar.matte:Show()
            else
                bar.outline:Hide()
                bar.matte:Hide()
            end
        end
    end
end

function DFRL.InitUnitFrameSkins(unit, healthBar, resourceBar)
    if unit ~= "player" and unit ~= "target" then return false end
    if Style.entries[unit] then return true end
    if not healthBar then return false end

    local bars = {MakeBarSkin(healthBar, true)}
    if resourceBar then table.insert(bars, MakeBarSkin(resourceBar, false)) end
    Style.entries[unit] = {bars = bars}

    if not Style.listening and DFRL.theme then
        Style.listening = true
        DFRL.theme:AddListener(function(selected) Style:Apply(selected) end)
    end
    Style:Apply(DFRL.theme and DFRL.theme:GetSelected())
    return true
end
