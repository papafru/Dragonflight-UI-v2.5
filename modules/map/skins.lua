-- fruUI Milestone 3C.2: square, minimal minimap visuals in Modern Dark.
-- Map controls, hit-testing, zoom, tracking and coordinates stay with Map.
-- Uses only stock WoW 1.12 region/texture APIs and named drawing layers.

local Skin = {entry = nil, listening = false}
DFRL.minimapSkins = Skin

local WHITE = "Interface\\Buttons\\WHITE8X8"

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
