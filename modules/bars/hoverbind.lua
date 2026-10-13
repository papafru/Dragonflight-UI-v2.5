-- Dragonflight UI: Reforged - mouseover keybinding for the 1.12/1.18 client.
-- Uses the original Blizzard binding commands so action-bar paging, stances,
-- pet commands and the existing DFRL hotkey renderer continue to work.
-- Written in Lua 5.0-compatible syntax; no ClassicAPI/SuperWoW DLL required.

local Bind = CreateFrame("Frame", "DFRL_MouseoverKeybindManager", UIParent)
DFRL.hoverbind = Bind

local BUTTON_GROUPS = {
    {"ActionButton", "ACTIONBUTTON", 12},
    {"MultiBarBottomLeftButton", "MULTIACTIONBAR1BUTTON", 12},
    {"MultiBarBottomRightButton", "MULTIACTIONBAR2BUTTON", 12},
    {"MultiBarRightButton", "MULTIACTIONBAR3BUTTON", 12},
    {"MultiBarLeftButton", "MULTIACTIONBAR4BUTTON", 12},
    {"BonusActionButton", "ACTIONBUTTON", 12},
    {"ShapeshiftButton", "SHAPESHIFTBUTTON", 10},
    {"PetActionButton", "BONUSACTIONBUTTON", 10},
}

Bind.active = false
Bind.hovered = nil
Bind.overlays = {}
Bind.refreshTimer = 0

local function Say(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff50c8ffDFRL Keybind:|r " .. message)
    end
end

local function CurrentKeys(command)
    -- Multiple return values must be captured as the final expression.
    -- Works on original Lua 5.0 and with ClassicAPI's Lua 5.1 extensions.
    local keys = { GetBindingKey(command) }
    return keys
end

local function KeyPrefix()
    local prefix = ""
    if IsAltKeyDown() then prefix = prefix .. "ALT-" end
    if IsControlKeyDown() then prefix = prefix .. "CTRL-" end
    if IsShiftKeyDown() then prefix = prefix .. "SHIFT-" end
    return prefix
end

local function IsModifier(key)
    return key == "SHIFT" or key == "LSHIFT" or key == "RSHIFT"
        or key == "CTRL" or key == "LCTRL" or key == "RCTRL"
        or key == "CONTROL" or key == "ALT" or key == "LALT"
        or key == "RALT" or key == "UNKNOWN" or key == ""
end

local function DisplayKey(key)
    if not key or key == "" then return "Unbound" end
    key = string.gsub(key, "MOUSEWHEELUP", "Wheel Up")
    key = string.gsub(key, "MOUSEWHEELDOWN", "Wheel Down")
    key = string.gsub(key, "BUTTON", "Mouse ")
    key = string.gsub(key, "SHIFT%-", "S-")
    key = string.gsub(key, "CTRL%-", "C-")
    key = string.gsub(key, "ALT%-", "A-")
    key = string.gsub(key, "NUMPAD", "Num ")
    return key
end

local function BindingsSaved()
    if type(SaveBindings) ~= "function" then
        Say("Bindings changed, but SaveBindings is unavailable. Save from the game's Key Bindings menu.")
        return
    end
    local which = 1
    if type(GetCurrentBindingSet) == "function" then
        which = GetCurrentBindingSet() or 1
    end
    local ok = pcall(SaveBindings, which)
    if not ok then
        Say("Could not save bindings; save them from the game's Key Bindings menu.")
    end
end

local function RestoreKeys(command, oldKeys)
    for i = 1, table.getn(oldKeys) do
        if oldKeys[i] then SetBinding(oldKeys[i], command) end
    end
end

local function ReplaceKey(command, newKey)
    local oldKeys = CurrentKeys(command)
    local previousCommand = GetBindingAction(newKey)

    -- A key already assigned to this action is a harmless no-op.
    if previousCommand == command then return true end

    -- Replace this action's old keys rather than leaving invisible extras.
    -- Preserve an unrelated command previously assigned to the new key so
    -- it can be restored if the client rejects the binding.
    for i = 1, table.getn(oldKeys) do
        if oldKeys[i] and not SetBinding(oldKeys[i]) then
            RestoreKeys(command, oldKeys)
            return false
        end
    end

    if not SetBinding(newKey, command) then
        if previousCommand and previousCommand ~= "" then
            SetBinding(newKey, previousCommand)
        else
            SetBinding(newKey)
        end
        RestoreKeys(command, oldKeys)
        return false
    end

    BindingsSaved()
    return true
end

local function ClearKeys(command)
    local oldKeys = CurrentKeys(command)
    for i = 1, table.getn(oldKeys) do
        if oldKeys[i] and not SetBinding(oldKeys[i]) then
            RestoreKeys(command, oldKeys)
            return false
        end
    end
    BindingsSaved()
    return true
end

local function CanShow(overlay)
    local button = overlay.target
    if not button or not button:IsVisible() then return false end
    if button.IsMouseEnabled and not button:IsMouseEnabled() then return false end
    if button.GetEffectiveAlpha then
        if button:GetEffectiveAlpha() < 0.05 then return false end
    else
        -- Vanilla has no GetEffectiveAlpha. A parent's alpha can hide the
        -- button without hiding the child frame itself.
        local alpha = 1
        local parent = button
        while parent do
            alpha = alpha * parent:GetAlpha()
            if alpha < 0.05 then return false end
            parent = parent:GetParent()
        end
    end
    return true
end

function Bind:UpdateStatus(message)
    if not self.statusText then return end
    if message then
        self.statusText:SetText(message)
    elseif self.hovered then
        self.statusText:SetText("Hovered: " .. self.hovered.target:GetName()
            .. "  |  " .. DisplayKey(GetBindingKey(self.hovered.command)))
    else
        self.statusText:SetText("Hover an action button, then press a key or mouse button.")
    end
end

function Bind:UpdateLabels()
    for i = 1, table.getn(self.overlays) do
        local overlay = self.overlays[i]
        overlay.label:SetText(DisplayKey(GetBindingKey(overlay.command)))
    end
    if self.active then self:UpdateStatus() end
end

function Bind:Select(overlay)
    if self.hovered == overlay then return end
    if self.hovered then self.hovered.fill:SetVertexColor(0.10, 0.42, 0.75, 0.33) end
    self.hovered = overlay
    if overlay then overlay.fill:SetVertexColor(0.18, 0.92, 0.73, 0.55) end
    self:UpdateStatus()
end

function Bind:HandleKey(raw)
    if not self.active then return end
    local key = string.upper(tostring(raw or ""))
    if key == "ESCAPE" then
        if self.hovered then
            if ClearKeys(self.hovered.command) then
                self:UpdateLabels()
                self:UpdateStatus("Cleared: " .. self.hovered.target:GetName())
            else
                self:UpdateStatus("Could not clear this binding.")
            end
        else
            self:Stop()
        end
        return
    end
    if not self.hovered or IsModifier(key) then return end
    if key == "LEFTBUTTON" or key == "BUTTON1" then return end
    if key == "RIGHTBUTTON" then
        key = "BUTTON2"
    elseif key == "MIDDLEBUTTON" then
        key = "BUTTON3"
    elseif string.find(key, "^BUTTON%d+$") then
        -- Button4, Button5 and any extra buttons reported by the client.
    elseif string.find(key, "^BUTTON") then
        return  -- reject unknown or vendor-specific mouse-button names
    end

    local binding = KeyPrefix() .. key
    if ReplaceKey(self.hovered.command, binding) then
        self:UpdateLabels()
        self:UpdateStatus("Bound " .. DisplayKey(binding) .. " to " .. self.hovered.target:GetName())
    else
        self:UpdateStatus("Unable to bind " .. DisplayKey(binding) .. ". Previous keys restored.")
    end
end

function Bind:CreateUI()
    if self.panel then return end

    local panel = CreateFrame("Frame", "DFRL_MouseoverKeybindPanel", UIParent)
    panel:SetFrameStrata("FULLSCREEN_DIALOG")
    panel:SetFrameLevel(50)
    panel:SetWidth(540)
    panel:SetHeight(80)
    panel:SetPoint("TOP", UIParent, "TOP", 0, -88)
    panel:EnableMouse(false)
    panel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    panel:SetBackdropColor(0.02, 0.04, 0.08, 0.92)
    panel:SetBackdropBorderColor(0.2, 0.65, 0.85, 0.95)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -12)
    title:SetText("DFRL | Mouseover Keybind Mode")

    local status = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    status:SetWidth(490)
    status:SetJustifyH("LEFT")
    status:SetText("Hover an action button, then press a key or mouse button.")

    local help = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    help:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -5)
    help:SetText("ESC = clear hovered  |  ESC off button = exit  |  Left click excluded")

    local close = CreateFrame("Button", "DFRL_MouseoverKeybindExit", panel, "UIPanelButtonTemplate")
    close:SetWidth(50)
    close:SetHeight(22)
    close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -9, -9)
    close:SetText("Exit")
    close:SetScript("OnClick", function() Bind:Stop() end)

    -- Mouse-disabled keyboard capture does not obscure the per-button hover
    -- targets; all action clicks are blocked by the visible overlays.
    local keyboard = CreateFrame("Frame", "DFRL_MouseoverKeybindKeyboard", UIParent)
    keyboard:SetFrameStrata("FULLSCREEN_DIALOG")
    keyboard:SetFrameLevel(100)
    keyboard:EnableMouse(false)
    keyboard:EnableKeyboard(false)
    keyboard:SetScript("OnKeyDown", function(_, key)
        Bind:HandleKey(key or arg1)
    end)
    keyboard:Hide()

    self.panel = panel
    self.statusText = status
    self.keyboard = keyboard
    panel:Hide()
end

function Bind:CreateOverlays()
    if table.getn(self.overlays) > 0 then return end
    for g = 1, table.getn(BUTTON_GROUPS) do
        local group = BUTTON_GROUPS[g]
        for i = 1, group[3] do
            local button = _G[group[1] .. i]
            if button then
                local overlay = CreateFrame("Frame", nil, UIParent)
                overlay.target = button
                overlay.DFRL_HoverBindOverlay = true
                overlay.command = group[2] .. i
                overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
                overlay:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
                overlay:SetFrameStrata("DIALOG")
                overlay:SetFrameLevel(40)
                overlay:EnableMouse(true)
                overlay:EnableMouseWheel(true)

                local fill = overlay:CreateTexture(nil, "BACKGROUND")
                fill:SetAllPoints(overlay)
                fill:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
                fill:SetVertexColor(0.10, 0.42, 0.75, 0.33)
                overlay.fill = fill

                local label = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                label:SetPoint("CENTER", overlay, "CENTER", 0, 0)
                label:SetWidth(45)
                label:SetText(DisplayKey(GetBindingKey(overlay.command)))
                overlay.label = label

                overlay:SetScript("OnEnter", function()
                    if Bind.active then Bind:Select(this) end
                end)
                overlay:SetScript("OnLeave", function()
                    if Bind.hovered == this then Bind:Select(nil) end
                end)
                overlay:SetScript("OnMouseDown", function(_, buttonName)
                    Bind:Select(this)
                    Bind:HandleKey(buttonName or arg1)
                end)
                overlay:SetScript("OnMouseWheel", function(_, delta)
                    Bind:Select(this)
                    delta = delta or arg1
                    if delta and delta > 0 then
                        Bind:HandleKey("MOUSEWHEELUP")
                    elseif delta and delta < 0 then
                        Bind:HandleKey("MOUSEWHEELDOWN")
                    end
                end)
                overlay:Hide()
                table.insert(self.overlays, overlay)
            end
        end
    end
end

function Bind:Start()
    if self.active then return end
    self:CreateUI()
    self:CreateOverlays()
    if table.getn(self.overlays) == 0 then
        Say("Action buttons are not ready. Try /kb after entering the world.")
        return
    end
    self.active = true
    self:Select(nil)
    self:UpdateLabels()
    self.panel:Show()
    self.keyboard:Show()
    self.keyboard:EnableKeyboard(true)
    self.refreshTimer = 1  -- force immediate visibility update
    self:RefreshVisibility()
    self:SetScript("OnUpdate", function()
        Bind.refreshTimer = Bind.refreshTimer + (arg1 or 0)
        if Bind.refreshTimer >= 0.1 then
            Bind.refreshTimer = 0
            Bind:RefreshVisibility()
        end
    end)
    Say("Enabled. Hover a button and press a key (or mouse button). ESC clears; Exit closes.")
end

function Bind:RefreshVisibility()
    for i = 1, table.getn(self.overlays) do
        local overlay = self.overlays[i]
        local visible = CanShow(overlay)
        if visible and not overlay:IsShown() then
            overlay:Show()
        elseif not visible and overlay:IsShown() then
            if self.hovered == overlay then self:Select(nil) end
            overlay:Hide()
        end
    end
    -- ClassicAPI's GetMouseFoci returns frames in hit-test order. Consider
    -- ONLY the top frame so we cannot bind an action bar hidden beneath a
    -- different dialog. Vanilla clients use the OnEnter/OnLeave handlers.
    if type(GetMouseFoci) == "function" then
        local foci = GetMouseFoci()
        if foci then
            local top = foci[1]
            if top and top.DFRL_HoverBindOverlay and top:IsShown() then
                self:Select(top)
            elseif self.hovered then
                self:Select(nil)
            end
        end
    end
end

function Bind:Stop()
    if not self.active then return end
    self.active = false
    self:SetScript("OnUpdate", nil)
    self:Select(nil)
    if self.keyboard then
        self.keyboard:EnableKeyboard(false)
        self.keyboard:Hide()
    end
    if self.panel then self.panel:Hide() end
    for i = 1, table.getn(self.overlays) do
        self.overlays[i]:Hide()
    end
    Say("Disabled.")
end

SLASH_DFRL_KEYBIND1 = "/kb"
SlashCmdList["DFRL_KEYBIND"] = function()
    if Bind.active then Bind:Stop() else Bind:Start() end
end

Bind:RegisterEvent("UPDATE_BINDINGS")
Bind:SetScript("OnEvent", function()
    if Bind.active then Bind:UpdateLabels() end
end)
