-- Integration/regression suite for fruUI theme foundation.
-- Run: lua5.1 tests/theme_foundation.lua (or texlua tests/theme_foundation.lua)
if not getfenv then getfenv = function() return _G end end
if not setfenv then setfenv = function() end end
if not table.getn then table.getn = function(t) return #t end end
if not tinsert then tinsert = table.insert end

local report = print
local checks = 0
local function assertEqual(actual, expected, message)
    checks = checks + 1
    if actual ~= expected then error(message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual)) end
end
local function assertTrue(value, message) assertEqual(not not value, true, message) end

local frames = {}
function CreateFrame()
    local f = {events = {}, scripts = {}}
    function f:RegisterEvent(e) self.events[e] = true end
    function f:SetScript(eventName, fn) self.scripts[eventName] = fn end
    frames[table.getn(frames) + 1] = f
    return f
end
UIParent = {}
DEFAULT_CHAT_FRAME = {AddMessage = function() end}
StaticPopupDialogs = {}
YES, NO = "Yes", "No"
local shownPopup
function StaticPopup_Show(name)
    shownPopup = name
    return {which = name}
end
function UnitName() return "TestCharacter" end
function IsAddOnLoaded() return false end
function ReloadUI() end
function GetTime() return 0 end
function gcinfo() return 0 end
function geterrorhandler() return function(e) error(e) end end

local root = ""
if arg and arg[0] then root = string.match(arg[0], "^(.*[/\\])tests[/\\]") or "" end
local function loadSource(path)
    local chunk, err = loadfile(root .. path)
    if not chunk then error(err) end
    chunk()
end
loadSource("core/core.lua")
loadSource("core/theme.lua")

local keys = {
    Bars = {enabled = {true}, barsDarkMode = {0}, barsColor = {{1, 1, 1}}, highlightColor = {{1, .82, 0}}, showGryphoon = {true}, mainBarScale = {1}},
    Player = {enabled = {true}, playerDarkMode = {0}, playerColor = {{1, 1, 1}}},
    Cast = {enabled = {true}, castDarkMode = {0}, castColor = {{.9, .9, .9}}},
    Generic = {enabled = {true}, combatAlerts = {true}},
}
for name, value in pairs(keys) do DFRL:NewDefaults(name, value) end
local function start(profile, isReturning, state)
    DFRL.tempDB = {}
    DFRL_DB_SETUP = {version = DFRL.DBversion}
    DFRL_CUR_PROFILE = {TestCharacter = "Default"}
    if isReturning then DFRL_CUR_PROFILE.TestCharacter_firstRun = true end
    DFRL_PROFILES = {Default = profile or {}}
    DFRL_THEME_STATE = state
    DFRL:InitTempDB()
    DFRL.theme:Initialize()
end

-- Fresh player: choice is pending; without a selected theme the profile wins.
start(nil, false, nil)
assertTrue(DFRL.theme:NeedsFirstRunChoice(), "new user requires theme choice")
assertEqual(DFRL.theme:GetSelected(), nil, "new installation is neutral")
assertEqual(DFRL:GetTempDB("Bars", "barsDarkMode"), 0, "neutral default appearance")
assertEqual(DFRL.theme:RequestRestoreDefaults(), false, "cannot reset with no theme")

-- Returning character with old config: no surprise recoloring or new prompt.
local legacy = {Bars = {enabled = true, barsDarkMode = .4, mainBarScale = 1.33}, Generic = {enabled = false, combatAlerts = false}}
start(legacy, true, nil)
assertEqual(DFRL.theme:GetSelected(), nil, "existing appearance preserved")
assertEqual(DFRL.theme:NeedsFirstRunChoice(), false, "existing user not prompted")
assertEqual(DFRL:GetTempDB("Bars", "barsDarkMode"), .4, "legacy dark mode intact")
assertEqual(DFRL:GetTempDB("Bars", "mainBarScale"), 1.33, "non theme scale intact")

-- Selecting modern provides only virtual appearance overrides.
assertTrue(DFRL.theme:Select("modern"), "modern selectable")
assertEqual(DFRL:GetTempDB("Bars", "barsDarkMode"), .85, "modern dark mode")
assertEqual(DFRL:GetTempDB("Bars", "showGryphoon"), false, "modern hides ornaments")
assertEqual(DFRL:GetTempDB("Bars", "mainBarScale"), 1.33, "theme never changes scale")
assertEqual(DFRL:GetTempDB("Generic", "combatAlerts"), false, "non-theme option intact")
assertEqual(DFRL.tempDB.Bars.barsDarkMode, .4, "raw profile setting is untouched")
assertEqual(DFRL.tempDB.Generic.enabled, false, "enabled setting intact")

-- All application paths, including initial callbacks, see themed values.
local callback, calls = nil, 0
DFRL:NewCallbacks("Bars", {barsDarkMode = function(v) callback = v; calls = calls + 1 end})
assertEqual(callback, .85, "new callback initially sees themed value")
DFRL:SetTempDB("Bars", "barsDarkMode", .6)
assertEqual(callback, .6, "appearance callback sees custom override")
assertEqual(DFRL.tempDB.Bars.barsDarkMode, .4, "appearance edit not stored in profile")
assertEqual(DFRL:GetTempDB("Bars", "barsDarkMode"), .6, "override persists in theme state")
DFRL:TriggerAllCallbacks()
assertEqual(callback, .6, "refresh callbacks resolve theme")
DFRL:SetTempDBNoCallback("Bars", "barsDarkMode", .5)
assertEqual(DFRL:GetTempDB("Bars", "barsDarkMode"), .5, "silent setter routes appearance")
assertEqual(DFRL.tempDB.Bars.barsDarkMode, .4, "silent setter leaves profile alone")
DFRL:SetTempDB("Bars", "mainBarScale", 1.45)
assertEqual(DFRL:GetTempDB("Bars", "mainBarScale"), 1.45, "non-appearance setter unchanged")

-- Color tables are defensive copies in both directions.
local picked = {.1, .2, .3}
DFRL:SetTempDB("Bars", "barsColor", picked)
picked[1] = .99
assertEqual(DFRL:GetTempDB("Bars", "barsColor")[1], .1, "saved color copied")
local got = DFRL:GetTempDB("Bars", "barsColor")
got[1] = .66
assertEqual(DFRL:GetTempDB("Bars", "barsColor")[1], .1, "resolved color copied")
DFRL:SetTempDB("Bars", "barsDarkMode", "invalid")
assertEqual(DFRL:GetTempDB("Bars", "barsDarkMode"), .5, "invalid themed value rejected")
DFRL:SetTempDB("Bars", "barsColor", {1, -1, 0})
assertEqual(DFRL:GetTempDB("Bars", "barsColor")[2], .2, "invalid themed color rejected")

-- Theme-specific customizations do not bleed to other themes.
assertTrue(DFRL.theme:Select("fantasy"), "fantasy selectable")
assertEqual(DFRL:GetTempDB("Bars", "barsDarkMode"), 0, "fantasy default on first select")
DFRL:SetTempDB("Bars", "barsDarkMode", .22)
assertTrue(DFRL.theme:Select("modern"), "modern reselectable")
assertEqual(DFRL:GetTempDB("Bars", "barsDarkMode"), .5, "modern customization restored")
DFRL:SaveTempDB()
assertEqual(DFRL_PROFILES.Default.Bars.barsDarkMode, .4, "save preserves profile's appearance")
assertEqual(DFRL_PROFILES.Default.Bars.mainBarScale, 1.45, "save preserves normal configuration changes")

-- Reset: cancel does nothing; accept clears only CURRENT theme's overrides.
assertTrue(DFRL.theme:RequestRestoreDefaults(), "reset confirmation available")
assertEqual(shownPopup, "DFRL_THEME_RESET_CONFIRM", "native confirmation requested")
StaticPopupDialogs.DFRL_THEME_RESET_CONFIRM.OnCancel()
assertEqual(DFRL:GetTempDB("Bars", "barsDarkMode"), .5, "cancel preserves override")
assertTrue(DFRL.theme:RequestRestoreDefaults(), "confirmation can reopen")
StaticPopupDialogs.DFRL_THEME_RESET_CONFIRM.OnAccept()
assertEqual(DFRL:GetTempDB("Bars", "barsDarkMode"), .85, "confirmed reset restores selected preset")
assertEqual(DFRL:GetTempDB("Bars", "barsColor")[1], .76, "confirmed reset restores theme palette")
assertEqual(DFRL.tempDB.Bars.barsDarkMode, .4, "reset does not alter profile")
assertTrue(DFRL.theme:Select("fantasy"), "other theme after reset")
assertEqual(DFRL:GetTempDB("Bars", "barsDarkMode"), .22, "other theme override preserved")

-- Returning with saved theme selections: persisted state is respected.
local savedTheme = DFRL_THEME_STATE
start(legacy, true, savedTheme)
assertEqual(DFRL.theme:GetSelected(), "fantasy", "theme persists after simulated reload")
assertEqual(DFRL:GetTempDB("Bars", "barsDarkMode"), .22, "override persists after simulated reload")
assertEqual(DFRL:GetTempDB("Generic", "combatAlerts"), false, "unrelated option survives reload")

-- Invalid theme/state: safe fallback, never writes through to a profile.
start(legacy, true, {schema = 1, selected = "unknown", overrides = {modern = "bad"}})
assertEqual(DFRL.theme:GetSelected(), nil, "invalid selected theme becomes neutral")
assertEqual(DFRL:GetTempDB("Bars", "barsDarkMode"), .4, "invalid state preserves profile")
assertTrue(DFRL.theme:Select("modern"), "repaired state can select theme")
assertEqual(DFRL:GetTempDB("Bars", "barsDarkMode"), .85, "corrupt modern overrides repaired")

-- No interference with the existing module registry/grid.
assertEqual(DFRL.modules.Theme, nil, "no theme NewMod registration")
assertEqual(DFRL.modules.ThemeManager, nil, "no extra Settings toggle")
report("PASS theme foundation: " .. checks .. " assertions")
