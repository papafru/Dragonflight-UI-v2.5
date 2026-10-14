-- fruUI Modern Dark rectangular unit frames (WoW 1.12/1.18).
-- Appearance only: preserve status-bar logic, portraits' runtime updates,
-- unit frame anchors, targeting, rare/elite classification and module state.
-- Do NOT create a NewMod; the settings grid has exactly 24 slots.

local Style = {entries = {}, listening = false}
DFRL.unitFrameSkins = Style

local WHITE = "Interface\\Buttons\\WHITE8X8"
local PALETTE = {
    background = {.022, .033, .052, .95},
    accent = {.43, .72, .90},
    muted = {.25, .39, .52},
    text = {.87, .92, .98},
}

local function Line(holder, first, fx, fy, second, sx, sy, horizontal)
    local region = holder:CreateTexture(nil, "OVERLAY")
    region:SetTexture(WHITE)
    region:SetPoint(first, holder, first, fx, fy)
    region:SetPoint(second, holder, second, sx, sy)
    if horizontal then region:SetHeight(1) else region:SetWidth(1) end
    return region
end

local function Outline(parent, reference, inset, accent)
    local border = CreateFrame("Frame", nil, parent)
    border:SetAllPoints(reference)
    border:SetFrameLevel(math.max(parent:GetFrameLevel(), reference:GetFrameLevel()) + 2)
    border:EnableMouse(false)
    local lines = {
        Line(border, "TOPLEFT", -inset, inset, "TOPRIGHT", inset, inset, true),
        Line(border, "BOTTOMLEFT", -inset, -inset, "BOTTOMRIGHT", inset, -inset, true),
        Line(border, "TOPLEFT", -inset, inset, "BOTTOMLEFT", -inset, -inset, false),
        Line(border, "TOPRIGHT", inset, inset, "BOTTOMRIGHT", inset, -inset, false),
    }
    for i = 1, table.getn(lines) do
        lines[i]:SetVertexColor(accent[1], accent[2], accent[3], .94)
    end
    border:Hide()
    return border
end

local function MakeBarSkin(bar, isHealth)
    local matte = bar:CreateTexture(nil, "BACKGROUND")
    matte:SetTexture(WHITE)
    matte:SetAllPoints(bar)
    matte:SetVertexColor(.025, .04, .06, .90)
    matte:Hide()
    local accent = isHealth and PALETTE.accent or PALETTE.muted
    local outline = Outline(bar, bar, 1, accent)
    return {bar = bar, matte = matte, outline = outline}
end

local function CaptureAnchors(region)
    if not region or not region.GetNumPoints or not region.GetPoint then return nil end
    local points = {}
    for i = 1, region:GetNumPoints() do
        local a, b, c, d, e = region:GetPoint(i)
        if a then table.insert(points, {a, b, c, d, e}) end
    end
    return points
end

local function RestoreAnchors(region, points)
    if not region or not points or table.getn(points) == 0 then return end
    region:ClearAllPoints()
    for i = 1, table.getn(points) do
        region:SetPoint(unpack(points[i]))
    end
end

-- Blizzard 1.12 exposes the actual portraits as global PlayerPortrait /
-- TargetPortrait regions. owner.portrait is not always the same region.
-- Save BOTH opacity and own visibility because those may differ due to other
-- addons or unit state. Do not replace Show(), Hide() or texture updaters.
local function SuppressOrnate(entry)
    for i = 1, table.getn(entry.ornate) do
        local region = entry.ornate[i]
        region:SetAlpha(0)
        region:Hide()
    end
end

local function CaptureAndHide(entry)
    entry.savedOrnate = {}
    for i = 1, table.getn(entry.ornate) do
        local region = entry.ornate[i]
        entry.savedOrnate[i] = {
            alpha = region.GetAlpha and region:GetAlpha() or 1,
            shown = region:IsShown(),
        }
    end
    SuppressOrnate(entry)
end

local function RestoreOrnate(entry)
    if not entry.savedOrnate then return end
    for i = 1, table.getn(entry.ornate) do
        local region = entry.ornate[i]
        local saved = entry.savedOrnate[i]
        region:SetAlpha(saved.alpha)
        if saved.shown then region:Show() else region:Hide() end
    end
    entry.savedOrnate = nil
end

local function CollectOrnate(unit, owner)
    local result, seen = {}, {}
    local function Add(region)
        if region and not seen[region] then
            seen[region] = true
            table.insert(result, region)
        end
    end
    local prefix = unit == "player" and "Player" or "Target"
    Add(_G[prefix .. "FrameTexture"])
    Add(_G[prefix .. "FrameBackground"])
    Add(owner.portrait)
    Add(_G[prefix .. "Portrait"])
    Add(_G[prefix .. "FramePortrait"])
    if unit == "target" then
        Add(_G.TargetFrameNameBackground)
    end
    return result
end

local function RestylePvP(entry)
    local icon = entry.pvpIcon
    if not icon then return end
    entry.savedPvpAnchor = CaptureAnchors(icon)
    entry.savedPvpWidth, entry.savedPvpHeight = icon:GetWidth(), icon:GetHeight()
    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT", entry.panel, "TOPRIGHT", 2, -1)
    icon:SetWidth(34)
    icon:SetHeight(34)
end

local function RestorePvP(entry)
    local icon = entry.pvpIcon
    if not icon then return end
    RestoreAnchors(icon, entry.savedPvpAnchor)
    if entry.savedPvpWidth then icon:SetWidth(entry.savedPvpWidth) end
    if entry.savedPvpHeight then icon:SetHeight(entry.savedPvpHeight) end
    entry.savedPvpAnchor = nil
    entry.savedPvpWidth, entry.savedPvpHeight = nil, nil
end

local function RestyleText(entry)
    local name, level = entry.name, entry.level
    entry.savedNameAnchor = CaptureAnchors(name)
    entry.savedLevelAnchor = CaptureAnchors(level)
    entry.savedNameColor = name and name.GetTextColor and {name:GetTextColor()} or nil
    entry.savedLevelColor = level and level.GetTextColor and {level:GetTextColor()} or nil
    entry.savedNameJustify = name and name.GetJustifyH and name:GetJustifyH() or nil
    if name then
        name:ClearAllPoints()
        name:SetPoint("TOPLEFT", entry.health, "TOPLEFT", 3, 19)
        name:SetJustifyH("LEFT")
        name:SetTextColor(unpack(PALETTE.text))
    end
    if level then
        level:ClearAllPoints()
        level:SetPoint("TOPRIGHT", entry.health, "TOPRIGHT", -3, 19)
        level:SetTextColor(unpack(PALETTE.accent))
    end
end

local function RestoreText(entry)
    RestoreAnchors(entry.name, entry.savedNameAnchor)
    RestoreAnchors(entry.level, entry.savedLevelAnchor)
    if entry.name and entry.savedNameJustify then
        entry.name:SetJustifyH(entry.savedNameJustify)
    end
    if entry.name and entry.savedNameColor then
        entry.name:SetTextColor(unpack(entry.savedNameColor))
    end
    if entry.level and entry.savedLevelColor then
        entry.level:SetTextColor(unpack(entry.savedLevelColor))
    end
    entry.savedNameAnchor, entry.savedLevelAnchor = nil, nil
    entry.savedNameColor, entry.savedLevelColor = nil, nil
    entry.savedNameJustify = nil
end

function Style:UpdateClassification()
    local target = self.entries.target
    if not target or not target.classLabel then return end
    if not target.modern or not UnitExists or not UnitExists("target") then
        target.classLabel:Hide()
        return
    end
    local kind = UnitClassification and UnitClassification("target") or "normal"
    local captions = {
        elite = "ELITE",
        rare = "RARE",
        rareelite = "RARE ELITE",
        worldboss = "BOSS",
    }
    if captions[kind] then
        target.classLabel:SetText(captions[kind])
        target.classLabel:Show()
    else
        target.classLabel:Hide()
    end
end

local function MakeRectangle(unit, owner, health, resource)
    local panel = owner:CreateTexture(nil, "BACKGROUND")
    panel:SetTexture(WHITE)
    panel:SetPoint("TOPLEFT", health, "TOPLEFT", -8, 23)
    panel:SetPoint("BOTTOMRIGHT", resource or health, "BOTTOMRIGHT", 8, -8)
    panel:SetVertexColor(unpack(PALETTE.background))
    panel:Hide()

    local outline = CreateFrame("Frame", nil, owner)
    outline:SetPoint("TOPLEFT", panel, "TOPLEFT")
    outline:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT")
    outline:SetFrameLevel(math.max(owner:GetFrameLevel(), health:GetFrameLevel()) + 2)
    outline:EnableMouse(false)
    local edge = {
        Line(outline, "TOPLEFT", 0, 0, "TOPRIGHT", 0, 0, true),
        Line(outline, "BOTTOMLEFT", 0, 0, "BOTTOMRIGHT", 0, 0, true),
        Line(outline, "TOPLEFT", 0, 0, "BOTTOMLEFT", 0, 0, false),
        Line(outline, "TOPRIGHT", 0, 0, "BOTTOMRIGHT", 0, 0, false),
    }
    for i = 1, table.getn(edge) do
        edge[i]:SetVertexColor(unpack(PALETTE.muted))
    end
    local rule = Line(outline, "TOPLEFT", 2, -20, "TOPRIGHT", -2, -20, true)
    rule:SetVertexColor(unpack(PALETTE.accent))
    outline:Hide()

    local classification
    if unit == "target" then
        classification = owner:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        classification:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -2, -12)
        classification:SetTextColor(unpack(PALETTE.accent))
        classification:Hide()
    end
    return panel, outline, classification
end

function Style:Apply(selected)
    local modern = selected == "modern"
    for _, entry in pairs(self.entries) do
        if modern and not entry.modern then
            CaptureAndHide(entry)
            RestyleText(entry)
            RestylePvP(entry)
            entry.modern = true
        elseif not modern and entry.modern then
            RestoreOrnate(entry)
            RestoreText(entry)
            RestorePvP(entry)
            entry.modern = false
        end
        if modern then
            -- Target/portrait update events can show legacy regions again.
            SuppressOrnate(entry)
            entry.panel:Show()
            entry.outline:Show()
        else
            entry.panel:Hide()
            entry.outline:Hide()
        end
        for i = 1, table.getn(entry.bars) do
            local bar = entry.bars[i]
            if modern then
                bar.matte:Show()
                bar.outline:Show()
            else
                bar.matte:Hide()
                bar.outline:Hide()
            end
        end
    end
    self:UpdateClassification()
end

function DFRL.InitUnitFrameSkins(unit, health, resource)
    if unit ~= "player" and unit ~= "target" then return false end
    if Style.entries[unit] then return true end
    if not health then return false end
    local owner = unit == "player" and _G.PlayerFrame or _G.TargetFrame
    if not owner then return false end

    local ornate = CollectOrnate(unit, owner)

    local panel, outline, classLabel = MakeRectangle(unit, owner, health, resource)
    local bars = {MakeBarSkin(health, true)}
    if resource then table.insert(bars, MakeBarSkin(resource, false)) end
    Style.entries[unit] = {
        owner = owner, health = health, resource = resource,
        ornate = ornate, panel = panel, outline = outline,
        bars = bars, classLabel = classLabel,
        name = owner.name,
        level = unit == "player" and _G.PlayerLevelText or _G.TargetLevelText,
        pvpIcon = unit == "player" and _G.PlayerPVPIcon or _G.TargetPVPIcon,
        modern = false,
    }

    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    watcher:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    watcher:RegisterEvent("UNIT_FACTION")
    if unit == "target" then watcher:RegisterEvent("PLAYER_TARGET_CHANGED") end
    watcher:SetScript("OnEvent", function()
        -- Legacy client portrait and PvP routines run outside our module.
        -- Never intercept their texture updates: just re-hide modern art.
        local entry = Style.entries[unit]
        if entry and entry.modern then SuppressOrnate(entry) end
        if unit == "target" then Style:UpdateClassification() end
    end)
    Style[unit .. "Watcher"] = watcher
    if not Style.listening and DFRL.theme then
        Style.listening = true
        DFRL.theme:AddListener(function(id) Style:Apply(id) end)
    end
    Style:Apply(DFRL.theme and DFRL.theme:GetSelected())
    return true
end
