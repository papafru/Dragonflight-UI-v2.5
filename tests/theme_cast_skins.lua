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
function methods:SetText(t) self.text=t end
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
eq(skin:QuietPlayerCompletion(),false,"Quiet completion disabled outside Modern")
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

-- Regression for client screenshot: vanilla success color (0,1,0) plus
-- another animated green flash created the noisy modern completion frame.
-- Exercise the actual Cast:HandleEvent / Cast:OnUpdate code from source,
-- without executing the entire game-dependent module constructor.
local eventSource=string.match(c,"(    function Setup:HandleEvent%(event, arg1, arg2%).-\n    end)")
local updateSource=string.match(c,"(    function Setup:OnUpdate%(elapsed%).-\n    end)")
eq(type(eventSource),"string","Cast event source extracted for end-to-end test")
eq(type(updateSource),"string","Cast fade/flash update extracted for end-to-end test")
local liveMethods=assert(loadstring("local Setup = {}\n"..eventSource.."\n"..updateSource.."\nreturn Setup"))()
-- Use the same Setup table registered with the skin, so theme switches
-- during completion operate on the real active cast state.
local runtime=player
runtime.HandleEvent=liveMethods.HandleEvent
runtime.OnUpdate=liveMethods.OnUpdate
local now=125
GetTime=function() return now end
FAILED="Failed"
INTERRUPTED="Interrupted"
runtime.config={width=200,height=16,fillDirection="right",flashSpeed=5,
  alphaSpeed=3,holdTimeDuration=1,barColor={r=.9,g=.82,b=.1}}
runtime.state={casting=false,channeling=false,fadeOut=false,flash=false,
  flashAlpha=0,holdTime=0,currentProgress=0,startTime=0,maxValue=0}
runtime.frame=player.frame
runtime.barTexture=player.barTexture
runtime.spark=player.spark
runtime.flashTex=player.flashTex
runtime.text=region(nil,"FontString")
runtime.timeText=region(nil,"FontString")
runtime.UpdateBarVisual=function(self,progress)
 self.barTexture:SetWidth(math.max(.1,progress*self.config.width))
end

theme:Select("modern")
runtime.flashTex:Hide()
eq(skin:QuietPlayerCompletion(),true,"Modern finish enters quiet state")
runtime:HandleEvent("SPELLCAST_START","Rough Blasting Powder",3500)
eq(runtime.state.casting,true,"Normal spell start still activates cast")
eq(runtime.barTexture:GetVertexColor(),.9,"Modern ongoing casting color unchanged")
eq(runtime.flashTex:IsShown(),false,"No flash while casting")
runtime:HandleEvent("SPELLCAST_STOP")
eq(runtime.state.casting,false,"Successful finish ends ongoing cast")
eq(runtime.state.flash,true,"Original completion flash state still ticks")
eq(runtime.state.fadeOut,true,"Original fade-out state still ticks")
eq(runtime.state.mode,"flash","Completion mode unchanged")
eq(runtime.barTexture:GetVertexColor(),.28,"Success fill has moderate red")
eq(runtime.barTexture.vertex[2],1,"Green channel stays vivid underneath charcoal tint")
eq(runtime.barTexture.vertex[3],.24,"Success hue is green rather than teal")
-- Renderer adds a 28% graphite overlay over the animated fill. The
-- resulting visible green should exceed 70%, avoiding the dim teal result
-- in the user's follow-up screenshot while keeping the flash suppressed.
local tint=skin.entries.player.mute
local effectiveGreen=runtime.barTexture.vertex[2]*(1-tint.vertex[4])+
    tint.vertex[2]*tint.vertex[4]
eq(effectiveGreen > .70,true,"Rendered Modern success green stays legible")
eq(runtime.flashTex:IsShown(),false,"Additional completion flash suppressed immediately")
eq(runtime.barTexture.width,200,"Completed fill remains at 100 percent")
runtime:OnUpdate(.09)
eq(math.abs(runtime.state.flashAlpha-.45)<.000001,true,"Completion animation internal timing preserved")
eq(runtime.state.flash,true,"Completion timing still in progress")
eq(runtime.flashTex:IsShown(),false,"OnUpdate does not bring back noisy flash")
theme:Select("fantasy")
eq(runtime.barTexture:GetVertexColor(),0,"Fantasy restores vivid default success green")
eq(runtime.barTexture.vertex[2],1,"Fantasy success color green")
eq(runtime.flashTex:IsShown(),true,"Fantasy shows original flash mid-completion")
runtime:OnUpdate(.03)
eq(runtime.flashTex:IsShown(),true,"Fantasy animates completion flash normally")
theme:Select("modern")
eq(runtime.barTexture:GetVertexColor(),.28,"Modern retones success mid-completion")
eq(runtime.flashTex:IsShown(),false,"Modern quiet mode hides in-flight flash")
runtime:OnUpdate(.09)
eq(runtime.state.flash,false,"Original flash interval completes normally")
eq(runtime.state.fadeOut,true,"Fade continues after quiet flash interval")
runtime:OnUpdate(.08)
eq(runtime.frame:GetAlpha()<1,true,"Original fade progression still runs")
eq(runtime.flashTex:IsShown(),false,"Flash remains suppressed during Modern fade")
theme:Select(nil)
eq(skin:QuietPlayerCompletion(),false,"Existing Appearance has normal completion behavior")
runtime:HandleEvent("SPELLCAST_START","Rough Blasting Powder",2500)
runtime:HandleEvent("SPELLCAST_STOP")
eq(runtime.barTexture:GetVertexColor(),0,"Existing Appearance preserves original success red channel")
eq(runtime.barTexture.vertex[2],1,"Existing Appearance uses original full green")
eq(runtime.flashTex:IsShown(),true,"Existing Appearance retains original flash")
runtime:OnUpdate(.1)
eq(runtime.flashTex:IsShown(),true,"Original flash updates outside Modern")
theme:Select("modern")
runtime:HandleEvent("SPELLCAST_START","Rough Blasting Powder",2500)
runtime:HandleEvent("SPELLCAST_INTERRUPTED")
eq(runtime.barTexture:GetVertexColor(),1,"Interrupted cast retains default red")
eq(runtime.barTexture.vertex[2],0,"Quiet success does not alter interruption red")
eq(runtime.state.mode,"hold","Interrupted hold period preserved")
eq(runtime.text.text,INTERRUPTED,"Interrupted spell label remains unchanged")
print("PASS Milestone 3C.1 cast skins: "..assertions.." assertions")
