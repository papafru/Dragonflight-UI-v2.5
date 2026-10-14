-- fruUI Milestone 3B: rectangular, portrait-free unit frame smoke tests.
-- Run with Lua 5.1: lua5.1 tests/theme_unit_skins.lua
local checks = 0
local function eq(actual, expected, message)
    checks = checks + 1
    if actual ~= expected then
        error(message .. " expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end
if not table.getn then table.getn = function(t) return #t end end

local numFrames, numTextures = 0, 0
local methods = {}
local function Region(kind, parent)
    local o = {kind = kind, parent = parent, shown = true, alpha = 1,
        children = {}, points = {}, level = 5, textColor = {1, .8, 0}, scripts = {}}
    setmetatable(o, {__index = methods})
    if parent then table.insert(parent.children, o) end
    return o
end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown end
function methods:SetAlpha(a) self.alpha = a end
function methods:GetAlpha() return self.alpha end
function methods:SetFrameLevel(n) self.level = n end
function methods:GetFrameLevel() return self.level end
function methods:EnableMouse(b) self.mouseEnabled = b end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:GetHeight() return self.height end
function methods:GetWidth() return self.width end
function methods:SetAllPoints(parent) self.allPoints = parent end
function methods:SetPoint(...) table.insert(self.points, {...}) end
function methods:ClearAllPoints() self.points = {} end
function methods:GetNumPoints() return #self.points end
function methods:GetPoint(i) return unpack(self.points[i]) end
function methods:SetTexture(p) self.texture = p end
function methods:GetTexture() return self.texture end
function methods:GetVertexColor() return unpack(self.vertexColor) end
function methods:Update()
    self.updateCalls = (self.updateCalls or 0) + 1
    if self.fill then self.fill:SetHeight(self:GetHeight()) end
end
function methods:SetVertexColor(...) self.vertexColor = {...} end
function methods:SetTextColor(...) self.textColor = {...} end
function methods:GetTextColor() return unpack(self.textColor) end
function methods:SetJustifyH(v) self.justify = v end
function methods:GetJustifyH() return self.justify end
function methods:SetText(t) self.text = t end
function methods:SetValue(v) self.value = v end
function methods:SetScript(name, fn) self.scripts[name] = fn end
function methods:RegisterEvent(name) self.events = self.events or {}; self.events[name] = true end
function methods:CreateTexture(name, layer, template)
    eq(template, nil, "1.12 CreateTexture has no numeric sublevel")
    local obj = Region("Texture", self)
    obj.layer = layer
    numTextures = numTextures + 1
    return obj
end
function methods:CreateFontString(_, layer, font)
    local obj = Region("FontString", self)
    obj.layer = layer
    obj.font = font
    return obj
end
function CreateFrame(kind, _, parent)
    numFrames = numFrames + 1
    return Region(kind, parent)
end

local function Owner(name, portraitAlpha, artAlpha, bgAlpha)
    local frame = Region("Frame")
    frame.name = Region("FontString", frame)
    frame.name:SetPoint("LEFT", frame, "LEFT", 85, 25)
    frame.name:SetTextColor(.95, .65, .20)
    frame.name:SetJustifyH(name == "target" and "RIGHT" or "LEFT")
    frame.portrait = Region("Model", frame)
    frame.portrait:SetAlpha(portraitAlpha)
    local art = Region("Texture", frame)
    art:SetAlpha(artAlpha)
    local background = Region("Texture", frame)
    background:SetAlpha(bgAlpha)
    return frame, art, background
end
local playerArt, playerBG, targetArt, targetBG
PlayerFrame, playerArt, playerBG = Owner("player", .83, .78, .4)
TargetFrame, targetArt, targetBG = Owner("target", .74, .55, .23)
PlayerFrameTexture, PlayerFrameBackground = playerArt, playerBG
TargetFrameTexture, TargetFrameBackground = targetArt, targetBG

-- Legacy FrameXML globals are not guaranteed to alias frame.portrait.
-- The live client showed TargetPortrait leaking beside the Modern rectangle.
PlayerPortrait = Region("Texture", PlayerFrame)
PlayerPortrait:SetAlpha(.68)
TargetPortrait = Region("Texture", TargetFrame)
TargetPortrait:SetAlpha(.61)
PlayerFramePortrait = PlayerFrame.portrait -- intentional duplicate alias
TargetFramePortrait = TargetFrame.portrait
TargetFrameNameBackground = Region("Texture", TargetFrame)
TargetFrameNameBackground:SetAlpha(.42)

PlayerPVPIcon = Region("Texture", PlayerFrame)
PlayerPVPIcon:SetPoint("CENTER", PlayerFrame, "LEFT", -42, -13)
PlayerPVPIcon:SetWidth(64)
PlayerPVPIcon:SetHeight(64)
TargetPVPIcon = Region("Texture", TargetFrame)
TargetPVPIcon:SetPoint("TOPRIGHT", TargetFrame, "TOPRIGHT", 22, -11)
TargetPVPIcon:SetWidth(64)
TargetPVPIcon:SetHeight(64)
TargetPVPIcon:Hide() -- prevent a style switch from re-enabling hidden icons
PlayerLevelText = Region("FontString", PlayerFrame)
PlayerLevelText:SetPoint("RIGHT", PlayerFrame, "RIGHT", -14, 25)
PlayerLevelText:SetTextColor(.92, .69, .11)
TargetLevelText = Region("FontString", TargetFrame)
TargetLevelText:SetPoint("CENTER", TargetFrame, "CENTER", -102, 25)
TargetLevelText:SetTextColor(.81, .71, .18)

local function Bar(isHealth)
    local b = Region("StatusFrame")
    b.level = 8
    b.value = 35
    b:SetHeight(isHealth and 30 or 12)
    b.fill = b:CreateTexture(nil, "ARTWORK")
    b.fill:SetTexture(isHealth and "original-beveled-health.tga" or "original-mana.tga")
    b.fill:SetVertexColor(isHealth and 0 or 1, isHealth and 1 or 0, 0, 1)
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    b.bg:SetVertexColor(0, 0, 0, .5)
    b.cutoutTexture = b.fill:GetTexture()
    b.mouseHandler = function() return "preserved" end
    b:Update()
    return b
end
local playerHealth, playerMana = Bar(true), Bar(false)
local targetHealth, targetMana = Bar(true), Bar(false)
-- The Mini module creates independently anchored 60px ToT status bars.
TargetofTargetFrame = Region("Frame")
TargetofTargetFrame.name = Region("FontString", TargetofTargetFrame)
TargetofTargetFrame.name:SetPoint("TOPLEFT", TargetofTargetFrame, "TOPLEFT", 40, 25)
TargetofTargetFrame.portrait = Region("Texture", TargetofTargetFrame)
TargetofTargetTexture = Region("Texture", TargetofTargetFrame)
TargetofTargetPortrait = Region("Texture", TargetofTargetFrame)
TargetofTargetBackground = Region("Texture", TargetofTargetFrame)
local totHealth, totMana = Bar(true), Bar(false)
totHealth:SetWidth(60)
totHealth:SetHeight(13)
totHealth:SetPoint("LEFT", TargetofTargetFrame, "LEFT", 40, 1)
totMana:SetWidth(60)
totMana:SetHeight(7)
totMana:SetPoint("TOPLEFT", totHealth, "BOTTOMLEFT", 0, 1)
local totOriginalManaPoint = {totMana:GetPoint(1)}
local totOriginalNamePoint = {TargetofTargetFrame.name:GetPoint(1)}
local totOriginalArt = {TargetofTargetTexture:GetAlpha(),TargetofTargetPortrait:GetAlpha(),TargetofTargetBackground:GetAlpha()}
local combatParent = Region("Frame", PlayerFrame)
combatParent:SetAlpha(.82)
local combatRing = combatParent:CreateTexture(nil, "OVERLAY")
combatRing:SetAlpha(.65)
local restParent = Region("Frame", PlayerFrame)
restParent:SetAlpha(.55)
local restRing = restParent:CreateTexture(nil, "OVERLAY")
restRing:SetAlpha(.25)
local restAnimation = Region("Frame")
restAnimation:SetAlpha(.73)
local effects = {combatParent, restParent, restAnimation}
local expectedEffectAlpha = {.82, .55, .73}
local mockCombat = false
function UnitAffectingCombat(unit)
    eq(unit, "player", "Combat state queried for player only")
    return mockCombat
end
targetMana:Hide()
local savedHandler = targetHealth.mouseHandler
local savedAlpha = {
    player = {PlayerFrameTexture:GetAlpha(), PlayerFrameBackground:GetAlpha(), PlayerFrame.portrait:GetAlpha()},
    target = {TargetFrameTexture:GetAlpha(), TargetFrameBackground:GetAlpha(), TargetFrame.portrait:GetAlpha()},
}
local originalRegions = {}
for _,region in ipairs({
    PlayerFrameTexture, PlayerFrameBackground, PlayerFrame.portrait,
    PlayerPortrait, TargetFrameTexture, TargetFrameBackground, TargetFrame.portrait,
    TargetPortrait, TargetFrameNameBackground,
    TargetofTargetFrame.portrait, TargetofTargetTexture,
    TargetofTargetPortrait, TargetofTargetBackground,
}) do
    originalRegions[region] = {alpha=region:GetAlpha(), shown=region:IsShown()}
end
local savedPvp = {
    player = {point={PlayerPVPIcon:GetPoint(1)},width=PlayerPVPIcon:GetWidth(),height=PlayerPVPIcon:GetHeight(),shown=PlayerPVPIcon:IsShown()},
    target = {point={TargetPVPIcon:GetPoint(1)},width=TargetPVPIcon:GetWidth(),height=TargetPVPIcon:GetHeight(),shown=TargetPVPIcon:IsShown()},
}
local savedAnchors = {
    playerName = {PlayerFrame.name:GetPoint(1)},
    targetName = {TargetFrame.name:GetPoint(1)},
    playerLevel = {PlayerLevelText:GetPoint(1)},
    targetLevel = {TargetLevelText:GetPoint(1)},
}
local oldColor = {PlayerFrame.name:GetTextColor()}
local selected, listeners = nil, {}
local classification = "normal"
local hasTarget = true
function UnitClassification(unit) eq(unit, "target", "Classification unit"); return classification end
function UnitExists(unit) eq(unit, "target", "Exists unit"); return hasTarget end
_G.DFRL = {
    themeUI = {palette = {modern = {accent = {.43, .72, .90}}}},
    theme = {
        GetSelected = function() return selected end,
        AddListener = function(_, listener) table.insert(listeners, listener) end,
    },
}
local root = string.match(arg[0], "^(.*[/\\])tests[/\\]") or ""
assert(loadfile(root .. "modules/unit/skins.lua"))()
local style = DFRL.unitFrameSkins
eq(style.listening, false, "No premature initialization")
eq(next(style.entries), nil, "No renderer before module setup")
eq(DFRL.InitUnitFrameSkins("pet", playerHealth, playerMana), false, "No unsupported unit")
eq(DFRL.InitUnitFrameSkins("player", nil, playerMana), false, "No health frame")
eq(numFrames, 0, "No frames on invalid init")

-- Target can initialize before Player. This is how these modules initialize.
eq(DFRL.InitUnitFrameSkins("target", targetHealth, targetMana), true, "Target initialization")
eq(DFRL.InitUnitFrameSkins("player", playerHealth, playerMana, effects), true, "Player initialization with animation parent references")
eq(DFRL.InitUnitFrameSkins("tot", totHealth, totMana), true, "Mini module's ToT frame initialization")
eq(style.listening, true, "Listener connected")
eq(#listeners, 1, "One theme listener for both unit frames")
eq(numFrames, 6, "One panel outline and watcher per unit, including Mini ToT")
eq(numTextures, 38, "Three units' original bars, Modern panels, tints, and effect textures")
eq(style.entries.tot.unit, "tot", "ToT has distinct renderer state")
eq(style.entries.tot.owner, TargetofTargetFrame, "ToT attaches to real Mini frame")
eq(style.entries.tot.pvpIcon, nil, "ToT doesn't borrow Player/Target shield")
eq(style.entries.tot.level, nil, "No required ToT level region")
eq(#style.entries.tot.bars, 2, "Mini's custom ToT health and resource bars styled")
eq(style.entries.player.modern, false, "Player starts unchanged")
eq(style.entries.target.modern, false, "Target starts unchanged")

for _,id in ipairs({"player", "target"}) do
    local e = style.entries[id]
    eq(e.owner, id == "player" and PlayerFrame or TargetFrame, "Rectangular panel parent")
    eq(e.panel.parent, e.owner, "Panel belongs to unit frame")
    eq(e.panel.layer, "BACKGROUND", "Panel drawn behind health fill")
    eq(e.panel.shown, false, "Fantasy does not display rectangular backdrop")
    eq(e.panel.points[1][1], "TOPLEFT", "Panel start anchored to health")
    eq(e.panel.points[1][2], e.health, "Panel start uses health bar")
    eq(e.panel.points[2][1], "BOTTOMRIGHT", "Panel bottom anchored to resource")
    eq(e.panel.points[2][2], e.resource, "Panel bottom uses mana bar")
    eq(e.outline.shown, false, "Outer border initially hidden")
    eq(e.outline.mouseEnabled, false, "Outer border cannot intercept clicks")
    eq(e.outline.points[1][2], e.panel, "Border follows panel")
    eq(#e.bars, 2, "Both existing status bars have reversible skin state")
    for index,skin in ipairs(e.bars) do
        eq(skin.isHealth, index == 1, "Health/resource type recorded")
        eq(skin.original, nil, "No original-state capture until theme changes")
        eq(skin.bar:GetHeight(), index == 1 and 30 or 12, "Legacy geometry untouched in Fantasy")
        eq(skin.bar.fill:GetTexture(), index == 1 and "original-beveled-health.tga" or "original-mana.tga", "Original textures untouched")
        eq(skin.bar.bg:GetVertexColor(), 0, "Original status background untouched")
        eq(skin.tint.layer, "OVERLAY", "Tint uses stock 1.12 overlay layer")
        eq(skin.tint.allPoints, skin.bar.fill, "Tint follows filled health/resource section")
        eq(skin.tint.shown, false, "Fantasy never displays color mute")
    end
end
eq(TargetFrame.portrait:GetAlpha(), savedAlpha.target[3], "Original target portrait initially unchanged")
eq(#style.entries.player.ornate, 4, "Player graphics include actual portrait global, without alias duplication")
eq(#style.entries.target.ornate, 5, "Target graphics include actual portrait and nameplate globals")
eq(style.playerWatcher.events.UNIT_PORTRAIT_UPDATE, true, "Player portrait reappearing events watched")
eq(style.targetWatcher.events.PLAYER_TARGET_CHANGED, true, "Target changes watched")
eq(style.playerWatcher.events.PLAYER_REGEN_DISABLED, true, "Combat start updates compact indicator")
eq(style.playerWatcher.events.PLAYER_REGEN_ENABLED, true, "Combat exit updates compact indicator")
eq(style.playerWatcher.events.PLAYER_UPDATE_RESTING, true, "Resting updates reassert concealment")
eq(style.entries.player.effects, effects, "Animation parents owned by Player code")
eq(style.totWatcher.events.UNIT_TARGET, true, "ToT updates when a unit's target changes")
eq(totHealth:GetWidth(), 60, "Mini ToT base health width untouched before selection")
eq(totMana:GetWidth(), 60, "Mini ToT base power width untouched before selection")
eq(TargetFrameTexture:GetAlpha(), savedAlpha.target[1], "Original target art unchanged")
eq(targetMana:IsShown(), false, "Existing hidden target mana remains hidden")

local function Switch(id)
    selected = id
    for _,listener in ipairs(listeners) do listener(id) end
end
Switch("modern")
eq(totHealth:GetWidth(), 86, "Modern ToT health fills a wider rectangular panel")
eq(totMana:GetWidth(), 86, "Modern ToT resource shares panel width")
eq(totHealth:GetHeight(), 16, "ToT health is legible at compact size")
eq(totMana:GetHeight(), 8, "ToT resource is intentionally secondary")
eq(totHealth.fill:GetTexture(), "Interface\\Buttons\\WHITE8X8", "ToT flat health fill")
eq(totMana.fill:GetTexture(), "Interface\\Buttons\\WHITE8X8", "ToT flat resource fill")
eq(totMana:GetPoint(1), "TOPLEFT", "Modern ToT power anchor type")
eq(select(2,totMana:GetPoint(1)), totHealth, "Modern ToT resource anchored below health")
eq(select(5,totMana:GetPoint(1)), -3, "Modern ToT health/power spacing")
eq(TargetofTargetTexture:IsShown(), false, "Modern hides Mini ToT frame art")
eq(TargetofTargetPortrait:IsShown(), false, "Modern hides original ToT portrait")
eq(TargetofTargetBackground:IsShown(), false, "Modern hides original ToT background")
eq(style.entries.tot.panel:IsShown(), true, "Modern ToT panel visible")
eq(TargetofTargetFrame.name:GetPoint(1), "TOPLEFT", "Modern ToT name in rectangular header")
eq(select(2,TargetofTargetFrame.name:GetPoint(1)),totHealth,"Modern ToT name positioned over custom bar")

-- Existing hostile target may have no power. Panels must close that gap and
-- reopen only when the Mini or Target module makes the power bar visible.
eq(select(2,style.entries.target.panel:GetPoint(2)),targetHealth,"Target no-power rectangle collapses")
targetMana:Show()
style:UpdateLayout("target")
eq(select(2,style.entries.target.panel:GetPoint(2)),targetMana,"Target power panel expands")
targetMana:Hide()
style:UpdateLayout("target")
eq(select(2,style.entries.target.panel:GetPoint(2)),targetHealth,"Target collapses after power loss")
totMana:Hide()
style:UpdateLayout("tot")
eq(select(2,style.entries.tot.panel:GetPoint(2)),totHealth,"ToT panel collapses without power")
totMana:Show()
style.totWatcher.scripts.OnEvent()
eq(select(2,style.entries.tot.panel:GetPoint(2)),totMana,"ToT panel expands after a power update")
Switch("modern")
eq(totHealth:GetWidth(),86,"Repeated Modern selection doesn't accumulate ToT width")
for _,id in ipairs({"player", "target"}) do
    local e = style.entries[id]
    eq(e.modern, true, "Modern state active")
    eq(e.panel.shown, true, "Modern panel is visible")
    eq(e.outline.shown, true, "Modern outline visible")
    eq(e.name.points[1][1], "TOPLEFT", "Unit name in rectangular header")
    eq(e.name.justify, "LEFT", "Modern name uses left-aligned text")
    eq(e.name.points[1][2], e.health, "Unit name placed above same health bar")
    eq(e.level.points[1][1], "TOPRIGHT", "Unit level in rectangular header")
    eq(e.level.points[1][2], e.health, "Unit level relative to same health bar")
    for _,original in ipairs(e.ornate) do
        eq(original:GetAlpha(), 0, "Circular/ornate originals transparent in Modern")
        eq(original:IsShown(), false, "Circular/ornate originals truly hidden in Modern")
    end
    local icon = e.pvpIcon
    eq(icon:GetWidth(), 34, "PvP icon compact width")
    eq(icon:GetHeight(), 34, "PvP icon compact height")
    eq(icon:GetPoint(1), "TOPLEFT", "PvP icon anchored to rectangle")
    eq(select(2, icon:GetPoint(1)), e.panel, "PvP icon follows current panel")
    for i,skin in ipairs(e.bars) do
        local bar = skin.bar
        eq(bar.fill:GetTexture(), "Interface\\Buttons\\WHITE8X8", "Flat fill replaces beveled artwork")
        eq(bar.cutoutTexture, "Interface\\Buttons\\WHITE8X8", "Damage cutouts match flat theme")
        eq(bar:GetHeight(), i == 1 and 20 or 10, "Modern health 20px and resource 10px with gap")
        eq(bar.bg:GetVertexColor(), .035, "Graphite replaces semitransparent black background")
        eq(bar.bg.vertexColor[4], .98, "Modern bar background opacity")
        eq(skin.original ~= nil, true, "Original bar texture and geometry captured")
        eq(bar.fill:GetHeight(), bar:GetHeight(), "Bar fill geometry recalculated after resize")
        eq(skin.tint.shown, true, "Softening overlay visible only in Modern")
        eq(skin.tint.vertexColor[4], .24, "Flat bar tint is subtle")
    end
end
eq(targetMana:IsShown(), false, "Hidden target mana remains hidden during style")
eq(playerHealth.value, 35, "Health value unchanged")
eq(playerHealth.fill.vertexColor[2], 1, "Reaction/class fill color remains controlled by bar")
eq(style.entries.player.combatEdge.vertexColor[1], .25, "Idle border remains muted")
for index,effect in ipairs(effects) do
    eq(effect:GetAlpha(), 0, "Modern conceals old circular status glow parents")
    eq(effect:IsShown(), true, "Modern does not interfere with animation show/hide")
end
eq(combatRing:GetAlpha(), .65, "Combat pulse texture alpha not overwritten")
mockCombat = true
style.playerWatcher.scripts.OnEvent()
eq(style.entries.player.combatEdge.vertexColor[1], .92, "Combat state is indicated by a red edge")
eq(style.entries.player.combatEdge.vertexColor[2], .29, "Combat indicator has subdued warm red")
combatRing:SetAlpha(1)
eq(combatParent:GetAlpha(), 0, "Continuously animated red circle still suppressed")
mockCombat = false
style.playerWatcher.scripts.OnEvent()
eq(style.entries.player.combatEdge.vertexColor[1], .25, "Combat edge returns to muted after leaving combat")
restRing:SetAlpha(.85)
eq(restParent:GetAlpha(), 0, "Animated resting ring still suppressed")
eq(restAnimation:GetAlpha(), 0, "Old rest flipbook also suppressed")
-- Target reaction can change while Modern is active. Never hardcode status color.
targetHealth.fill:SetVertexColor(.8, .22, .1, 1)
eq(targetHealth.fill.vertexColor[1], .8, "Health reaction recolor remains possible in Modern")
eq(targetHealth.fill:GetTexture(), "Interface\\Buttons\\WHITE8X8", "Dynamic recolor doesn't restore old texture")
eq(targetHealth.mouseHandler, savedHandler, "Click handling unchanged")
eq(PlayerFrame.name.textColor[1], .87, "Modern title color")
eq(TargetFrame.portrait.shown, false, "Modern explicitly hides portrait")
eq(TargetPortrait.shown, false, "Actual named TargetPortrait hidden")
eq(PlayerPortrait.shown, false, "Actual named PlayerPortrait hidden")
eq(PlayerPVPIcon:IsShown(), true, "Visible Player PvP marker remains visible")
eq(TargetPVPIcon:IsShown(), false, "Hidden Target PvP marker stays hidden")
-- Reproduce vanilla portrait code unexpectedly showing/retinting the region.
TargetPortrait:Show()
TargetPortrait:SetAlpha(.4)
style.targetWatcher.scripts.OnEvent()
eq(TargetPortrait:IsShown(), false, "Target portrait event reasserts hide")
eq(TargetPortrait:GetAlpha(), 0, "Target portrait event reasserts opacity")
PlayerPortrait:Show()
PlayerPortrait:SetAlpha(.5)
style.playerWatcher.scripts.OnEvent()
eq(PlayerPortrait:IsShown(), false, "Player portrait event reasserts hide")

-- The original target border still receives classification updates under the
-- transparent layer; returning to Fantasy must reveal the latest texture.
TargetFrameTexture:SetTexture("new-elite-frame-art")
classification = "rareelite"
style.targetWatcher.scripts.OnEvent()
eq(style.entries.target.classLabel.text, "RARE ELITE", "Rare elite classification stays visible")
eq(style.entries.target.classLabel.shown, true, "Rare elite badge visible")
classification = "worldboss"
style.targetWatcher.scripts.OnEvent()
eq(style.entries.target.classLabel.text, "BOSS", "World boss classification displayed")
hasTarget = false
style.targetWatcher.scripts.OnEvent()
eq(style.entries.target.classLabel.shown, false, "Badge hides when target disappears")
hasTarget = true
classification = "elite"
style.targetWatcher.scripts.OnEvent()
eq(style.entries.target.classLabel.text, "ELITE", "Elite classification displayed")
eq(style.entries.target.classLabel.shown, true, "Elite badge visible")
classification = "normal"
style.targetWatcher.scripts.OnEvent()
eq(style.entries.target.classLabel.shown, false, "Normal mobs have no badge")

local originalFrames, originalTextures = numFrames, numTextures
Switch("modern")
eq(numFrames, originalFrames, "Repeat Modern selection creates no frames")
eq(numTextures, originalTextures, "Repeat Modern selection creates no textures")
Switch("fantasy")
eq(totHealth:GetHeight(),13,"Fantasy restores original ToT health height")
eq(totMana:GetHeight(),7,"Fantasy restores original ToT power height")
eq(totHealth:GetWidth(),60,"Fantasy restores original ToT health width")
eq(totMana:GetWidth(),60,"Fantasy restores original ToT power width")
local q,ref,rp,dx,dy=totMana:GetPoint(1)
eq(q,totOriginalManaPoint[1],"ToT resource anchor type restored")
eq(ref,totOriginalManaPoint[2],"ToT resource original health anchor restored")
eq(rp,totOriginalManaPoint[3],"ToT relative anchor restored")
eq(dx,totOriginalManaPoint[4],"ToT power horizontal offset restored")
eq(dy,totOriginalManaPoint[5],"ToT power vertical offset restored")
eq(TargetofTargetFrame.name:GetPoint(1),totOriginalNamePoint[1],"ToT name original anchor restored")
eq(TargetofTargetTexture:IsShown(),true,"Fantasy restores ToT frame artwork")
eq(TargetofTargetPortrait:IsShown(),true,"Fantasy restores ToT circular portrait")
eq(TargetofTargetBackground:IsShown(),true,"Fantasy restores ToT decorative background")
eq(totHealth.fill:GetTexture(),"original-beveled-health.tga","ToT original health texture restored")
eq(totMana.fill:GetTexture(),"original-mana.tga","ToT original resource texture restored")
for _,id in ipairs({"player", "target"}) do
    local e = style.entries[id]
    eq(e.modern, false, "Original mode restored")
    eq(e.panel.shown, false, "Modern rectangle hidden when returning to Fantasy")
    eq(e.outline.shown, false, "Modern border hidden when returning to Fantasy")
    for index,skin in ipairs(e.bars) do
        local bar = skin.bar
        local originalTexture = index == 1 and "original-beveled-health.tga" or "original-mana.tga"
        eq(bar.fill:GetTexture(), originalTexture, "Exact original beveled fill restored")
        eq(bar.cutoutTexture, originalTexture, "Original damage cutout texture restored")
        eq(bar:GetHeight(), index == 1 and 30 or 12, "Original bar height restored")
        eq(bar.bg:GetVertexColor(), 0, "Original bar background red restored")
        eq(bar.bg.vertexColor[4], .5, "Original background alpha restored")
        eq(skin.original, nil, "Per-bar saved skin state cleared")
        eq(bar.fill:GetHeight(), bar:GetHeight(), "Restored fill geometry recalculated")
        eq(skin.tint.shown, false, "Switching to Fantasy hides tint")
    end
    for i,region in ipairs(e.ornate) do
        local saved = originalRegions[region]
        eq(region:GetAlpha(), saved.alpha, "Exact original alpha preserved")
        eq(region:IsShown(), saved.shown, "Exact original visibility preserved")
    end
    local icon = e.pvpIcon
    local initial = savedPvp[id]
    eq(icon:GetWidth(), initial.width, "PvP icon width restored")
    eq(icon:GetHeight(), initial.height, "PvP icon height restored")
    eq(icon:IsShown(), initial.shown, "PvP icon original visibility remains")
    local x, ref, rp, dx, dy = icon:GetPoint(1)
    eq(x, initial.point[1], "PvP original point restored")
    eq(ref, initial.point[2], "PvP original reference frame restored")
    eq(rp, initial.point[3], "PvP original relative point restored")
    eq(dx, initial.point[4], "PvP original x-offset restored")
    eq(dy, initial.point[5], "PvP original y-offset restored")
end
for i,effect in ipairs(effects) do
    eq(effect:GetAlpha(), expectedEffectAlpha[i], "Fantasy restores exact glow parent alpha")
end
eq(combatRing:GetAlpha(), 1, "Dynamic combat texture value remains controlled by original Player module")
eq(TargetFrameTexture.texture, "new-elite-frame-art", "Dynamic elite artwork survives theme switching")
eq(PlayerFrame.name.points[1][1], savedAnchors.playerName[1], "Player name restored anchor")
eq(TargetFrame.name.points[1][1], savedAnchors.targetName[1], "Target name restored anchor")
eq(TargetFrame.name.justify, "RIGHT", "Original target name justification restored")
eq(PlayerLevelText.points[1][1], savedAnchors.playerLevel[1], "Player level restored anchor")
eq(TargetLevelText.points[1][1], savedAnchors.targetLevel[1], "Target level restored anchor")
eq(PlayerFrame.name.textColor[1], oldColor[1], "Player name original color restored")
eq(TargetFrame.portrait:GetAlpha(), .74, "Target 3D portrait original alpha restored")
eq(TargetPortrait:IsShown(), true, "Named target portrait reappears in Fantasy")
eq(TargetPortrait:GetAlpha(), .61, "Named target portrait alpha restored")
eq(PlayerPortrait:IsShown(), true, "Named player portrait reappears in Fantasy")
eq(targetMana.shown, false, "Hidden resource frame never forced visible")
eq(targetHealth.fill.vertexColor[1], .8, "Reaction color survives return to Fantasy")
eq(targetHealth.fill.vertexColor[2], .22, "Reaction color remains unchanged by styling")
eq(numFrames, originalFrames, "No new objects during switch")

Switch("modern")
Switch(nil)
eq(style.entries.player.panel.shown, false, "Existing Appearance restores Fantasy visuals")
eq(style.entries.target.panel.shown, false, "Existing Appearance hides rectangular art")
eq(style.entries.tot.panel.shown, false, "Existing Appearance hides Modern ToT artwork")
eq(totHealth:GetWidth(),60,"Existing Appearance keeps original Mini ToT width")
eq(PlayerFrame.portrait:GetAlpha(), .83, "Existing Appearance portrait alpha restored")
eq(PlayerPortrait:IsShown(), true, "Existing Appearance restores actual portrait global")
eq(PlayerPVPIcon:GetWidth(), 64, "Existing Appearance preserves PvP marker size")
eq(playerHealth.fill:GetTexture(), "original-beveled-health.tga", "Existing Appearance restores original fill")
eq(playerHealth:GetHeight(), 30, "Existing Appearance restores original height")
eq(combatParent:GetAlpha(), .82, "Existing Appearance preserves original combat overlay alpha")
eq(restParent:GetAlpha(), .55, "Existing Appearance preserves original resting overlay alpha")
eq(DFRL.InitUnitFrameSkins("player", playerHealth, playerMana), true, "Idempotent init")
eq(#listeners, 1, "No duplicate theme listener")
eq(numFrames, originalFrames, "No duplicated frames from initialization")
eq(numTextures, originalTextures, "No duplicated textures from initialization")
eq(DFRL.modules, nil, "No extra Modules grid toggle")
print("PASS Milestone 3B rectangular unit frames: " .. checks .. " assertions")
