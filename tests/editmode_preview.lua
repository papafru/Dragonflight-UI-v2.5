-- fruUI Edit Mode: hidden-target previews and exact visibility restoration.
if not table.getn then table.getn=function(a)return #a end end
floor=math.floor
local n=0
local function eq(a,b,msg)
 n=n+1
 if a~=b then error(msg..": expected "..tostring(b)..", got "..tostring(a)) end
end
local objects={}
local methods={}
local function frame(name,parent)
 local f={name=name,parent=parent,shown=true,children={},scripts={},points={},level=2,left=100,top=300}
 setmetatable(f,{__index=methods})
 if parent then table.insert(parent.children,f) end
 if name then _G[name]=f end
 table.insert(objects,f)
 return f
end
function CreateFrame(_,name,parent) return frame(name,parent) end
UIParent=frame("UIParent")
function methods:RegisterEvent(e) self.event=e end
function methods:UnregisterEvent(e) self.event=nil end
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:GetScript(k) return self.scripts[k] end
function methods:SetPoint(...)
  local args={...}
  table.insert(self.points,args)
  if args[1]=="TOPLEFT" and args[2]==UIParent and args[3]=="BOTTOMLEFT" then
    self.left,self.top=args[4],args[5]
  end
end
function methods:ClearAllPoints() self.points={} end
function methods:SetAllPoints(o) self.allPoints=o end
function methods:SetWidth(x) self.width=x end
function methods:SetHeight(y) self.height=y end
function methods:SetFrameStrata(x) self.strata=x end
function methods:SetFrameLevel(x) self.level=x end
function methods:SetToplevel(x) self.toplevel=x end
function methods:EnableMouse(x) self.mouse=x end
function methods:SetMovable(x) self.movable=x end
function methods:Hide() self.shown=false;self.hides=(self.hides or 0)+1 end
function methods:Show() self.shown=true;self.shows=(self.shows or 0)+1 end
function methods:IsShown() return self.shown end
function methods:IsVisible()
 return self.shown and (not self.parent or self.parent:IsVisible())
end
function methods:SetBackdrop(...) end
function methods:SetBackdropColor(...) end
function methods:SetBackdropBorderColor(...) end
function methods:SetTexture(...) end
function methods:SetVertexColor(...) end
function methods:CreateTexture(...) return frame(nil,self) end
function methods:SetText(text) self.text=text end
function methods:SetTextColor(...) self.textColor={...} end
function methods:SetShadowColor(...) self.shadowColor={...} end
function methods:SetShadowOffset(...) self.shadowOffset={...} end
function methods:CreateFontString(...) return frame(nil,self) end
function methods:GetNormalTexture() return frame(nil,self) end
function methods:GetHighlightTexture() return frame(nil,self) end
function methods:GetPushedTexture() return frame(nil,self) end
function methods:GetName() return self.name end
function methods:GetLeft() return self.left end
function methods:GetTop() return self.top end
function methods:StartMoving() self.moving=true end
function methods:StopMovingOrSizing() self.moving=false end
function GetScreenWidth() return 1920 end
function GetScreenHeight() return 1080 end
local unit={target=false,targettarget=false}
function UnitExists(id) return unit[id] or false end
local callbacks={}
_G.DFRL={
 activeScripts={},
 NewDefaults=function(self,name,defaults) end,
 NewMod=function(self,name,priority,fn) callbacks[name]=fn end,
 GetTempDB=function(_,module,key)
   if module=="TargetCastbar" and key=="enemyCastbarAutoPosition" then return true end
   return false
 end,
 SetTempDBNoCallback=function() end,
}
DFRL_FRAMEPOS={}
PlayerFrame=frame("PlayerFrame",UIParent)
TargetFrame=frame("TargetFrame",UIParent)
TargetofTargetFrame=frame("TargetofTargetFrame",TargetFrame)
TargetFrame:Hide()
TargetofTargetFrame:Hide()
-- Sparse optional list regression: later entries must all remain registered.
DFRL.mainBar=frame("DFRLMainBar",UIParent)
DFRL.mainBar:Hide()
MultiBarRight=frame("MultiBarRight",UIParent)
MultiBarRight:Hide()
PartyMemberFrame1=frame("PartyMemberFrame1",UIParent)
PartyMemberFrame1:Hide()
BuffButton32=frame("BuffButton32",UIParent)
BuffButton32:Hide()
DFRL.netStatsFrame=frame("DFRLNetStats",UIParent)
DFRL.netStatsFrame:Hide()
DFRL.castbar=frame("DFRLCastbar",UIParent)
DFRL.castbar.bar=frame("DFRLCastbarFill",DFRL.castbar)
DFRL.castbar:Hide()
DFRL.targetCastbar=frame("DFRLTargetCastbar",UIParent)
DFRL.targetCastbar:Hide()
local root=string.match(arg[0],"^(.*[/\\])tests[/\\]") or ""
assert(loadfile(root.."modules/frames/frames.lua"))()
eq(type(callbacks.Frames),"function","Existing Frames module registration")
callbacks.Frames()
local worldEvent
for _,obj in ipairs(objects) do
 if obj.event=="PLAYER_ENTERING_WORLD" then worldEvent=obj end
end
eq(worldEvent~=nil,true,"OnWorld event registered")
worldEvent.scripts.OnEvent()
local edit=DFRL.EditMode
eq(edit.ready,true,"Edit controller ready")
eq(TargetFrame:IsShown(),false,"Original target missing")
eq(TargetofTargetFrame:IsShown(),false,"Original ToT missing")
eq(edit:Start(),true,"Edit Mode starts")
eq(TargetFrame:IsShown(),false,"No fake target unit is shown during Edit Mode")
eq(TargetofTargetFrame:IsShown(),false,"No fake ToT unit is shown during Edit Mode")
eq(TargetFrame.shows or 0,0,"Never force nonexistent target to show")
eq(TargetofTargetFrame.shows or 0,0,"Never force nonexistent ToT to show")
eq(DFRL.mainBar:IsShown(),true,"Later optional action bar exposed in Edit Mode")
eq(MultiBarRight:IsShown(),true,"Hidden vertical action bar exposed")
eq(PartyMemberFrame1:IsShown(),true,"Hidden party frame exposed")
eq(BuffButton32:IsShown(),true,"Hidden buff anchor exposed beyond holes in list")
eq(DFRL.netStatsFrame:IsShown(),true,"Net stats anchor exposed")
eq(DFRL.castbar:IsShown(),true,"Cast bar anchor exposed")
eq(DFRL.castbar.bar:IsShown(),false,"Castbar fill remains intentionally hidden")
eq(DFRL.targetCastbar:IsShown(),false,"Auto-positioned enemy castbar is excluded")
eq(TargetofTargetFrame:IsVisible(),false,"ToT remains naturally hidden with no unit")
local overlayTarget,overlayToT,overlayBuff
for _,e in ipairs(edit.overlays) do
 if e.frame==TargetFrame then overlayTarget=e.overlay end
 if e.frame==TargetofTargetFrame then overlayToT=e.overlay end
 if e.frame==BuffButton32 then overlayBuff=e.overlay end
end
eq(overlayTarget~=nil,true,"Target registered movable")
eq(overlayToT~=nil,true,"ToT registered movable")
eq(overlayBuff~=nil,true,"Later sparse frame registered movable")
eq(overlayTarget:IsShown(),true,"Target proxy overlay visible without a unit")
eq(overlayToT:IsShown(),true,"ToT proxy overlay visible without a unit")
eq(overlayTarget.parent,UIParent,"Target proxy independent of native frame visibility")
eq(overlayToT.parent,UIParent,"ToT proxy independent of native frame visibility")
local totShows=overlayToT.shows or 0
local targetShows=overlayTarget.shows or 0
eq(overlayTarget.nameText.text,"Target Frame","Target has readable name")
eq(overlayToT.nameText.text,"Target of Target","ToT has readable name")
eq(overlayBuff.nameText.text,"Buff Group 32","Buff anchor has readable name")
local playerOverlay,mainOverlay,rightOverlay,partyOverlay
for _,entry in ipairs(edit.overlays) do
 if entry.frame==PlayerFrame then playerOverlay=entry.overlay end
 if entry.frame==DFRL.mainBar then mainOverlay=entry.overlay end
 if entry.frame==MultiBarRight then rightOverlay=entry.overlay end
 if entry.frame==PartyMemberFrame1 then partyOverlay=entry.overlay end
end
eq(playerOverlay.nameText.text,"Player Frame","Player frame named")
eq(mainOverlay.nameText.text,"Main Action Bar","Main bar named")
eq(rightOverlay.nameText.text,"Right Action Bar","Right action bar named")
eq(partyOverlay.nameText.text,"Party Member 1","Party frame named")
eq(overlayTarget.nameText.textColor[1],1,"Caption uses high contrast white")
eq(overlayTarget.nameText.shadowColor[4],1,"Caption has dark text shadow")
-- The native client can hide both frames during target events while editing.
TargetFrame:Hide()
TargetofTargetFrame:Hide()
BuffButton32:Hide()
DFRL.castbar.bar:Hide()
for i=1,8 do
  edit:RefreshOverlays() -- native client repeatedly hides nonexistent units
  eq(TargetFrame:IsShown(),false,"Editor never resurrects nonexistent target")
  eq(TargetofTargetFrame:IsShown(),false,"Editor never resurrects nonexistent ToT")
  eq(overlayTarget:IsShown(),true,"Target proxy remains stable")
  eq(overlayToT:IsShown(),true,"ToT proxy remains stable")
end
eq(overlayTarget.shows or 0,targetShows,"Target proxy is not recreated/flickered")
eq(overlayToT.shows or 0,totShows,"ToT proxy is not recreated/flickered")
eq(TargetFrame.shows or 0,0,"Target unit never receives extra Show calls")
eq(TargetofTargetFrame.shows or 0,0,"ToT never receives extra Show calls")
eq(overlayTarget:IsShown(),true,"Target drag overlay returns after native hide")
eq(overlayToT:IsShown(),true,"ToT overlay returns after native hide")
eq(BuffButton32:IsShown(),true,"Hidden extra frame reappears during Edit Mode")
eq(overlayBuff:IsShown(),true,"Extra overlay reappears")
eq(DFRL.castbar.bar:IsShown(),false,"Intentional cast fill suppression survives refresh")
-- A target can be moved even though there is no actual target unit.
overlayTarget.scripts.OnMouseDown()
eq(overlayTarget.moving,true,"Independent target drag proxy starts moving")
local originalFrameX=TargetFrame:GetLeft()
local originalFrameY=TargetFrame:GetTop()
local startX=overlayTarget:GetLeft()
local startY=overlayTarget:GetTop()
overlayTarget.left=startX+35
overlayTarget.top=startY-21
overlayTarget.scripts.OnMouseUp()
eq(overlayTarget.moving,false,"Independent target drag proxy stops moving")
eq(DFRL_FRAMEPOS.TargetFrame.x,originalFrameX+35,"Target drag delta persisted")
eq(DFRL_FRAMEPOS.TargetFrame.y,originalFrameY-21,"Target vertical delta persisted")
eq(overlayTarget.points[1][2],TargetFrame,"Target proxy reattaches to actual frame")
overlayToT.scripts.OnMouseDown()
eq(overlayToT.moving,true,"ToT can be dragged without a real unit")
overlayToT.scripts.OnMouseUp()
eq(overlayToT.moving,false,"ToT proxy mouse up completes drag")
eq(DFRL_FRAMEPOS.TargetofTargetFrame.x,100,"ToT click without movement has no position jump")
eq(DFRL_FRAMEPOS.TargetofTargetFrame.y,300,"ToT click without movement has no vertical jump")
edit:Stop()
eq(TargetFrame:IsShown(),false,"Target hidden after edit with no unit")
eq(TargetofTargetFrame:IsShown(),false,"ToT hidden after edit with no unit")
eq(DFRL.mainBar:IsShown(),false,"Extra action bar restored to hidden")
eq(MultiBarRight:IsShown(),false,"Vertical action bar restored to hidden")
eq(PartyMemberFrame1:IsShown(),false,"Party frame restored to hidden")
eq(BuffButton32:IsShown(),false,"Buff frame restored to hidden")
eq(DFRL.netStatsFrame:IsShown(),false,"Net stats restored to hidden")
eq(DFRL.castbar:IsShown(),false,"Cast bar restored to hidden")
eq(DFRL.castbar.bar:IsShown(),true,"Cast fill original own visibility restored")
eq(DFRL.targetCastbar:IsShown(),false,"Auto castbar remains untouched")
eq(overlayTarget:IsShown(),false,"Target edit overlay hidden")
eq(overlayToT:IsShown(),false,"ToT edit overlay hidden")
eq(DFRL.activeScripts.FrameControlScript,false,"FrameControl script deactivated")
-- If a real target was acquired during editing, do not hide it on exit.
edit:Start()
unit.target=true
unit.targettarget=true
TargetFrame:Show() -- native frame handler, not Edit Mode
TargetofTargetFrame:Show()
edit:Stop()
eq(TargetFrame:IsShown(),true,"Native real target remains visible after edit")
eq(TargetofTargetFrame:IsShown(),true,"Native real ToT remains visible after edit")
-- If the target existed before editing but disappeared while editing, hide it.
unit.target=true
unit.targettarget=true
edit:Start()
unit.target=false
unit.targettarget=false
TargetFrame:Hide()
TargetofTargetFrame:Hide()
edit:Stop()
eq(TargetFrame:IsShown(),false,"Native lost target is not left as ghost")
eq(TargetofTargetFrame:IsShown(),false,"Native lost ToT is not left as ghost")
-- Temporarily exposed status bars are still returned to their original state.
eq(edit.active,false,"Edit controller stopped")
print("PASS Edit Mode target previews: "..n.." assertions")
