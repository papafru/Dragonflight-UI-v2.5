-- fruUI Theme Foundation (schema 1).
-- Loaded after core.lua and BEFORE ADDON_LOADED initialises profiles/modules.
-- This is deliberately not a NewMod: the Modules options grid has 24 slots.
-- Appearance is an overlay; legacy profile data remains untouched.

local Theme = {}
DFRL.theme = Theme

local function CopyValue(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for k, v in pairs(value) do copy[k] = CopyValue(v) end
    return copy
end

local function SameValue(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for k, v in pairs(a) do
        if not SameValue(v, b[k]) then return false end
    end
    for k in pairs(b) do
        if a[k] == nil then return false end
    end
    return true
end

local function ValidValue(value, model)
    if type(value) ~= type(model) then return false end
    if type(model) == "number" then
        return value == value and value >= 0 and value <= 1
    elseif type(model) == "table" then
        -- These keys are colors, not general-purpose configuration tables.
        for i = 1, 3 do
            if type(value[i]) ~= "number" or value[i] ~= value[i]
                or value[i] < 0 or value[i] > 1 then return false end
        end
        for k in pairs(value) do
            if k ~= 1 and k ~= 2 and k ~= 3 then return false end
        end
    end
    return true
end

-- Only explicitly listed, already-supported appearance properties may be
-- themed. Sizes, positions, bindings, module enablement, and behavior are
-- intentionally absent. Future visual skins can expand this catalog safely.
Theme.presets = {
    fantasy = {
        Bars = {barsDarkMode = 0, barsColor = {1, 1, 1}, highlightColor = {1, .82, 0}, showGryphoon = true},
        Bags = {bagDarkMode = 0, bagColor = {1, 1, 1}},
        Cast = {castDarkMode = 0, castColor = {.9, .9, .9}},
        Chat = {chatDarkMode = 0, chatColor = {1, 1, 1}},
        Micro = {microDarkMode = 0, microColor = {1, 1, 1}},
        Player = {playerDarkMode = 0, playerColor = {1, 1, 1}},
        Target = {targetDarkMode = 0, targetColor = {1, 1, 1}},
        Xprep = {xprepDarkMode = 0, xprepColor = {1, 1, 1}},
        -- Round remains the Fantasy theme default; shape can be overridden
        -- per theme without touching the character's legacy map settings.
        Map = {mapSquare = false},
    },
    modern = {
        Bars = {barsDarkMode = .85, barsColor = {.76, .82, .9}, highlightColor = {.5, .72, .88}, showGryphoon = false},
        Bags = {bagDarkMode = .85, bagColor = {.82, .86, .93}},
        Cast = {castDarkMode = .8, castColor = {.68, .79, .9}},
        Chat = {chatDarkMode = .8, chatColor = {.85, .9, 1}},
        Micro = {microDarkMode = .85, microColor = {.8, .86, .95}},
        Player = {playerDarkMode = .85, playerColor = {.82, .86, .94}},
        Target = {targetDarkMode = .85, targetColor = {.82, .86, .94}},
        Xprep = {xprepDarkMode = .85, xprepColor = {.8, .86, .95}},
        -- Modern Dark is square by default, but the Map checkbox still
        -- stores an independent per-theme override when toggled.
        Map = {mapSquare = true},
    },
}

function Theme:GetSelected()
    if not self.state then return nil end
    return self.presets[self.state.selected] and self.state.selected or nil
end

function Theme:NeedsFirstRunChoice()
    return self.state and self.state.needsChoice == true or false
end

function Theme:Initialize()
    -- Per-character SavedVariables are restored by the WoW client before
    -- the addon's ADDON_LOADED event. NEVER bump DFRL.DBversion for themes.
    local state = DFRL_THEME_STATE
    if type(state) ~= "table" or state.schema ~= 1 then
        local char = UnitName("player")
        local activeProfile = DFRL_CUR_PROFILE[char] or "Default"
        local hasOldWelcome = DFRL_CUR_PROFILE[char .. "_firstRun"] == true
        local profile = DFRL_PROFILES[activeProfile]
        local hasSavedProfile = type(profile) == "table" and next(profile) ~= nil
        state = {
            schema = 1,
            selected = nil,
            -- Existing players remain exactly as configured, without a prompt.
            needsChoice = not (hasOldWelcome or hasSavedProfile),
            overrides = {fantasy = {}, modern = {}},
        }
        DFRL_THEME_STATE = state
    end
    if type(state.overrides) ~= "table" then state.overrides = {} end
    if type(state.overrides.fantasy) ~= "table" then state.overrides.fantasy = {} end
    if type(state.overrides.modern) ~= "table" then state.overrides.modern = {} end
    if not self.presets[state.selected] then state.selected = nil end
    if type(state.needsChoice) ~= "boolean" then state.needsChoice = false end
    self.state = state
end

function Theme:Supports(module, key)
    return self.presets.fantasy[module] ~= nil
        and self.presets.fantasy[module][key] ~= nil
        and self.presets.modern[module] ~= nil
        and self.presets.modern[module][key] ~= nil
end

function Theme:Resolve(module, key, profileValue)
    local selected = self:GetSelected()
    if not selected or not self:Supports(module, key) then return profileValue end
    local model = self.presets[selected][module][key]
    local bucket = self.state.overrides[selected][module]
    local override = bucket and bucket[key]
    if override ~= nil and ValidValue(override, model) then
        return CopyValue(override)
    end
    return CopyValue(model)
end

function Theme:WriteOverride(module, key, value)
    local selected = self:GetSelected()
    if not selected or not self:Supports(module, key) then return false end
    local model = self.presets[selected][module][key]
    -- The key is owned by the theme; reject malformed data without writing
    -- it into the legacy profile's raw tempDB.
    if not ValidValue(value, model) then return true end
    local overrides = self.state.overrides[selected]
    overrides[module] = overrides[module] or {}
    if SameValue(value, model) then
        overrides[module][key] = nil
    else
        overrides[module][key] = CopyValue(value)
    end
    if next(overrides[module]) == nil then overrides[module] = nil end
    return true
end

function Theme:AddListener(listener)
    if type(listener) ~= "function" then return end
    self.listeners = self.listeners or {}
    table.insert(self.listeners, listener)
end

function Theme:Refresh()
    -- Only dispatch callbacks for our own appearance whitelist. A broad
    -- TriggerAllCallbacks() would re-run unrelated gameplay/config handlers.
    local selected = self:GetSelected()
    for module, properties in pairs(self.presets.fantasy) do
        for key in pairs(properties) do
            local raw = DFRL.tempDB[module] and DFRL.tempDB[module][key]
            DFRL:TriggerCallback(module .. "_" .. key .. "_changed",
                self:Resolve(module, key, raw))
        end
    end
    if DFRL.gui and DFRL.gui.Base and DFRL.gui.Base.SyncControls then
        DFRL.gui.Base.SyncControls()
    end
    if self.listeners then
        for i = 1, table.getn(self.listeners) do self.listeners[i](selected) end
    end
end

function Theme:UseExistingAppearance()
    if not self.state then return false end
    self.state.selected = nil
    self.state.needsChoice = false
    self:Refresh()
    return true
end

function Theme:Select(id)
    if not self.state or not self.presets[id] then return false end
    self.state.selected = id
    self.state.needsChoice = false
    self:Refresh()
    return true
end

local pendingReset
local function ConfirmReset()
    if not Theme.state or pendingReset ~= Theme:GetSelected() then return end
    local selected = pendingReset
    pendingReset = nil
    -- Only the selected theme's custom appearance values are deleted.
    Theme.state.overrides[selected] = {}
    Theme:Refresh()
end

StaticPopupDialogs["DFRL_THEME_RESET_CONFIRM"] = {
    text = "Restore the selected theme's default appearance?\n\nYour keybindings, profiles, frame positions and other theme customizations will not change.",
    button1 = YES,
    button2 = NO,
    OnAccept = ConfirmReset,
    OnCancel = function() pendingReset = nil end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

function Theme:RequestRestoreDefaults()
    local selected = self:GetSelected()
    if not selected then return false end
    pendingReset = selected
    if not StaticPopup_Show("DFRL_THEME_RESET_CONFIRM") then
        pendingReset = nil
        return false
    end
    return true
end
