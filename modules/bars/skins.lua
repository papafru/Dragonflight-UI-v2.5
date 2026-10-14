-- fruUI Milestone 3A: reversible Modern Dark action-button graphics.
-- No new DFRL:NewMod: the existing Modules settings grid is capacity-limited.
-- This file only manages decorative regions; all action IDs, drag/drop, click,
-- cooldown, macro and keybinding handling remains owned by the Bars module.

local Skins = {
    initialized = false,
    entries = {},
}
DFRL.actionButtonSkins = Skins

local WHITE = "Interface\\Buttons\\WHITE8X8"

local function MakeLine(holder, anchorA, xA, yA, anchorB, xB, yB, horizontal)
    local texture = holder:CreateTexture(nil, "OVERLAY")
    texture:SetTexture(WHITE)
    texture:SetPoint(anchorA, holder, anchorA, xA, yA)
    texture:SetPoint(anchorB, holder, anchorB, xB, yB)
    if horizontal then texture:SetHeight(2) else texture:SetWidth(2) end
    return texture
end

local function MakeModernBorder(button)
    -- Use only named texture layers supported by legacy clients; do not pass
    -- numeric texture sublevels or borrow Retail-only button APIs.
    local holder = CreateFrame("Frame", nil, button)
    holder:SetAllPoints(button)
    holder:SetFrameLevel(button:GetFrameLevel() + 2)
    holder:EnableMouse(false)
    local lines = {
        MakeLine(holder, "TOPLEFT", -1, 1, "TOPRIGHT", 1, 1, true),
        MakeLine(holder, "BOTTOMLEFT", -1, -1, "BOTTOMRIGHT", 1, -1, true),
        MakeLine(holder, "TOPLEFT", -1, 1, "BOTTOMLEFT", -1, -1, false),
        MakeLine(holder, "TOPRIGHT", 1, 1, "BOTTOMRIGHT", 1, -1, false),
    }
    holder:Hide()
    return holder, lines
end

local function HideOriginals(entry)
    entry.savedVisibility = {}
    for i = 1, table.getn(entry.originals) do
        local original = entry.originals[i]
        entry.savedVisibility[i] = original:IsShown()
        original:Hide()
    end
end

local function RestoreOriginals(entry)
    if not entry.savedVisibility then return end
    for i = 1, table.getn(entry.originals) do
        local original = entry.originals[i]
        if entry.savedVisibility[i] then original:Show() else original:Hide() end
    end
    entry.savedVisibility = nil
end

function Skins:Tint(color)
    color = color or (DFRL.GetTempDB and DFRL:GetTempDB("Bars", "highlightColor"))
    if type(color) ~= "table" or type(color[1]) ~= "number"
        or type(color[2]) ~= "number" or type(color[3]) ~= "number" then
        color = {.50, .72, .88}
    end
    local visible = not DFRL.GetTempDB
        or DFRL:GetTempDB("Bars", "highlightShow") ~= false
    -- Keep the rectangular Modern border, but use graphite rather than
    -- the highlight color when the hover effect is switched off.
    local tint = visible and color or {.27, .39, .48}
    for i = 1, table.getn(self.entries) do
        local entry = self.entries[i]
        for j = 1, table.getn(entry.lines) do
            entry.lines[j]:SetVertexColor(tint[1], tint[2], tint[3], .95)
        end
    end
end

function Skins:RefreshHighlights()
    -- NewCallbacks replaces the Bars handler; update the actual hover
    -- textures as well as Modern Dark's decorative border tint.
    local color = DFRL:GetTempDB("Bars", "highlightColor") or {1, .82, 0}
    if type(color) ~= "table" or type(color[1]) ~= "number"
        or type(color[2]) ~= "number" or type(color[3]) ~= "number" then
        color = {1, .82, 0}
    end
    local visible = DFRL:GetTempDB("Bars", "highlightShow") ~= false
    local black = color[1] == 0 and color[2] == 0 and color[3] == 0
    for i = 1, table.getn(self.entries) do
        local button = self.entries[i].button
        local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
        if highlight then
            highlight:SetVertexColor(color[1], color[2], color[3])
            highlight:SetBlendMode(black and "BLEND" or "ADD")
            highlight:SetAlpha(visible and 1 or 0)
        end
    end
    self:Tint(color)
end

function Skins:Apply(themeId)
    if not self.initialized then return end
    local modern = themeId == "modern"
    for i = 1, table.getn(self.entries) do
        local entry = self.entries[i]
        if modern then
            if not entry.modern then
                HideOriginals(entry)
                entry.modern = true
            end
            entry.holder:Show()
        else
            entry.holder:Hide()
            if entry.modern then
                RestoreOriginals(entry)
                entry.modern = false
            end
        end
    end
    if modern then self:Tint() end
end

function DFRL.InitActionButtonSkins(buttonTypes)
    if Skins.initialized then return true end
    if type(buttonTypes) ~= "table" then return false end

    for _, prefix in ipairs(buttonTypes) do
        for i = 1, 12 do
            local button = _G[prefix .. i]
            if button then
                local holder, lines = MakeModernBorder(button)
                local originals = {}
                if button.DFRL_BorderOverlay then
                    table.insert(originals, button.DFRL_BorderOverlay)
                end
                -- These textures exist only for ActionButton1-12, not
                -- multibars/pet/stances/bonus bars.
                if prefix == "ActionButton" then
                    local border = _G["DFRL_ActionButtonBorder" .. i]
                    local bg = _G["DFRL_ActionButtonBg" .. i]
                    if border then table.insert(originals, border) end
                    if bg then table.insert(originals, bg) end
                end
                table.insert(Skins.entries, {
                    button = button,
                    holder = holder,
                    lines = lines,
                    originals = originals,
                    modern = false,
                })
            end
        end
    end

    Skins.initialized = true
    if DFRL.theme then
        DFRL.theme:AddListener(function(selected) Skins:Apply(selected) end)
    end
    -- These callbacks replace the initial Bars callbacks; update both the
    -- native highlights and the reversible Modern border tint.
    DFRL:NewCallbacks("Bars", {
        highlightColor = function() Skins:RefreshHighlights() end,
        highlightShow = function() Skins:RefreshHighlights() end,
    })
    Skins:Apply(DFRL.theme and DFRL.theme:GetSelected())
    return true
end
