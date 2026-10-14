-- fruUI Milestone 3C.2: square, minimal minimap visuals in Modern Dark.
-- Map controls, hit-testing, zoom, tracking and coordinates stay with Map.
-- Uses only stock WoW 1.12 region/texture APIs and named drawing layers.

local Skin = {entry = nil, listening = false}
DFRL.minimapSkins = Skin

local WHITE = "Interface\\Buttons\\WHITE8X8"

-- The legacy map places the name and clock independently, so long zone
-- names can overflow their header or collide with 12-hour time strings.
-- Only Modern receives this measured, single-line header layout.
function Skin:UpdateHeader(force)
    local e = self.entry
    if not e or not e.modern then return end

    local setup = e.setup
    local zone = _G.MinimapZoneText
    local button = _G.MinimapZoneTextButton
    local clock = setup.timeText
    if not zone or not button or not clock then return end
    if not zone.GetStringWidth or not zone.GetFont then return end

    local panelWidth = setup.topPanel:GetWidth()
    local zoneX = DFRL:GetTempDB("Map", "zoneTextX") or 4
    local zoneY = DFRL:GetTempDB("Map", "zoneTextY") or -3
    local timeX = DFRL:GetTempDB("Map", "timeX") or -4
    local timeY = DFRL:GetTempDB("Map", "timeY") or -3
    local zoneSize = DFRL:GetTempDB("Map", "zoneTextSize") or 10
    local clockVisible = DFRL:GetTempDB("Map", "mapTime") ~= false
    local clockWidth = 0
    if clockVisible then
        clockWidth = math.max(38, (clock:GetStringWidth() or 38) + 6)
    end

    -- Honor user offsets relative to the original defaults. Add just a few
    -- pixels of breathing room and reserve a safe gap before the clock.
    local left = zoneX + 5
    local right = clockVisible and (math.abs(timeX) + 5 + clockWidth + 7) or 9
    local available = math.max(18, panelWidth - left - right)
    local text = zone:GetText() or ""
    local signature = table.concat({
        text, tostring(panelWidth), tostring(left), tostring(zoneY),
        tostring(timeX), tostring(timeY), tostring(clockWidth),
        tostring(clockVisible), tostring(zoneSize),
    }, "\031")
    if not force and signature == e.headerSignature then return end
    e.headerSignature = signature

    button:ClearAllPoints()
    button:SetPoint("LEFT", setup.topPanel, "LEFT", left, zoneY + 2)
    button:SetWidth(available)
    zone:SetWidth(available)

    local path, currentSize, flags = zone:GetFont()
    if path and currentSize then
        zone:SetFont(path, zoneSize, flags or "")
        -- GetStringWidth is present in the 1.12 FontString API; never
        -- rewrite the native zone name or replace its update handlers.
        local fit = zoneSize
        while fit > 7 and zone:GetStringWidth() > available do
            fit = fit - 1
            zone:SetFont(path, fit, flags or "")
        end
    end

    if setup.timeText then
        clock:ClearAllPoints()
        clock:SetPoint("RIGHT", setup.topPanel, "RIGHT", timeX - 4, timeY + 2)
    end
end

function Skin:RestoreHeader()
    local e = self.entry
    if not e or not e.headerAdjusted then return end
    local setup = e.setup
    local zone = _G.MinimapZoneText
    local button = _G.MinimapZoneTextButton
    if button then
        button:ClearAllPoints()
        button:SetPoint("LEFT", setup.topPanel, "LEFT",
            DFRL:GetTempDB("Map", "zoneTextX") or 4,
            DFRL:GetTempDB("Map", "zoneTextY") or -3)
        if e.original.zoneButtonWidth then
            button:SetWidth(e.original.zoneButtonWidth)
        end
    end
    if zone then
        if e.original.zoneWidth then zone:SetWidth(e.original.zoneWidth) end
        if zone.GetFont then
            local path, size, flags = zone:GetFont()
            if path and size then
                zone:SetFont(path, DFRL:GetTempDB("Map", "zoneTextSize") or 10,
                    flags or "")
            end
        end
    end
    if setup.timeText then
        setup.timeText:ClearAllPoints()
        setup.timeText:SetPoint("RIGHT", setup.topPanel, "RIGHT",
            DFRL:GetTempDB("Map", "timeX") or -4,
            DFRL:GetTempDB("Map", "timeY") or -3)
    end
    e.headerSignature = nil
    e.headerAdjusted = false
end

local function ModernSquare()
    return DFRL.theme and DFRL.theme:GetSelected() == "modern"
        and DFRL:GetTempDB("Map", "mapSquare") == true
end

function Skin:Refresh()
    local e = self.entry
    if not e then return end
    local modern = DFRL.theme and DFRL.theme:GetSelected() == "modern"
    local square = ModernSquare()
    -- The existing Map callbacks have already updated the actual mask and
    -- shape artwork. We only conceal their ornate border for square Modern.
    e.setup.minimapBorder:SetAlpha(square and 0 or e.original.borderAlpha)
    e.setup.minimapShadow:SetAlpha(square and 0 or e.original.shadowAlpha)
    e.setup.bgTexture:SetAlpha(modern and 0 or e.original.panelAlpha)

    if modern then
        e.panel:Show()
        e.divider:Show()
    else
        e.panel:Hide()
        e.divider:Hide()
    end
    for i = 1, table.getn(e.edges) do
        if square then e.edges[i]:Show() else e.edges[i]:Hide() end
    end
    e.modern = modern
    e.square = square
    if modern then
        e.headerAdjusted = true
        self:UpdateHeader()
    else
        self:RestoreHeader()
    end
end

function Skin:UpdateShadowAlpha(value)
    local e = self.entry
    if not e then return end
    e.original.shadowAlpha = value
    if e.square then e.setup.minimapShadow:SetAlpha(0) end
end

function DFRL.InitMinimapSkin(setup)
    if Skin.entry then return true end
    if not setup or not setup.minimapBorder or not setup.minimapShadow
        or not setup.topPanel or not setup.bgTexture then return false end
    if not Minimap then return false end

    local entry = {
        setup = setup, edges = {}, modern = false, square = false,
        original = {
            borderAlpha = setup.minimapBorder:GetAlpha(),
            shadowAlpha = setup.minimapShadow:GetAlpha(),
            panelAlpha = setup.bgTexture:GetAlpha(),
            zoneWidth = MinimapZoneText and MinimapZoneText:GetWidth() or nil,
            zoneButtonWidth = MinimapZoneTextButton
                and MinimapZoneTextButton:GetWidth() or nil,
        },
    }

    -- Edges follow the existing minimap geometry through size/scale edits.
    local map = Minimap
    local function Line(a, b, w)
        local tex = map:CreateTexture(nil, "OVERLAY")
        tex:SetTexture(WHITE)
        tex:SetVertexColor(.27, .39, .48, 1)
        tex:SetPoint(a, map, a, 0, 0)
        tex:SetPoint(b, map, b, 0, 0)
        if w then tex:SetWidth(1) else tex:SetHeight(1) end
        tex:Hide()
        return tex
    end
    entry.edges[1] = Line("TOPLEFT", "TOPRIGHT", false)
    entry.edges[2] = Line("BOTTOMLEFT", "BOTTOMRIGHT", false)
    entry.edges[3] = Line("TOPLEFT", "BOTTOMLEFT", true)
    entry.edges[4] = Line("TOPRIGHT", "BOTTOMRIGHT", true)

    -- Original top-panel texture extends 20px beyond the panel. Modern uses
    -- exactly the panel's own bounds, for a slim charcoal zone/time header.
    local panel = setup.topPanel:CreateTexture(nil, "BACKGROUND")
    panel:SetTexture(WHITE)
    panel:SetAllPoints(setup.topPanel)
    panel:SetVertexColor(.045, .065, .09, .96)
    panel:Hide()
    entry.panel = panel

    local divider = setup.topPanel:CreateTexture(nil, "ARTWORK")
    divider:SetTexture(WHITE)
    divider:SetPoint("BOTTOMLEFT", setup.topPanel, "BOTTOMLEFT", 0, 0)
    divider:SetPoint("BOTTOMRIGHT", setup.topPanel, "BOTTOMRIGHT", 0, 0)
    divider:SetHeight(1)
    divider:SetVertexColor(.27, .39, .48, .9)
    divider:Hide()
    entry.divider = divider

    Skin.entry = entry
    if DFRL.theme and not Skin.listening then
        Skin.listening = true
        DFRL.theme:AddListener(function() Skin:Refresh() end)
    end
    Skin:Refresh()
    return true
end
