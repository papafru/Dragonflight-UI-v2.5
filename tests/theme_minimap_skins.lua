-- fruUI Milestone 3C.2: square Modern Dark minimap (Lua 5.1 mocks).
if not table.getn then table.getn=function(t)return #t end end
local count=0
local function eq(v,w,why)
 count=count+1
 if v~=w then error(why..": expected "..tostring(w)..", got "..tostring(v)) end
end
local regions=0
local methods={}
local function Region(parent,kind)
 local o={parent=parent,kind=kind,shown=true,alpha=1,points={},color={1,1,1,1},
  width=180,height=180,children={}}
 setmetatable(o,{__index=methods})
 if parent then table.insert(parent.children,o) end
 return o
end
function methods:CreateTexture(name,layer)
 regions=regions+1
 local o=Region(self,"Texture")
 o.layer=layer
 o.name=name
 return o
end
function methods:SetTexture(v) self.texture=v end
function methods:GetTexture() return self.texture end
function methods:SetMaskTexture(v) self.mask=v end
function methods:SetAlpha(v) self.alpha=v end
function methods:GetAlpha() return self.alpha end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:SetVertexColor(...) self.color={...} end
function methods:GetVertexColor() return unpack(self.color) end
function methods:SetPoint(...) table.insert(self.points,{...}) end
function methods:SetAllPoints(p) self.allPoints=p end
function methods:SetWidth(x) self.width=x end
function methods:SetHeight(y) self.height=y end
function methods:SetScale(x) self.scale=x end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end

local root=string.match(arg[0],"^(.*[/\\])tests[/\\]") or ""
local function read(path)
 local file=assert(io.open(root..path,"r"))
 local text=file:read("*a")
 file:close()
 return text
end
DFRL={tempDB={Map={mapSquare=false,mapShadow=true,alphaShadow=.3}},callbacks={},gui={}}
function DFRL:GetTempDB(mod,key)
 local raw=self.tempDB[mod] and self.tempDB[mod][key]
 return self.theme and self.theme:Resolve(mod,key,raw) or raw
end
function DFRL:SetTempDB(mod,key,value)
 if not (self.theme and self.theme:WriteOverride(mod,key,value)) then
  self.tempDB[mod]=self.tempDB[mod] or {}
  self.tempDB[mod][key]=value
 end
 self:TriggerCallback(mod.."_"..key.."_changed",self:GetTempDB(mod,key))
end
function DFRL:TriggerCallback(key,v)
 if self.callbacks[key] then self.callbacks[key](v) end
end
StaticPopupDialogs={}
YES,NO="Yes","No"
local themeFile=assert(loadfile(root.."core/theme.lua"))
themeFile()
DFRL.theme.state={selected=nil,needsChoice=false,overrides={modern={},fantasy={}}}
eq(DFRL.theme:Supports("Map","mapSquare"),true,"Map shape is explicitly theme-owned")
eq(DFRL.theme:Resolve("Map","mapSquare",false),false,"Unselected theme honors raw circular map")
eq(DFRL.theme.presets.modern.Map.mapSquare,true,"Modern Dark defaults square")
eq(DFRL.theme.presets.fantasy.Map.mapSquare,false,"Fantasy theme defaults round")
eq(DFRL.tempDB.Map.mapSquare,false,"No legacy profile change at initialization")

Minimap=Region(nil,"Minimap")
Minimap.mask="Textures\\MinimapMask"
local panel=Region(Minimap,"Frame")
panel.width=180
panel.height=12
local border=Minimap:CreateTexture("MinimapBorder","OVERLAY")
local shadow=Minimap:CreateTexture("MinimapShadow","BORDER")
local background=panel:CreateTexture(nil,"BACKGROUND")
border:SetAlpha(.9)
shadow:SetAlpha(.3)
background:SetAlpha(.72)
local setup={
 texpath="Interface\\AddOns\\DragonflightUI-Reforged\\media\\tex\\minimap\\",
 minimapBorder=border,minimapShadow=shadow,bgTexture=background,topPanel=panel,
}
local mapSource=read("modules/map/map.lua")
-- Compile the real legacy callbacks in a tiny isolated module environment.
local squareSource=string.match(mapSource,
  "(        callbacks.mapSquare = function%(value%).-\n        end)")
local shadowSource=string.match(mapSource,
  "(        callbacks.alphaShadow = function%(value%).-\n        end)")
eq(type(squareSource),"string","Actual mapSquare callback is available")
eq(type(shadowSource),"string","Actual alphaShadow callback is available")
local callbackFactory=assert(loadstring("return function(Setup, Minimap, DFRL)\n"
   .."local callbacks = {}\n"..squareSource.."\n"..shadowSource..
   "\nreturn callbacks\nend"))()
local callbacks=callbackFactory(setup,Minimap,DFRL)
DFRL.callbacks.Map_mapSquare_changed=callbacks.mapSquare
DFRL.callbacks.Map_alphaShadow_changed=callbacks.alphaShadow
callbacks.mapSquare(DFRL:GetTempDB("Map","mapSquare"))
callbacks.alphaShadow(DFRL:GetTempDB("Map","alphaShadow"))
local textureAlloc=regions
assert(loadfile(root.."modules/map/skins.lua"))()
eq(DFRL.InitMinimapSkin(nil),false,"Missing optional map setup fails safely")
eq(DFRL.InitMinimapSkin(setup),true,"Modern skin initializes")
local skin=DFRL.minimapSkins
eq(#DFRL.theme.listeners,1,"Exactly one theme listener")
eq(regions,textureAlloc+6,"Four edge lines, panel matte, divider created once")
eq(DFRL.InitMinimapSkin(setup),true,"Minimap skin initializer idempotent")
eq(regions,textureAlloc+6,"No duplicated skin assets")
eq(border:GetAlpha(),.9,"Neutral keeps ornate border")
eq(shadow:GetAlpha(),.3,"Neutral keeps configured shadow")
eq(background:GetAlpha(),.72,"Neutral keeps ornate top panel")
eq(Minimap.mask,"Textures\\MinimapMask","Neutral map keeps circular mask")
eq(skin.entry.panel:IsShown(),false,"Modern panel hidden initially")
for _,line in ipairs(skin.entry.edges) do eq(line:IsShown(),false,"No modern lines initially") end

eq(DFRL.theme:Select("modern"),true,"Modern theme selectable")
eq(DFRL:GetTempDB("Map","mapSquare"),true,"Modern square via theme resolve")
eq(DFRL.tempDB.Map.mapSquare,false,"Legacy profile map shape unchanged")
eq(Minimap.mask,"Interface\\BUTTONS\\WHITE8X8","Real Map callback applies square mask")
eq(border:GetTexture(),setup.texpath.."map_dragonflight_square2.tga","Real Map callback selects square artwork")
eq(border:GetAlpha(),0,"Modern hides bulky Dragonflight square artwork")
eq(shadow:GetAlpha(),0,"Modern removes ornamental shadow")
eq(background:GetAlpha(),0,"Modern hides oversized header texture")
eq(skin.entry.panel:IsShown(),true,"Thin top panel visible in Modern")
eq(skin.entry.panel.allPoints,panel,"Header matte uses exact panel bounds")
eq(skin.entry.divider:IsShown(),true,"Minimal header divider visible")
eq(skin.entry.panel.color[1],.045,"Graphite header background")
eq(skin.entry.panel.color[4],.96,"Graphite header opacity")
eq(skin.entry.divider.layer,"ARTWORK","Divider uses named vanilla draw layer")
eq(skin.entry.square,true,"Skin tracks square mode")
for i,line in ipairs(skin.entry.edges) do
 eq(line:IsShown(),true,"Modern has thin square edge")
 eq(line.layer,"OVERLAY","Map border on supported named draw layer")
 eq(line.width==1 or line.height==1,true,"Only one-pixel border")
 eq(line.parent,Minimap,"Border follows native minimap dimensions")
end
local textures=regions
DFRL.theme:Select("modern")
eq(regions,textures,"Repeated theme selection creates no assets")
eq(shadow:GetAlpha(),0,"Repeated selection keeps shadow concealed")
Minimap:SetWidth(234)
Minimap:SetHeight(234)
eq(skin.entry.edges[1].points[1][2],Minimap,"Border anchored to dynamically sized minimap")
eq(Minimap:GetWidth(),234,"Modern does not change map size")
eq(Minimap:GetHeight(),234,"Modern does not change map height")

-- User may override shape in Modern without modifying Fantasy or profile.
DFRL:SetTempDB("Map","mapSquare",false)
eq(DFRL:GetTempDB("Map","mapSquare"),false,"User may switch Modern to round")
eq(Minimap.mask,"Textures\\MinimapMask","Real shape callback switches mask to circle")
eq(skin.entry.square,false,"Thin square edges disabled for round override")
eq(border:GetAlpha(),.9,"Round override restores its original decorative border")
eq(shadow:GetAlpha(),.3,"Round override restores matching shadow")
eq(skin.entry.panel:IsShown(),true,"Modern header stays flat for optional round map")
for _,line in ipairs(skin.entry.edges) do eq(line:IsShown(),false,"No mismatched square edge on circle") end
eq(DFRL.tempDB.Map.mapSquare,false,"Modern round override doesn't touch raw profile")
DFRL:SetTempDB("Map","mapSquare",true)
eq(Minimap.mask,"Interface\\BUTTONS\\WHITE8X8","Modern square override returns")
eq(skin.entry.square,true,"Modern thin frame returns")
eq(shadow:GetAlpha(),0,"Ornamental shadow concealed again")
eq(DFRL.theme.state.overrides.modern.Map,nil,"Selecting preset clears redundant override")

DFRL:SetTempDB("Map","alphaShadow",.65)
eq(shadow:GetAlpha(),0,"Live shadow slider doesn't reveal Modern square shadow")
eq(skin.entry.original.shadowAlpha,.65,"Theme preserves latest profile-owned shadow alpha")
eq(DFRL.tempDB.Map.alphaShadow,.65,"Profile-owned shadow transparency updated")
DFRL.theme:Select("fantasy")
eq(Minimap.mask,"Textures\\MinimapMask","Fantasy returns circular mask by default")
eq(border:GetAlpha(),.9,"Fantasy restores ornate border")
eq(shadow:GetAlpha(),.65,"Fantasy restores most recent shadow slider")
eq(background:GetAlpha(),.72,"Fantasy restores original top panel art")
eq(skin.entry.panel:IsShown(),false,"Fantasy hides flat Modern panel")
eq(skin.entry.divider:IsShown(),false,"Fantasy hides modern divider")
for _,line in ipairs(skin.entry.edges) do eq(line:IsShown(),false,"Fantasy hides thin square edges") end

-- The Fantasy user can explicitly enable square art; preserve preference.
DFRL:SetTempDB("Map","mapSquare",true)
eq(Minimap.mask,"Interface\\BUTTONS\\WHITE8X8","Fantasy square override works")
eq(border:GetAlpha(),.9,"Fantasy square still has its Dragonflight border")
eq(border:GetTexture(),setup.texpath.."map_dragonflight_square2.tga","Fantasy uses original ornamental square art")
eq(skin.entry.edges[1]:IsShown(),false,"Modern outline stays hidden in Fantasy")
DFRL.theme:Select("modern")
eq(Minimap.mask,"Interface\\BUTTONS\\WHITE8X8","Fantasy override cannot change Modern default")
eq(border:GetAlpha(),0,"Modern flat appearance restored")
DFRL.theme:UseExistingAppearance()
eq(DFRL.theme:GetSelected(),nil,"Existing Appearance returns neutral mode")
eq(Minimap.mask,"Textures\\MinimapMask","Existing Appearance uses raw profile circle")
eq(background:GetAlpha(),.72,"Existing Appearance restores original header art")
eq(border:GetAlpha(),.9,"Existing Appearance restores original border alpha")
eq(skin.entry.panel:IsShown(),false,"No Modern matte in Existing Appearance")
eq(DFRL.tempDB.Map.mapSquare,false,"Existing profile remains unmodified")

-- Integration guards for real Map after construction and callback loading.
eq(string.find(mapSource,'DFRL.InitMinimapSkin(Setup)',1,true)~=nil,true,
 "Map module attaches skin to real Setup object")
eq(string.find(mapSource,'DFRL:NewCallbacks("Map", callbacks)',1,true) <
   string.find(mapSource,'DFRL.InitMinimapSkin(Setup)',1,true),true,
 "Map visual skin initialized after callbacks")
eq(string.find(mapSource,'DFRL.minimapSkins:Refresh()',1,true)~=nil,true,
 "User shape override refreshes modern frame")
local toc=read("DragonflightUI-Reforged.toc")
eq(string.find(toc,'modules\\map\\skins.lua',1,true)~=nil,true,
 "TOC loads Map skins module")
eq(string.find(mapSource,'Minimap:EnableMouseWheel(true)',1,true)~=nil,true,
 "Legacy zoom interaction remains")
eq(string.find(mapSource,'Setup:PizzaWorldBuffs()',1,true)~=nil,true,
 "Minimap addons and world buff toggle remain initialized")
print("PASS Milestone 3C.2 square minimap: "..count.." assertions")
