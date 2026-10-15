-- Dragonflight UI v2.5 regression: transactional mouseover bindings, Lua 5.1 client mock.
if not table.getn then table.getn=function(t) return #t end end
local n=0
local function same(actual,expected,reason)
  n=n+1
  if actual~=expected then error(reason..": "..tostring(actual).." != "..tostring(expected)) end
end
local frames={}
local methods={}
local function frame(name,parent)
  local f={name=name,parent=parent,scripts={},children={},shown=true,enabled=true,alpha=1}
  setmetatable(f,{__index=methods})
  if parent then table.insert(parent.children,f) end
  if name then _G[name]=f end
  table.insert(frames,f)
  return f
end
function CreateFrame(kind,name,parent)
  local f=frame(name,parent)
  f.kind=kind
  return f
end
UIParent=frame("UIParent")
function methods:RegisterEvent(s) self.events=self.events or {};self.events[s]=true end
function methods:SetScript(k,f) self.scripts[k]=f end
function methods:GetScript(k) return self.scripts[k] end
function methods:SetPoint(...) self.point={...} end
function methods:GetPoint() if self.point then return unpack(self.point) end end
function methods:ClearAllPoints() self.point=nil end
function methods:GetHeight() return self.height end
function methods:GetTop() return self.top or 400 end
function methods:GetBottom() return self.bottom or 100 end
function methods:GetObjectType() return self.kind or "Frame" end
function methods:GetChildren() return unpack(self.children) end
function methods:SetAllPoints(other) self.allPoints=other end
function methods:SetWidth(x) self.width=x end
function methods:SetHeight(x) self.height=x end
function methods:SetFrameStrata(x) self.strata=x end
function methods:SetFrameLevel(x) self.level=x end
function methods:EnableMouse(x) self.mouse=x end
function methods:EnableMouseWheel(x) self.wheel=x end
function methods:EnableKeyboard(x) self.keyboard=x end
function methods:SetBackdrop(x) self.backdrop=x end
function methods:SetBackdropColor(...) end
function methods:SetBackdropBorderColor(...) end
function methods:Hide() self.shown=false end
function methods:Show() self.shown=true end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function methods:GetEffectiveAlpha() return self.alpha end
function methods:IsMouseEnabled() return self.mouse~=false end
function methods:GetName() return self.name end
function methods:SetText(t) self.text=t end
function methods:SetTextColor(...) end
function methods:SetJustifyH(x) self.justify=x end
function methods:SetVertexColor(...) self.color={...} end
function methods:SetTexture(...) self.texture={...} end
function methods:Enable() self.enabled=true end
function methods:Disable() self.enabled=false end
function methods:CreateFontString()
  return frame(nil,self)
end
function methods:CreateTexture()
  return frame(nil,self)
end

local map={ ["1"]="ACTIONBUTTON1",["2"]="ACTIONBUTTON2",["J"]="EXTRAACTION",["ALT-3"]="ACTIONBUTTON1" }
local disk={}
local writes=0
local saveFailure=false
for k,v in pairs(map) do disk[k]=v end
function GetBindingAction(key) return map[key] or "" end
function GetBindingKey(command)
  local keys={}
  -- fixed order for two-key binding restoration checks
  for _,key in ipairs({"1","ALT-3","2","J","K","E","F","MOUSEWHEELUP","BUTTON3","SHIFT-K"}) do
    if map[key]==command then table.insert(keys,key) end
  end
  return unpack(keys)
end
function SetBinding(key,command)
  if not key or key=="" then return false end
  map[key]=command
  return true
end
function GetCurrentBindingSet() return 2 end
function SaveBindings(which)
  same(which,2,"Save uses original binding set")
  writes=writes+1
  if saveFailure then return false end
  disk={}
  for k,v in pairs(map) do disk[k]=v end
  return 1
end
function IsAltKeyDown() return false end
function IsShiftKeyDown() return false end
function IsControlKeyDown() return false end
DEFAULT_CHAT_FRAME={AddMessage=function()end}
SlashCmdList={}
_G.DFRL={}
frame("ActionButton1",UIParent)
frame("ActionButton2",UIParent)
local root=string.match(arg[0],"^(.*[/\\])tests[/\\]") or ""
assert(loadfile(root.."modules/bars/hoverbind.lua"))()
local bind=DFRL.hoverbind
local function selectButton(idx)
  for _,o in ipairs(bind.overlays) do
    if o.target:GetName()=="ActionButton"..idx then bind:Select(o);return o end
  end
  error("Missing overlay: "..idx)
end
same(bind.active,false,"not active on load")
bind:Start()
same(bind.active,true,"/kb starts")
same(bind.saveButton.enabled,false,"save starts disabled")
same(writes,0,"start never writes bindings")
local a=selectButton(1)
bind:HandleKey("RIGHTBUTTON")
bind:HandleKey("BUTTON2")
bind:HandleKey("LEFTBUTTON")
bind:HandleKey("BUTTON1")
same(bind.pending,false,"left and right click never register")
same(map["1"],"ACTIONBUTTON1","right click does not change old key")
same(map["BUTTON2"],nil,"right-click never assigned even with overlay selected")
bind:HandleKey("J")
same(map["J"],"ACTIONBUTTON1","live preview displaces unrelated action")
same(map["1"],nil,"old primary binding removed from live preview")
same(map["ALT-3"],nil,"old secondary binding removed from live preview")
same(bind.pending,true,"unsaved state set")
same(bind.saveButton.enabled,true,"save button enabled")
same(writes,0,"key assignment remains unsaved")
selectButton(2)
bind:HandleKey("K")
same(map["K"],"ACTIONBUTTON2","second action preview assigned")
same(map["2"],nil,"second action old key gone")
selectButton(1)
bind:HandleKey("ESCAPE")
same(bind.active,true,"Escape over an action stays in keybind mode")
same(map["J"],nil,"Escape clears hovered action's provisional key")
same(map["K"],"ACTIONBUTTON2","Escape leaves other pending bindings untouched")
same(bind.pending,true,"Escape clear is still unsaved")
same(writes,0,"Escape over action never calls SaveBindings")
same(bind.escapeGuard,true,"Escape keyboard route sets duplicate guard")
bind.escapeGuardFrame.scripts.OnUpdate()
same(bind.escapeGuard,false,"Escape guard expires on next rendered frame")
bind:Select(nil)
bind:HandleKey("ESCAPE")
same(bind.active,false,"Escape away from overlays cancels pending session")
same(writes,0,"Escape outside never calls SaveBindings")
same(map["1"],"ACTIONBUTTON1","original primary recovered")
same(map["ALT-3"],"ACTIONBUTTON1","original alternate recovered")
same(map["2"],"ACTIONBUTTON2","other action recovered")
same(map["J"],"EXTRAACTION","displaced unrelated command recovered")
same(map["K"],nil,"session created key removed")
same(bind.escapeGuard,true,"cancel outside also guards matching menu toggle")
bind.escapeGuardFrame.scripts.OnUpdate()
same(bind.escapeGuard,false,"cancel guard expires on next frame")
bind:Start()
selectButton(1)
bind:HandleKey("DELETE")
same(map["1"],nil,"Delete clears hovered command as preview")
same(bind.pending,true,"clear is unsaved")
bind:Cancel()
same(map["1"],"ACTIONBUTTON1","cancel undoes clear")
same(map["ALT-3"],"ACTIONBUTTON1","cancel undoes alternate clear")
bind:Start()
selectButton(1)
bind:HandleKey("E")
same(bind:SaveChanges(),true,"Save Changes completes")
same(bind.active,false,"save closes mode")
same(writes,1,"explicit SaveBindings called exactly once")
same(disk["E"],"ACTIONBUTTON1","persisted assignment is new key")
same(disk["J"],"EXTRAACTION","unrelated key not persisted incorrectly")
same(disk["1"],nil,"old binding removed when confirmed")
bind:Start()
selectButton(2)
bind:HandleKey("F")
saveFailure=true
same(bind:SaveChanges(),false,"failed SaveBindings keeps session active")
same(bind.active,true,"save failure does not discard edit journal")
same(bind.pending,true,"save failure still pending")
saveFailure=false
bind:Stop()
same(map["F"],nil,"Cancel via Stop restores failed-save preview")
same(map["2"],"ACTIONBUTTON2","Stop restores original binding")
same(writes,2,"failed Save attempted once, never silently retried")
-- Edit Mode activation calls Stop(), which also cancels.
bind:Start()
selectButton(1)
bind:HandleKey("BUTTON3")
same(map["BUTTON3"],"ACTIONBUTTON1","middle click can be bound")
bind:Stop()
same(map["BUTTON3"],nil,"handoff cancel restores middle mouse")
same(map["E"],"ACTIONBUTTON1","previous saved session remains intact")
-- Cancel button callback uses same rollback path.
bind:Start()
selectButton(1)
bind:HandleKey("MOUSEWHEELUP")
DFRL_MouseoverKeybindExit.scripts.OnClick()
same(map["MOUSEWHEELUP"],nil,"Cancel button undoes wheel binding")
same(bind.active,false,"Cancel button ends mode")
-- Both legacy ESC input paths must clear when hovering and cancel outside.
local menu=frame("MockGameMenu",UIParent)
menu:SetHeight(320)
menu:Hide()
local keyButton=frame("MockKeyButton",menu)
keyButton:SetPoint("TOP",menu,"BOTTOM",0,0)
DFRL.menuframe=menu
DFRL.menuButtons={keybindings=keyButton}
DFRL.tools={CreateButton=function(parent,label,w,h)
    local button=CreateFrame("Button",nil,parent)
    button:SetText(label)
    button:SetWidth(w)
    button:SetHeight(h)
    return button
end}
DFRL.EditMode={active=false,ready=true,IsActive=function(self)return self.active end,
    Start=function()return true end,Stop=function()end}
StaticPopupDialogs={}
YES,NO="Yes","No"
local opened=0
ToggleGameMenu=function() opened=opened+1 end
assert(loadfile(root.."modules/menu/editmode.lua"))()
DFRL.InitEditModeMenu()
same(DFRL.editModeMenuInitialized,true,"ESC menu extension initialized")
bind:Start()
selectButton(2)
bind:HandleKey("K")
same(bind.pending,true,"preview pending before menu ESC")
ToggleGameMenu()
same(bind.active,true,"Menu ESC over hovered button stays in keybind mode")
same(map["K"],nil,"Menu ESC clears hovered assignment")
same(map["2"],nil,"Menu ESC clears old action key too")
same(writes,2,"Menu ESC does not persist changes")
same(opened,0,"ESC while keybinding never opens menu")
bind:Select(nil)
bind.escapeGuardFrame.scripts.OnUpdate()
ToggleGameMenu()
same(bind.active,false,"Menu ESC away cancels the session")
same(map["2"],"ACTIONBUTTON2","Menu ESC outside restores previous assignment")
same(opened,0,"Menu ESC outside does not open game menu")

bind:Start()
selectButton(2)
bind:HandleKey("ESCAPE")
same(bind.active,true,"OnKeyDown ESC over hover only clears")
same(map["2"],nil,"Keyboard ESC clears original action")
same(bind.pending,true,"Clear via OnKeyDown is pending")
ToggleGameMenu()
same(bind.active,true,"Duplicate menu ESC does not leave mode")
same(map["2"],nil,"Duplicate menu ESC does not rebind key")
same(opened,0,"Duplicate ESC route swallowed")
bind.escapeGuardFrame.scripts.OnUpdate()
bind:Select(nil)
bind:HandleKey("ESCAPE")
ToggleGameMenu()
same(bind.active,false,"OnKeyDown ESC outside cancels")
same(map["2"],"ACTIONBUTTON2","Outside cancellation rolls back clear")
same(opened,0,"Second route for outside ESC swallowed")
bind.escapeGuardFrame.scripts.OnUpdate()
ToggleGameMenu()
same(opened,1,"Normal game menu works on later ESC")

-- ESC over an unbound button is a harmless no-op; Save stays disabled.
bind:Start()
selectButton(2)
bind:HandleKey("ESCAPE")
same(bind.pending,true,"First ESC clears existing binding")
bind.escapeGuardFrame.scripts.OnUpdate()
bind:HandleKey("ESCAPE")
same(bind.active,true,"Second ESC over already cleared action keeps mode")
same(bind.pending,true,"No extra journal edit for already clear")
bind:Select(nil)
bind.escapeGuardFrame.scripts.OnUpdate()
bind:HandleKey("ESCAPE")
same(map["2"],"ACTIONBUTTON2","Cancel restores keys after repeated hover ESC")
print("PASS transactional keybinds + ESC menu integration: "..n.." assertions")
