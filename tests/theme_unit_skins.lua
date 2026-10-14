-- Milestone 3B: stock WoW 1.12-compatible player/target visual test.
-- Run: lua5.1 tests/theme_unit_skins.lua
local checks = 0
local function eq(actual, expected, note)
    checks = checks + 1
    if actual ~= expected then
        error(note .. " expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end
if not table.getn then table.getn = function(x) return #x end end
local createdFrames = 0
local createdTextures = 0
local frameMethods = {}
local function region(kind, parent)
    local obj={kind=kind,parent=parent,shown=true,children={},scripts={},level=5}
    setmetatable(obj,{__index=frameMethods})
    if parent then table.insert(parent.children,obj) end
    return obj
end
function frameMethods:SetAllPoints(parent) self.allPoints=parent end
function frameMethods:SetFrameLevel(v) self.level=v end
function frameMethods:GetFrameLevel() return self.level end
function frameMethods:EnableMouse(v) self.mouseEnabled=v end
function frameMethods:Show() self.shown=true end
function frameMethods:Hide() self.shown=false end
function frameMethods:IsShown() return self.shown end
function frameMethods:SetTexture(texture) self.texture=texture end
function frameMethods:SetPoint(...) table.insert(self.points,{...}) end
function frameMethods:SetVertexColor(...) self.color={...} end
function frameMethods:SetWidth(v) self.width=v end
function frameMethods:SetHeight(v) self.height=v end
function frameMethods:SetValue(v) self.value=v end
function frameMethods:CreateTexture(_, layer, forbiddenSublevel)
    eq(forbiddenSublevel,nil,"Do not use unsupported 1.12 texture sublevels")
    local o=region("Texture",self)
    o.layer=layer
    o.points={}
    createdTextures=createdTextures+1
    return o
end
function CreateFrame(kind, name, parent)
    local obj=region(kind,parent)
    createdFrames=createdFrames+1
    return obj
end
local function Bar()
    local obj=region("StatusBar",nil)
    obj.points={}
    obj.level=8
    obj.value=30
    obj.fancyTexture="stock-specific-class-health-texture"
    return obj
end
local healthPlayer, manaPlayer=Bar(),Bar()
local healthTarget, manaTarget=Bar(),Bar()
local originalValue=healthPlayer.value
local originalTexture=healthPlayer.fancyTexture
local userCallHandler=function() return "original" end
healthPlayer.scripts.OnMouseDown=userCallHandler
manaTarget:Hide()
local current,events=nil,{}
_G.DFRL={
    theme={
        GetSelected=function() return current end,
        AddListener=function(_,cb) table.insert(events,cb) end,
    },
    themeUI={palette={modern={accent={.43,.72,.90}}}},
}
local root=string.match(arg[0], "^(.*[/\\])tests[/\\]") or ""
assert(loadfile(root.."modules/unit/skins.lua"))()
local style=DFRL.unitFrameSkins
eq(style.listening,false,"Renderer not active at source load")
eq(next(style.entries),nil,"No orphan skin objects")
eq(DFRL.InitUnitFrameSkins("party",healthPlayer,manaPlayer),false,"Do not skin unrequested unit")
eq(DFRL.InitUnitFrameSkins("player",nil,manaPlayer),false,"Reject missing health bar")
eq(createdFrames,0,"Missing/disabled module creates no decoration")
eq(DFRL.InitUnitFrameSkins("target",healthTarget,manaTarget),true,"Target can initialize before player")
eq(DFRL.InitUnitFrameSkins("player",healthPlayer,manaPlayer),true,"Player initialization after world event")
eq(#events,1,"Exactly one theme event listener")
eq(style.listening,true,"Listener registered")
eq(style.entries.player~=nil,true,"Player registered")
eq(style.entries.target~=nil,true,"Target registered")
eq(#style.entries.player.bars,2,"Player has health and resource skins")
eq(#style.entries.target.bars,2,"Target has health and resource skins")
eq(createdFrames,4,"One decorative frame per status bar")
eq(createdTextures,20,"Five graphic textures per status bar")
for _,unit in pairs({"player","target"}) do
    local entry=style.entries[unit]
    for idx,skin in ipairs(entry.bars) do
        eq(skin.isHealth,idx==1,"Correct health/resource role")
        eq(skin.outline.parent,skin.bar,"Decorations belong to status bar")
        eq(skin.outline.allPoints,skin.bar,"Outline follows status bar geometry")
        eq(skin.outline.level,skin.bar.level+1,"Outline is just above statusbar")
        eq(skin.outline.mouseEnabled,false,"Decorations cannot catch clicks")
        eq(skin.outline.shown,false,"No modern artwork before selecting theme")
        eq(skin.matte.shown,false,"No dark matte on original Fantasy style")
        eq(skin.matte.parent,skin.bar,"Dark backdrop lives inside status bar")
        eq(skin.matte.layer,"BACKGROUND","Dark matte behind the bar fill")
        eq(skin.matte.allPoints,skin.bar,"Dark matte follows same dimensions")
        eq(#skin.lines,4,"Four lightweight outline segments")
        for j,line in ipairs(skin.lines) do
            eq(line.parent,skin.outline,"Line belongs to the inert outline frame")
            eq(line.layer,"OVERLAY","Supported legacy draw layer")
            eq(line.texture,"Interface\\Buttons\\WHITE8X8","Built-in neutral texture")
            eq(#line.points,2,"Outline texture is anchored at two edges")
            eq(j<3 and line.height or line.width,1,"One pixel border")
        end
    end
end
local function switch(id)
    current=id
    for _,cb in ipairs(events) do cb(id) end
end
switch("modern")
for _,item in pairs(style.entries) do
    for _,skin in ipairs(item.bars) do
        eq(skin.outline.shown,true,"Modern style shows outline")
        eq(skin.matte.shown,true,"Modern style shows dark backing")
        eq(skin.lines[1].color[4],.95,"Modern border opacity")
        local expectedR=skin.isHealth and .43 or .43*.55
        eq(skin.lines[1].color[1],expectedR,"Health/resource outlines share theme palette")
    end
end
eq(healthPlayer.value,originalValue,"Does not change actual health")
eq(healthPlayer.fancyTexture,originalTexture,"Does not replace status textures")
eq(healthPlayer.scripts.OnMouseDown,userCallHandler,"Does not replace statusbar handlers")
eq(manaTarget.shown,false,"Invisible target resource bar remains hidden")
local beforeFrameCount,beforeTexCount=createdFrames,createdTextures
switch("modern")
eq(createdFrames,beforeFrameCount,"Repeat modern doesn't create frames")
eq(createdTextures,beforeTexCount,"Repeat modern doesn't create textures")
switch("fantasy")
for _,item in pairs(style.entries) do
    for _,skin in ipairs(item.bars) do
        eq(skin.outline.shown,false,"Fantasy hides new outlines")
        eq(skin.matte.shown,false,"Fantasy hides new dark backing")
    end
end
eq(DFRL.InitUnitFrameSkins("player",healthPlayer,manaPlayer),true,"Idempotent player registration")
eq(#events,1,"No duplicate listener after repeat registration")
eq(createdFrames,beforeFrameCount,"No duplicate unit decorations")
switch("modern")
switch(nil)
for _,item in pairs(style.entries) do
    for _,skin in ipairs(item.bars) do
        eq(skin.outline.shown,false,"Existing Appearance hides Modern artwork")
        eq(skin.matte.shown,false,"Existing Appearance hides Modern mattes")
    end
end
eq(manaTarget.shown,false,"Style switching doesn't force hidden bars visible")
local petTest=Bar()
eq(DFRL.InitUnitFrameSkins("player",healthPlayer,petTest),true,"Existing skin isn't replaced")
eq(#style.entries.player.bars,2,"No orphan third resource bar")
eq(DFRL.modules,nil,"Skin renderer does not register a new module")
print("PASS milestone 3B unit skins: "..checks.." assertions")
