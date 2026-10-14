-- fruUI 3C.1: Lua 5.1 mock, reversible castbar visuals only.
if not table.getn then table.getn=function(t)return #t end end
local assertions, textureCount = 0, 0
local function eq(actual, expected, reason)
  assertions=assertions+1
  if actual~=expected then
    error(reason..": expected "..tostring(expected)..", got "..tostring(actual))
  end
end
local methods={}
local function region(parent,layer)
  local r={alpha=1,visible=true,parent=parent,layer=layer,vertex={1,1,1,1}}
  setmetatable(r,{__index=methods})
  return r
end
function methods:SetTexture(t) self.texture=t end
function methods:GetTexture() return self.texture end
function methods:SetAlpha(a) self.alpha=a end
function methods:GetAlpha() return self.alpha end
function methods:SetVertexColor(...) self.vertex={...} end
function methods:GetVertexColor() return unpack(self.vertex) end
function methods:SetWidth(v) self.width=v end
function methods:SetHeight(v) self.height=v end
function methods:SetAllPoints(other) self.allPoints=other end
function methods:SetPoint(...) self.point={...} end
function methods:Show() self.visible=true end
function methods:Hide() self.visible=false end
function methods:IsShown() return self.visible end
function methods:CreateTexture(name,layer)
  textureCount=textureCount+1
  return region(self,layer)
end
local theme={selected=nil,listeners={}}
function theme:GetSelected() return self.selected end
function theme:AddListener(fn) table.insert(self.listeners,fn) end
function theme:Select(value)
  self.selected=value
  for _,fn in ipairs(self.listeners) do fn(value) end
end
DFRL={theme=theme}
local root=string.match(arg[0],"^(.*[/\\])tests[/\\]") or ""
assert(loadfile(root.."modules/cast/skins.lua"))()
local skin=DFRL.castbarSkins
eq(type(DFRL.InitCastbarSkin),"function","Loader offers independent castbar skin entry")
eq(DFRL.InitCastbarSkin("bad",{}),false,"Reject invalid castbar")
eq(DFRL.InitCastbarSkin("target",{}),false,"Absent optional Target castbar safe")
local function make(id,hasFlash)
 local frame=region(nil,"Frame")
 local bar=frame:CreateTexture(nil,"BORDER")
 bar:SetTexture(id.."-fantasy-gradient.blp")
 bar:SetVertexColor(.75,.6,.1,1)
 bar:SetWidth(19)
 local backdrop=frame:CreateTexture(nil,"BACKGROUND")
 backdrop:SetTexture(id.."-fantasy-backdrop.blp")
 backdrop:SetAlpha(.65)
 local borderframe=frame:CreateTexture(nil,"ARTWORK")
 borderframe:SetTexture(id.."-fantasy-border.blp")
 borderframe:SetAlpha(.88)
 local dropshadow=frame:CreateTexture(nil,"BACKGROUND")
 dropshadow:SetTexture(id.."-fantasy-shadow.blp")
 dropshadow:SetAlpha(.4)
 local spark=frame:CreateTexture(nil,"OVERLAY")
 spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
 spark:SetWidth(25)
 local flash=nil
 if hasFlash then
  flash=frame:CreateTexture(nil,"OVERLAY")
  flash:SetTexture(id.."-flash.tga")
 end
 return {frame=frame,barTexture=bar,backdrop=backdrop,
  borderframe=borderframe,dropshadow=dropshadow,spark=spark,
  flashTex=flash,icon=region(frame,"Frame"),
  state={casting=true,channeling=false,startTime=10,endTime=16,currentProgress=.42},
  config={width=200,height=16,fillDirection="right"}}
end
local player=make("player",true)
local target=make("target",false)
local baseTextures=textureCount
eq(DFRL.InitCastbarSkin("player",player),true,"Player skin setup")
eq(textureCount,baseTextures+6,"Player skin allocates track/tint/four borders once")
eq(#theme.listeners,1,"Only one registered theme listener")
eq(DFRL.InitCastbarSkin("player",player),true,"Player init idempotent")
eq(textureCount,baseTextures+6,"Idempotent call doesn't allocate more")
eq(skin.entries.player.modern,false,"Fantasy/unselected begins unchanged")
eq(player.barTexture:GetTexture(),"player-fantasy-gradient.blp","Fantasy fill untouched on startup")
eq(player.backdrop:GetAlpha(),.65,"Fantasy background remains original")
eq(skin.entries.player.track:IsShown(),false,"Fantasy track starts hidden")
eq(DFRL.InitCastbarSkin("target",target),true,"Optional Target skin")
eq(#theme.listeners,1,"Both skins share theme listener")
eq(textureCount,baseTextures+12,"Target adds only six skins")
eq(skin.entries.target.mute.allPoints,target.barTexture,"Target tint follows animated fill")
eq(skin.entries.player.mute.allPoints,player.barTexture,"Player tint follows animated fill")
theme:Select("modern")
local white="Interface\\Buttons\\WHITE8X8"
for _,setup in ipairs({player,target}) do
  local entry=setup==player and skin.entries.player or skin.entries.target
  eq(entry.modern,true,"Modern marked active")
  eq(setup.barTexture:GetTexture(),white,"Modern flat fill")
  eq(setup.backdrop:GetAlpha(),0,"Original ornate back hidden by alpha")
  eq(setup.borderframe:GetAlpha(),0,"Original ornate border hidden")
  eq(setup.dropshadow:GetAlpha(),0,"Modern suppresses old drop shadow")
  eq(entry.track:IsShown(),true,"Charcoal track visible")
  eq(entry.mute:IsShown(),true,"Muted fill tint visible")
  eq(entry.mute:GetVertexColor(),.028,"Muted tint color unchanged")
  eq(entry.mute.vertex[4],.28,"Muted fill tint strength")
  for i=1,#entry.lines do
    eq(entry.lines[i]:IsShown(),true,"Single thin rectangle segment visible")
    eq(entry.lines[i].layer,"ARTWORK","Modern borders on supported named layer")
    eq(entry.lines[i].width==1 or entry.lines[i].height==1,true,"Thin 1px line")
  end
  eq(setup.barTexture.width,19,"Cast fill's active width unaffected")
  eq(setup.spark.width,25,"Existing spark unchanged")
  eq(setup.state.casting,true,"Cast state untouched")
  eq(setup.state.currentProgress,.42,"Cast timing/progress untouched")
  eq(setup.config.fillDirection,"right","Configured fill direction untouched")
end
eq(player.flashTex:GetTexture(),white,"Player flash flattened, fade events still own alpha")
eq(target.flashTex,nil,"Target castbar flash optional")
-- Dynamic state updates still control status fill colors, spark show, spell text.
player.barTexture:SetVertexColor(0,1,0,1)
player.barTexture:SetWidth(83)
player.spark:Show()
theme:Select("modern")
eq(player.barTexture.vertex[2],1,"Repeated selection doesn't overwrite completion green")
eq(player.barTexture.width,83,"Repeated selection doesn't overwrite progress")
eq(textureCount,baseTextures+12,"Repeated selection doesn't allocate textures")
-- Old appearance restored, including original alpha; live progress remains.
theme:Select("fantasy")
eq(player.barTexture:GetTexture(),"player-fantasy-gradient.blp","Fantasy fill restored")
eq(target.barTexture:GetTexture(),"target-fantasy-gradient.blp","Target Fantasy fill restored")
eq(player.flashTex:GetTexture(),"player-flash.tga","Fantasy flash restored")
eq(player.backdrop:GetAlpha(),.65,"Player background alpha restored")
eq(player.borderframe:GetAlpha(),.88,"Player ornate frame alpha restored")
eq(player.dropshadow:GetAlpha(),.4,"Player shadow alpha restored")
eq(target.backdrop:GetAlpha(),.65,"Target background alpha restored")
eq(target.borderframe:GetAlpha(),.88,"Target ornate border alpha restored")
eq(target.dropshadow:GetAlpha(),.4,"Target shadow alpha restored")
eq(player.barTexture.vertex[2],1,"Green cast completion state stays authoritative")
eq(player.barTexture.width,83,"Fill progress preserved on theme restoration")
for _,entry in pairs(skin.entries) do
  eq(entry.track:IsShown(),false,"Fantasy hides track")
  eq(entry.mute:IsShown(),false,"Fantasy hides fill tint")
  for _,line in ipairs(entry.lines) do eq(line:IsShown(),false,"Fantasy hides modern outline") end
end
theme:Select("modern")
theme:Select(nil)
eq(player.barTexture:GetTexture(),"player-fantasy-gradient.blp","Existing Appearance restores original graphics")
eq(target.barTexture:GetTexture(),"target-fantasy-gradient.blp","Existing Appearance restores optional Target")
eq(#theme.listeners,1,"No duplicate listeners after theme switching")
-- Even missing Shadow is safe on an optional setup.
local minimal=make("minimal",false)
minimal.dropshadow=nil
skin.entries.target=nil
eq(DFRL.InitCastbarSkin("target",minimal),true,"Optional target omits dropshadow safely")
theme:Select("modern")
eq(minimal.barTexture:GetTexture(),white,"Minimal Target still flat")
theme:Select(nil)
eq(minimal.barTexture:GetTexture(),"minimal-fantasy-gradient.blp","Minimal Target restores fill")
-- Verify owning modules initialize only after registering settings.
local function contents(path)
 local file=assert(io.open(root..path,"r"))
 local data=file:read("*a")
 file:close()
 return data
end
local c=contents("modules/cast/cast.lua")
local t=contents("modules/cast/target.lua")
local toc=contents("DragonflightUI-Reforged.toc")
eq(string.find(c,'DFRL.InitCastbarSkin("player", Setup)',1,true)~=nil,true,"Cast module registers renderer")
eq(string.find(t,'DFRL.InitCastbarSkin("target", Setup)',1,true)~=nil,true,"Target cast module registers renderer")
eq(string.find(toc,'modules\\cast\\skins.lua',1,true)~=nil,true,"TOC includes shared skin renderer")
eq(string.find(c,'DFRL:NewCallbacks("Cast", callbacks)',1,true) < string.find(c,'DFRL.InitCastbarSkin("player", Setup)',1,true),true,"Player skin initializes after callbacks")
eq(string.find(t,'DFRL:NewCallbacks("TargetCastbar", callbacks)',1,true) < string.find(t,'DFRL.InitCastbarSkin("target", Setup)',1,true),true,"Target skin initializes after callbacks")
print("PASS Milestone 3C.1 cast skins: "..assertions.." assertions")
