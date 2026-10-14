-- fruUI Milestone 3C.1: modern cast-bar appearance only.
-- No module registration, cast timing changes, or dependency on ClassicAPI.
-- All created regions are cosmetic and use stock WoW 1.12 texture layers.

local Skin = {entries = {}, listening = false}
DFRL.castbarSkins = Skin

local WHITE = "Interface\\Buttons\\WHITE8X8"
-- Success should read as positive feedback, not a full neon-green flash.
local SUCCESS = {.32, .66, .51}

function Skin:QuietPlayerCompletion()
    local entry = self.entries.player
    return entry and entry.modern == true or false
end

function Skin:StylePlayerCompletion(setup)
    if not self:QuietPlayerCompletion() then return false end
    setup.barTexture:SetVertexColor(unpack(SUCCESS))
    if setup.flashTex then setup.flashTex:Hide() end
    return true
end

local function Line(frame, a, x1, y1, b, x2, y2, horizontal)
    local line = frame:CreateTexture(nil, "ARTWORK")
    line:SetTexture(WHITE)
    line:SetVertexColor(.25, .37, .47, 1)
    line:SetPoint(a, frame, a, x1, y1)
    line:SetPoint(b, frame, b, x2, y2)
    if horizontal then line:SetHeight(1) else line:SetWidth(1) end
    line:Hide()
    return line
end

local function Capture(entry)
    local setup = entry.setup
    local original = {}
    for _, name in ipairs({"backdrop", "borderframe", "dropshadow"}) do
        local region = setup[name]
        if region then original[name .. "Alpha"] = region:GetAlpha() end
    end
    original.fillTexture = setup.barTexture:GetTexture()
    if setup.flashTex then original.flashTexture = setup.flashTex:GetTexture() end
    entry.original = original
end

local function Toggle(entry, modern)
    local setup = entry.setup
    if modern then
        -- Preserve all color updates, cast success/interruption state,
        -- spark positions and dimensions. Only substitute flat surfaces.
        setup.barTexture:SetTexture(WHITE)
        if setup.flashTex then setup.flashTex:SetTexture(WHITE) end
        for _,name in ipairs({"backdrop", "borderframe", "dropshadow"}) do
            if setup[name] then setup[name]:SetAlpha(0) end
        end
        entry.track:Show()
        entry.mute:Show()
        for i=1,table.getn(entry.lines) do entry.lines[i]:Show() end
    else
        local original = entry.original
        setup.barTexture:SetTexture(original.fillTexture)
        if setup.flashTex then setup.flashTex:SetTexture(original.flashTexture) end
        for _,name in ipairs({"backdrop", "borderframe", "dropshadow"}) do
            local region = setup[name]
            if region then region:SetAlpha(original[name .. "Alpha"]) end
        end
        entry.track:Hide()
        entry.mute:Hide()
        for i=1,table.getn(entry.lines) do entry.lines[i]:Hide() end
    end
    entry.modern = modern

    -- Switching themes during the short completion/fade window must update
    -- the completion color immediately, not wait for the next spell cast.
    -- Normal casting and channeling colors remain owned by the Cast module.
    local state = setup.state
    if entry.id == "player" and state and state.mode == "flash"
        and setup.frame:IsShown() then
        if modern then
            Skin:StylePlayerCompletion(setup)
        else
            setup.barTexture:SetVertexColor(0, 1, 0)
            if setup.flashTex and state.flash then
                setup.flashTex:SetVertexColor(0, 1, 0)
                setup.flashTex:Show()
            end
        end
    end
end

function Skin:Apply(theme)
    local modern = theme == "modern"
    for _,entry in pairs(self.entries) do
        -- Avoid mutating legacy textures for unselected themes until needed.
        if entry.modern ~= modern then Toggle(entry, modern) end
    end
end

function DFRL.InitCastbarSkin(id, setup)
    if id ~= "player" and id ~= "target" then return false end
    if Skin.entries[id] then return true end
    if not setup or not setup.frame or not setup.barTexture
        or not setup.backdrop or not setup.borderframe then return false end

    local f = setup.frame
    local entry = {id = id, setup = setup, modern = false, lines = {}}

    -- A separate matte avoids fighting Cast/TargetCastbar appearance
    -- callbacks, which continue recoloring their original hidden backdrop.
    local track = f:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints(f)
    track:SetTexture(WHITE)
    track:SetVertexColor(.055, .080, .11, .98)
    track:Hide()
    entry.track = track

    local mute = f:CreateTexture(nil, "ARTWORK")
    mute:SetAllPoints(setup.barTexture)
    mute:SetTexture(WHITE)
    mute:SetVertexColor(.028, .045, .060, .28)
    mute:Hide()
    entry.mute = mute

    -- One crisp rectangle, no doubled inner bar outlines.
    entry.lines[1] = Line(f, "TOPLEFT", -1, 1, "TOPRIGHT", 1, 1, true)
    entry.lines[2] = Line(f, "BOTTOMLEFT", -1, -1, "BOTTOMRIGHT", 1, -1, true)
    entry.lines[3] = Line(f, "TOPLEFT", -1, 1, "BOTTOMLEFT", -1, -1, false)
    entry.lines[4] = Line(f, "TOPRIGHT", 1, 1, "BOTTOMRIGHT", 1, -1, false)
    Capture(entry)
    Skin.entries[id] = entry

    if not Skin.listening and DFRL.theme then
        Skin.listening = true
        DFRL.theme:AddListener(function(selected) Skin:Apply(selected) end)
    end
    Skin:Apply(DFRL.theme and DFRL.theme:GetSelected())
    return true
end
