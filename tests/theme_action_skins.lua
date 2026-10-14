-- Milestone 3A action button skin contract tests (Lua 5.1).
-- This file creates simulated UI frames; no game client is needed.
local checkCount=0
local function eq(actual,expected,label)
    checkCount=checkCount+1
    if actual~=expected then error(label..": "..tostring(actual).." ~= "..tostring(expected)) end
end
if not table.getn then table.getn = function(a) return #a end end
local created=0
local textures=0
local function Base(t,shown)
    local obj={kind=t,shown=shown~=false,points={},children={},mouse=true}
    function obj:SetTexture(path) self.path=path end
    function obj:SetVertexColor(...) self.color={...} end
    function obj:SetHeight(h) self.height=h end
    function obj:SetWidth(w) self.width=w end
    function obj:SetPoint(...) table.insert(self.points,{...}) end
    function obj:SetAllPoints(parent) self.allPoints=parent end
    function obj:SetFrameLevel(n) self.level=n end
    function obj:GetFrameLevel() return self.level or 5 end
    function obj:EnableMouse(b) self.mouse=b end
    function obj:Hide() self.shown=false end
    function obj:Show() self.shown=true end
    function obj:IsShown() return self.shown end
    function obj:CreateTexture(name,layer,template)
        eq(template,nil,"No unsupported numeric texture sublevel")
        local x=Base("Texture")
        x.name=name; x.layer=layer; textures=textures+1
        table.insert(self.children,x)
        return x
    end
    return obj
end
function CreateFrame(kind,name,parent)
    created=created+1
    local o=Base(kind)
    o.parent=parent
    if parent then table.insert(parent.children,o) end
    return o
end
local initializedCallbacks={}
local selected, listeners=nil,{}
_G.DFRL={
    theme={
        GetSelected=function() return selected end,
        AddListener=function(_,fn) table.insert(listeners,fn) end,
    },
    callbacks={},
    GetTempDB=function(_,module,key)
        if module=="Bars" and key=="highlightColor" then return {.5,.72,.88} end
    end,
    NewCallbacks=function(_,mod,callbacks)
        eq(mod,"Bars","Register only bars callback")
        initializedCallbacks=callbacks
        callbacks.highlightColor({.5,.72,.88})
    end,
}
local function changeTheme(id)
    selected=id
    for _,listener in ipairs(listeners) do listener(id) end
end
local function Button(name,originalShown)
    local button=Base("Button")
    button.name=name
    button.level=8
    local cb=function() end
    button.clickHandler=cb
    button.DFRL_BorderOverlay=Base("Texture",originalShown)
    _G[name]=button
    return button
end
local main1=Button("ActionButton1",true)
local main2=Button("ActionButton2",false)
local multi=Button("MultiBarBottomLeftButton1",true)
_G.DFRL_ActionButtonBorder1=Base("Texture",true)
_G.DFRL_ActionButtonBg1=Base("Texture",false)
_G.DFRL_ActionButtonBorder2=Base("Texture",true)
_G.DFRL_ActionButtonBg2=Base("Texture",true)
local root=string.match(arg[0], "^(.*[/\\])tests[/\\]") or ""
assert(loadfile(root.."modules/bars/skins.lua"))()
local skins=DFRL.actionButtonSkins
eq(skins.initialized,false,"Not initialized just by loading source")
eq(#skins.entries,0,"No orphan UI on module load")
eq(DFRL.InitActionButtonSkins(nil),false,"Reject missing Bars types")
eq(DFRL.InitActionButtonSkins({"ActionButton","MultiBarBottomLeftButton","PetActionButton"}),true,"Bars integration initializes")
eq(skins.initialized,true,"Module initialized")
eq(#skins.entries,3,"Only actual action buttons are decorated")
eq(#listeners,1,"Exactly one theme listener")
eq(#initializedCallbacks>0,false,"Callback table is not numerically indexed")
local createdAfterInit=created
local texturesAfterInit=textures
eq(texturesAfterInit,12,"Exactly four lines per button")
for _,entry in ipairs(skins.entries) do
    eq(entry.holder.shown,false,"Modern skin starts invisible")
    eq(entry.holder.mouse,false,"No mouse/click interception")
    eq(entry.holder.parent,entry.button,"Skin parent is action button")
    eq(entry.holder.allPoints,entry.button,"Skin tracks button size")
    eq(entry.holder.level,10,"Overlay frame above action button")
    eq(#entry.lines,4,"Four thin border lines")
    for index,line in ipairs(entry.lines) do
        eq(line.layer,"OVERLAY","Supported legacy drawing layer")
        eq(line.path,"Interface\\Buttons\\WHITE8X8","Shared neutral texture")
        eq(#line.points,2,"Line has two anchors")
        eq(index<=2 and line.height or line.width,2,"Two-point border")
    end
end
local beforeClick=main1.clickHandler
eq(main1.DFRL_BorderOverlay.shown,true,"Initial classic main border unchanged")
eq(main2.DFRL_BorderOverlay.shown,false,"Hidden original remains hidden")
eq(DFRL_ActionButtonBg1.shown,false,"Hidden main background unchanged")
changeTheme("modern")
eq(skins.entries[1].holder.shown,true,"Modern theme shows first border")
eq(main1.DFRL_BorderOverlay.shown,false,"Modern hides ornate overlay")
eq(DFRL_ActionButtonBorder1.shown,false,"Modern hides main bar fancy border")
eq(DFRL_ActionButtonBg1.shown,false,"Modern hides main bar existing background")
eq(multi.DFRL_BorderOverlay.shown,false,"Modern applies to multibar")
eq(skins.entries[1].lines[1].color[1],.5,"Modern tint uses existing highlight color")
-- Repeated Modern selection must not overwrite the captured baseline state.
changeTheme("modern")
eq(#skins.entries,3,"No new entries on repeated style choice")
eq(created,createdAfterInit,"Theme switching allocates no frames")
eq(textures,texturesAfterInit,"Theme switching allocates no textures")
DFRL.actionButtonSkins:Tint({.2,.5,.9})
eq(skins.entries[1].lines[1].color[1],.2,"Existing color property recolors border")
changeTheme("fantasy")
eq(skins.entries[1].holder.shown,false,"Fantasy hides modern overlay")
eq(main1.DFRL_BorderOverlay.shown,true,"Restores originally visible main overlay")
eq(main2.DFRL_BorderOverlay.shown,false,"Restores originally hidden overlay")
eq(DFRL_ActionButtonBorder1.shown,true,"Restores original main bar border")
eq(DFRL_ActionButtonBg1.shown,false,"Restores originally hidden main bar background")
eq(multi.DFRL_BorderOverlay.shown,true,"Restores multibar overlay")
eq(main1.clickHandler,beforeClick,"No action button handler modification")
changeTheme("modern")
changeTheme(nil)
eq(skins.entries[1].holder.shown,false,"Existing Appearance removes modern overlay")
eq(main1.DFRL_BorderOverlay.shown,true,"Existing Appearance restores baseline")
eq(DFRL.InitActionButtonSkins({"ActionButton"}),true,"Initializer idempotent")
eq(created,createdAfterInit,"Reinitialize never duplicates frames")
eq(#listeners,1,"Reinitialize never duplicates callback listener")
eq(DFRL.modules,nil,"Skin extension does not register a NewMod")
print("PASS Milestone 3A action skins: "..checkCount.." assertions")
