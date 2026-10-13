-- Mocked 1.18 UI tests for Milestone 2. No Retail-only helpers required.
if not getfenv then getfenv = function() return _G end end
if not setfenv then setfenv = function() end end
if not table.getn then table.getn = function(t) return #t end end
if not tinsert then tinsert = table.insert end
local report = print
local checks = 0
local function eq(a,b,msg)
    checks = checks + 1
    if a ~= b then error(msg..": expected "..tostring(b)..", got "..tostring(a)) end
end
local objs = {}
local frame_methods = {}
local function create(typeName, name, parent)
    local f={typeName=typeName, name=name, parent=parent, scripts={}, children={}, shown=true, enabled=true}
    setmetatable(f,{__index=frame_methods})
    table.insert(objs,f)
    if parent then table.insert(parent.children,f) end
    if name then _G[name]=f end
    return f
end
function frame_methods:CreateTexture() return create("Texture",nil,self) end
function frame_methods:CreateFontString() return create("FontString",nil,self) end
function frame_methods:SetScript(k,v) self.scripts[k]=v end
function frame_methods:GetScript(k) return self.scripts[k] end
function frame_methods:RegisterEvent(e) self.events=self.events or {}; self.events[e]=true end
function frame_methods:UnregisterEvent(e) self.events[e]=nil end
function frame_methods:SetWidth(x) self.width=x end
function frame_methods:SetHeight(x) self.height=x end
function frame_methods:SetPoint(...) self.point={...} end
function frame_methods:SetText(v) self.text=v end
function frame_methods:SetTextColor(...) self.textcolor={...} end
function frame_methods:SetVertexColor(...) self.color={...} end
function frame_methods:SetTexture(x) self.texture=x end
function frame_methods:SetFont(...) self.font={...} end
function frame_methods:SetBackdrop(...) self.backdrop={...} end
function frame_methods:SetBackdropColor(...) self.backdropColor={...} end
function frame_methods:SetBackdropBorderColor(...) self.borderColor={...} end
function frame_methods:SetFrameStrata(v) self.strata=v end
function frame_methods:SetToplevel(v) self.toplevel=v end
function frame_methods:EnableMouse(v) self.mouse=v end
function frame_methods:SetJustifyH(v) self.justify=v end
function frame_methods:Hide() self.shown=false end
function frame_methods:Show() self.shown=true; if self.scripts.OnShow then self.scripts.OnShow() end end
function frame_methods:IsShown() return self.shown end
function frame_methods:Enable() self.enabled=true end
function frame_methods:Disable() self.enabled=false end
function frame_methods:Click() if self.enabled and self.scripts.OnClick then self.scripts.OnClick() end end
function CreateFrame(t,n,p) return create(t,n,p) end
UIParent=create("Frame","UIParent",nil)
DEFAULT_CHAT_FRAME={AddMessage=function() end}
StaticPopupDialogs={}
YES,NO="Yes","No"
local popup
function StaticPopup_Show(name) popup=name; return {} end
function UnitName() return "TestCharacter" end
function IsAddOnLoaded() return false end
function GetTime() return 0 end
function geterrorhandler() return function(err) error(err) end end
function ReloadUI() end
function gcinfo() return 0 end

local root=string.match(arg[0], "^(.*[/\\])tests[/\\]") or ""
local function loadSource(path) assert(loadfile(root..path))() end
loadSource("core/core.lua")
loadSource("core/theme.lua")
loadSource("core/theme_ui.lua")
loadSource("core/theme_welcome.lua")
loadSource("modules/gui/themes.lua")
DFRL.tools.CreateButton = function(parent,label,w,h)
    local b=CreateFrame("Button",nil,parent)
    b:SetText(label)
    b:SetWidth(w)
    b:SetHeight(h)
    return b
end
local function initialize(profile,seen,state)
    DFRL_DB_SETUP={version=DFRL.DBversion}
    DFRL_PROFILES={Default=profile or {}}
    DFRL_CUR_PROFILE={TestCharacter="Default"}
    if seen then DFRL_CUR_PROFILE.TestCharacter_firstRun=true end
    DFRL_THEME_STATE=state
    DFRL.tempDB={}
    DFRL:NewDefaults("Bars",{enabled={true},barsDarkMode={0},mainBarScale={1}})
    DFRL:InitTempDB()
    DFRL.theme:Initialize()
end

-- Existing user: new first-run selector does not appear.
initialize({Bars={barsDarkMode=.4}},true,nil)
loadSource("core/first.lua")
local eventFrame=objs[#objs]
eventFrame.scripts.OnEvent()
eq(DFRL.theme:NeedsFirstRunChoice(),false,"old profile skips first run")
eq(DFRLThemeWelcome,nil,"no unexpected welcome frame")
eq(DFRL:GetTempDB("Bars","barsDarkMode"),.4,"legacy appearance untouched")

-- Fresh character: no selection until the player clicks a card AND Continue.
initialize({},false,nil)
eq(DFRL.theme:NeedsFirstRunChoice(),true,"new character sees choice")
eq(DFRL.ShowThemeWelcome(),true,"fresh welcome opens")
local welcome=DFRLThemeWelcome
eq(welcome.width,744,"welcome width")
eq(welcome.height,422,"welcome height")
eq(welcome.shown,true,"welcome shown")
local chosenCards={}
local go
for _,child in ipairs(welcome.children) do
    if child.typeName=="Button" and child.width==337 then table.insert(chosenCards,child) end
    if child.typeName=="Button" and child.text=="Continue" then go=child end
end
eq(#chosenCards,2,"exactly two visual cards")
eq(go.enabled,false,"continue starts disabled")
go:Click()
eq(DFRL.theme:GetSelected(),nil,"disabled Continue does not select")
chosenCards[2]:Click()
eq(DFRL.theme:GetSelected(),nil,"preview selection is not applied early")
eq(go.enabled,true,"Continue enabled after selection")
go:Click()
eq(DFRL.theme:GetSelected(),"modern","Continue applies chosen theme")
eq(DFRL.theme:NeedsFirstRunChoice(),false,"choice dismissed permanently")
eq(DFRL_CUR_PROFILE.TestCharacter_firstRun,true,"legacy welcome flag marked")
eq(welcome.shown,false,"welcome dismissed")
eq(DFRL:GetTempDB("Bars","barsDarkMode"),.85,"modern appearance applied")

-- Themes tab updates selection, offers neutral mode, and uses confirmation.
local scroll=create("Frame",nil,UIParent)
DFRL.InitThemeSettings({scrollChildren={[16]=scroll}})
eq(DFRL.themeSettingsReady,true,"Themes panel initialized")
local settingsCards={}
local restore,existing
for _,obj in ipairs(scroll.children) do
    if obj.width==335 and obj.typeName=="Button" then table.insert(settingsCards,obj) end
    if obj.text=="Restore Theme Defaults" then restore=obj end
    if obj.text=="Use Existing Appearance" then existing=obj end
end
eq(#settingsCards,2,"settings contains two cards")
eq(restore.enabled,true,"reset available with selected theme")
DFRL:SetTempDB("Bars","barsDarkMode",.6)
eq(DFRL:GetTempDB("Bars","barsDarkMode"),.6,"customization applied")
restore:Click()
eq(popup,"DFRL_THEME_RESET_CONFIRM","reset presents confirmation")
eq(DFRL:GetTempDB("Bars","barsDarkMode"),.6,"no mutation before accept")
StaticPopupDialogs[popup].OnCancel()
eq(DFRL:GetTempDB("Bars","barsDarkMode"),.6,"cancel does nothing")
restore:Click()
StaticPopupDialogs[popup].OnAccept()
eq(DFRL:GetTempDB("Bars","barsDarkMode"),.85,"accept resets chosen theme")
settingsCards[1]:Click()
eq(DFRL.theme:GetSelected(),"fantasy","switch from settings")
eq(DFRL:GetTempDB("Bars","barsDarkMode"),0,"fantasy palette")
existing:Click()
eq(DFRL.theme:GetSelected(),nil,"neutral legacy mode")
eq(DFRL:GetTempDB("Bars","barsDarkMode"),0,"neutral raw default")
eq(restore.enabled,false,"no reset in neutral mode")

-- Theme refresh synchronizes controls without writing rounded UI values back.
local syncCount=0
DFRL.gui.Base={SyncControls=function()
    syncCount=syncCount+1
    DFRL.suppressGuiWrites=true
    DFRL:SetTempDB("Bars","barsDarkMode",.9)
    DFRL:SetTempDBNoCallback("Bars","barsDarkMode",.9)
    DFRL.suppressGuiWrites=false
end}
DFRL.theme:Select("modern")
eq(syncCount,1,"one safe refresh of settings controls")
eq(DFRL:GetTempDB("Bars","barsDarkMode"),.85,"refresh never rounds preset to .9")
eq(DFRL.tempDB.Bars.barsDarkMode,0,"underlying profile untouched")

-- No accidental settings module registration.
eq(DFRL.modules.Themes,nil,"no new module checkbox")
report("PASS milestone 2 mocked client: "..checks.." assertions")
