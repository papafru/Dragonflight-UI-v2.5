-- fruUI hover-highlight options and color palette, pure Lua 5.1.
local total=0
local function eq(a,b,what)
  total=total+1
  if a~=b then error(what..": got "..tostring(a)..", expected "..tostring(b)) end
end
if not table.getn then table.getn=function(t)return #t end end
local root=string.match(arg[0],"^(.*[/\\])tests[/\\]") or ""
local function content(path)
 local f=assert(io.open(root..path,"r"))
 local v=f:read("*a")
 f:close()
 return v
end
local methods={}
local function item(parent)
 local t={parent=parent,children={},scripts={},value=1,shown=true,swatchColor={}}
 setmetatable(t,{__index=methods})
 if parent then table.insert(parent.children,t) end
 return t
end
function CreateFrame(kind,name,parent)
 local f=item(parent)
 f.kind=kind
 f.name=name
 return f
end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
function methods:SetOrientation(x) self.orientation=x end
function methods:SetThumbTexture(x) self.thumb=x end
function methods:SetBackdrop(x) self.backdrop=x end
function methods:SetMinMaxValues(a,b) self.min=a;self.max=b end
function methods:GetMinMaxValues() return self.min,self.max end
function methods:SetValueStep(v) self.step=v end
function methods:SetPoint(...) self.point={...} end
function methods:SetFont(...) self.font={...} end
function methods:SetText(v) self.text=tostring(v) end
function methods:SetTextColor(...) self.textColor={...} end
function methods:SetTexture(v) self.texture=v end
function methods:SetVertexColor(...) self.swatchColor={...} end
function methods:CreateFontString(...) return item(self) end
function methods:CreateTexture(...) return item(self) end
function methods:GetValue() return self.value end
function methods:SetValue(v)
  if self.min and v<self.min then v=self.min end
  if self.max and v>self.max then v=self.max end
  self.value=v
  local fn=self.scripts.OnValueChanged
  if fn then
    local oldThis=this
    this=self
    fn()
    this=oldThis
  end
end
function methods:SetScript(event,callback) self.scripts[event]=callback end
function methods:EnableMouseWheel(v) self.wheel=v end
local profile={highlightColor={1,.82,0},highlightShow=true}
local writes={}
DFRL={
 tools={},
 tempDB={Bars=profile},
 gui=nil,
 GetTempDB=function(self,mod,key)
  local raw=self.tempDB[mod][key]
  if self.theme then return self.theme:Resolve(mod,key,raw) end
  return raw
 end,
 SetTempDB=function(self,mod,key,value)
  if not(self.theme and self.theme:WriteOverride(mod,key,value)) then
   self.tempDB[mod][key]=value
  end
  table.insert(writes,{module=mod,key=key,value=value})
 end,
 TriggerCallback=function() end,
}
StaticPopupDialogs={}
YES,NO="Yes","No"
assert(loadfile(root.."core/theme.lua"))()
local t=DFRL.theme
t.state={schema=1,selected=nil,needsChoice=false,overrides={modern={},fantasy={}}}
eq(t:Supports("Bars","highlightShow"),true,"Highlight show is valid theme appearance setting")
eq(t.presets.modern.Bars.highlightShow,true,"Modern highlights default enabled")
eq(t.presets.fantasy.Bars.highlightShow,true,"Fantasy highlights default enabled")
eq(DFRL:GetTempDB("Bars","highlightShow"),true,"Existing Appearance uses legacy default")
eq(t:Select("modern"),true,"Can choose Modern theme")
eq(DFRL:GetTempDB("Bars","highlightShow"),true,"Modern keeps default highlights enabled")
DFRL:SetTempDB("Bars","highlightShow",false)
eq(DFRL:GetTempDB("Bars","highlightShow"),false,"Modern can hide hover glow")
eq(DFRL.tempDB.Bars.highlightShow,true,"Modern override does not mutate profile")
DFRL:SetTempDB("Bars","highlightShow","false")
eq(DFRL:GetTempDB("Bars","highlightShow"),false,"Malformed string cannot override boolean")
t:Select("fantasy")
eq(DFRL:GetTempDB("Bars","highlightShow"),true,"Fantasy show preference is separate")
t:Select("modern")
eq(DFRL:GetTempDB("Bars","highlightShow"),false,"Returning to Modern restores disabled state")

-- Compile the original color slider constructor, rather than testing a
-- second hardcoded list copied out of the production module.
local source=content("modules/gui/tools.lua")
local start=assert(string.find(source,"function DFRL.tools.CreateColour(",1,true))
local finish=assert(string.find(source,"\nfunction DFRL.tools.CreateDropDown(",start,true))
local load=assert(loadstring(string.sub(source,start,finish-1)))
load()
local parent=item(nil)
local slider=DFRL.tools.CreateColour(parent,nil,"Bars","highlightColor")
eq(slider.COLOR_COUNT,31,"Exactly 31 available colors")
eq(table.getn(slider.BASIC_COLORS),31,"Palette range derived from array length")
local min,max=slider:GetMinMaxValues()
eq(min,1,"Old first palette index preserved")
eq(max,31,"Black is available as last swatch")
for i=1,30 do
 eq(slider.BASIC_COLORS[i][1]~=nil,true,"Existing palette entry preserved: "..i)
end
eq(slider.BASIC_COLORS[31][1],0,"Black palette red is zero")
eq(slider.BASIC_COLORS[31][2],0,"Black palette green is zero")
eq(slider.BASIC_COLORS[31][3],0,"Black palette blue is zero")
eq(slider.moduleName,"Bars","Slider still targets Bars")
eq(slider.configKey,"highlightColor","Slider still targets existing setting")
slider:SetValue(31)
eq(slider:GetValue(),31,"User can select palette index 31")
eq(slider.valueText.text,"31","Slider displays black index")
eq(slider.colorSwatch.swatchColor[1],0,"Visible slider swatch becomes black")
eq(DFRL:GetTempDB("Bars","highlightColor")[1],0,"Theme stores black zero channel")
eq(DFRL:GetTempDB("Bars","highlightColor")[2],0,"Theme stores all-zero green channel")
eq(DFRL:GetTempDB("Bars","highlightColor")[3],0,"Theme stores all-zero blue channel")
eq(DFRL.tempDB.Bars.highlightColor[1],1,"Modern black does not alter old legacy profile")
eq(slider.COLOR_COUNT==table.getn(slider.BASIC_COLORS),true,"No hardcoded palette count")
slider:SetValue(30)
eq(slider.BASIC_COLORS[30][1],.8,"Old gold remains index 30")
eq(DFRL:GetTempDB("Bars","highlightColor")[1],.8,"Old color selectable after black")
slider:SetValue(31)
t:Select("fantasy")
eq(DFRL:GetTempDB("Bars","highlightColor")[1],1,"Black Modern does not alter Fantasy")
eq(DFRL:GetTempDB("Bars","highlightShow"),true,"Fantasy keeps show state")
t:Select("modern")
eq(DFRL:GetTempDB("Bars","highlightColor")[1],0,"Returning Modern restores black")
eq(DFRL:GetTempDB("Bars","highlightShow"),false,"Returning Modern restores show-off")

-- Freshly created GUI selector must recognize a persisted black choice.
local reopened=DFRL.tools.CreateColour(parent,nil,"Bars","highlightColor")
eq(reopened:GetValue(),31,"Color picker reload resolves exact black")
eq(reopened.colorSwatch.swatchColor[1],0,"Color swatch reload stays black")
-- The Settings sync path must use each color control's own palette count.
local elem=content("modules/gui/elem.lua")
eq(string.find(elem,"element.COLOR_COUNT",1,true)~=nil,true,
 "Settings sync uses dynamic available palette")
-- Ensure UI's new control is exposed and handlers don't use a false black.
local bars=content("modules/bars/bars.lua")
eq(string.find(bars,"highlightShow = {true, \"checkbox\"",1,true)~=nil,true,
 "Highlight toggle is an ordinary checkbox")
eq(string.find(bars,'SetBlendMode(black and "BLEND" or "ADD")',1,true)~=nil,true,
 "Black selects visible alpha blend rather than additive no-op")
eq(string.find(bars,'SetAlpha(visible and 1 or 0)',1,true)~=nil,true,
 "Toggling highlight does not turn off button input")
print("PASS action highlight controls: "..total.." assertions")
