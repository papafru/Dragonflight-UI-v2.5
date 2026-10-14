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
function methods:SetAllPoints(parent) self.allPoints = parent end
function methods:SetPoint(...) table.insert(self.points, {...}) end
function methods:ClearAllPoints() self.points = {} end
function methods:GetNumPoints() return #self.points end
function methods:GetPoint(i) return unpack(self.points[i]) end
function methods:SetTexture(p) self.texture = p end
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
PlayerLevelText = Region("FontString", PlayerFrame)
PlayerLevelText:SetPoint("RIGHT", PlayerFrame, "RIGHT", -14, 25)
PlayerLevelText:SetTextColor(.92, .69, .11)
TargetLevelText = Region("FontString", TargetFrame)
TargetLevelText:SetPoint("CENTER", TargetFrame, "CENTER", -102, 25)
TargetLevelText:SetTextColor(.81, .71, .18)

local function Bar()
    local b = Region("StatusFrame")
    b.level = 8
    b.value = 35
    b.fillTexture = "existing-color-dynamic-health-art"
    b.mouseHandler = function() return "preserved" end
    return b
end
local playerHealth, playerMana = Bar(), Bar()
local targetHealth, targetMana = Bar(), Bar()
targetMana:Hide()
local savedHandler = targetHealth.mouseHandler
local savedAlpha = {
    player = {PlayerFrameTexture:GetAlpha(), PlayerFrameBackground:GetAlpha(), PlayerFrame.portrait:GetAlpha()},
    target = {TargetFrameTexture:GetAlpha(), TargetFrameBackground:GetAlpha(), TargetFrame.portrait:GetAlpha()},
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
eq(DFRL.InitUnitFrameSkins("player", playerHealth, playerMana), true, "Player initialization")
eq(style.listening, true, "Listener connected")
eq(#listeners, 1, "One theme listener for both unit frames")
eq(numFrames, 7, "One rectangular outline and two bar outlines per unit, plus target watcher")
eq(numTextures, 32, "16 textures per unit: panel + five lines + two bar mats + eight lines")
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
    eq(#e.bars, 2, "Exactly two decorative status-bar treatments")
    for _,bar in ipairs(e.bars) do
        eq(bar.matte.layer, "BACKGROUND", "Graphite bar backing uses background")
        eq(bar.matte.shown, false, "Graphite bar backing starts hidden")
        eq(bar.outline.shown, false, "Bar outline starts hidden")
        eq(bar.outline.mouseEnabled, false, "Bar decoration is mouse-inert")
        eq(bar.outline.allPoints, bar.bar, "Bar decoration follows existing geometry")
    end
end
eq(TargetFrame.portrait:GetAlpha(), savedAlpha.target[3], "Original target portrait initially unchanged")
eq(TargetFrameTexture:GetAlpha(), savedAlpha.target[1], "Original target art unchanged")
eq(targetMana:IsShown(), false, "Existing hidden target mana remains hidden")

local function Switch(id)
    selected = id
    for _,listener in ipairs(listeners) do listener(id) end
end
Switch("modern")
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
    end
    for _,bar in ipairs(e.bars) do
        eq(bar.matte.shown, true, "Modern matte visible")
        eq(bar.outline.shown, true, "Modern thin outline visible")
    end
end
eq(targetMana:IsShown(), false, "Hidden target mana remains hidden during style")
eq(playerHealth.value, 35, "Health value unchanged")
eq(targetHealth.mouseHandler, savedHandler, "Click handling unchanged")
eq(PlayerFrame.name.textColor[1], .87, "Modern title color")
eq(TargetFrame.portrait.shown, true, "Portrait hidden via reversible alpha, not destructive Hide()")

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
for _,id in ipairs({"player", "target"}) do
    local e = style.entries[id]
    eq(e.modern, false, "Original mode restored")
    eq(e.panel.shown, false, "Modern rectangle hidden when returning to Fantasy")
    eq(e.outline.shown, false, "Modern border hidden when returning to Fantasy")
    for _,bar in ipairs(e.bars) do
        eq(bar.matte.shown, false, "Custom matte removed from Fantasy")
        eq(bar.outline.shown, false, "Custom thin outline removed from Fantasy")
    end
    for i,region in ipairs(e.ornate) do
        eq(region:GetAlpha(), savedAlpha[id][i], "Exact original alpha preserved")
    end
end
eq(TargetFrameTexture.texture, "new-elite-frame-art", "Dynamic elite artwork survives theme switching")
eq(PlayerFrame.name.points[1][1], savedAnchors.playerName[1], "Player name restored anchor")
eq(TargetFrame.name.points[1][1], savedAnchors.targetName[1], "Target name restored anchor")
eq(TargetFrame.name.justify, "RIGHT", "Original target name justification restored")
eq(PlayerLevelText.points[1][1], savedAnchors.playerLevel[1], "Player level restored anchor")
eq(TargetLevelText.points[1][1], savedAnchors.targetLevel[1], "Target level restored anchor")
eq(PlayerFrame.name.textColor[1], oldColor[1], "Player name original color restored")
eq(TargetFrame.portrait:GetAlpha(), .74, "Target 3D portrait original alpha restored")
eq(targetMana.shown, false, "Hidden resource frame never forced visible")
eq(numFrames, originalFrames, "No new objects during switch")

Switch("modern")
Switch(nil)
eq(style.entries.player.panel.shown, false, "Existing Appearance restores Fantasy visuals")
eq(style.entries.target.panel.shown, false, "Existing Appearance hides rectangular art")
eq(PlayerFrame.portrait:GetAlpha(), .83, "Existing Appearance portrait alpha restored")
eq(DFRL.InitUnitFrameSkins("player", playerHealth, playerMana), true, "Idempotent init")
eq(#listeners, 1, "No duplicate theme listener")
eq(numFrames, originalFrames, "No duplicated frames from initialization")
eq(numTextures, originalTextures, "No duplicated textures from initialization")
eq(DFRL.modules, nil, "No extra Modules grid toggle")
print("PASS Milestone 3B rectangular unit frames: " .. checks .. " assertions")
