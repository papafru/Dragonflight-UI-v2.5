-- fruUI: Edit Mode entry point and lightweight Retail-inspired toolbar.
-- Keep the menu integration separate from its native menu implementation.
-- Frame movement/persistence remains in modules/frames/frames.lua.

-- Called by Menu once its frames/buttons exist. This must NOT register an
-- additional NewMod: the original Modules settings grid only fits 24 toggles
-- and an extra entry leaves its last (Xprep) checkbox orphaned on UIParent.
DFRL.InitEditModeMenu = function()
    if DFRL.editModeMenuInitialized then return end
    local Edit = DFRL.EditMode or {active = false, ready = false}
    DFRL.EditMode = Edit
    local menu = DFRL.menuframe
    local menuButtons = DFRL.menuButtons
    if not menu or not menuButtons or not menuButtons.keybindings then return end

    local keyButton = menuButtons.keybindings
    local editButton = DFRL.tools.CreateButton(menu, "Edit Mode", 120, 30)
    editButton:SetScript("OnClick", function()
        if not Edit.ready then return end
        menu:Hide()
        Edit:Start()
    end)

    -- Respect whichever anchor Key Bindings currently has. Addons may insert
    -- arbitrary numbers of buttons in this chain; we always insert just
    -- BEFORE Key Bindings without moving or reparenting their frames.
    local function PlaceEditButton()
        local point, relative, relativePoint, x, y = keyButton:GetPoint(1)
        if relative == editButton then return end
        if not point or not relative then return end
        editButton:ClearAllPoints()
        editButton:SetPoint(point, relative, relativePoint, x, y)
        keyButton:ClearAllPoints()
        keyButton:SetPoint("TOP", editButton, "BOTTOM", 0, 0)
    end

    -- The original Escape menu has a fixed height. Grow it to cover every
    -- visible direct child button, including buttons contributed by addons.
    -- Do not shrink below the original height, or reset addon-owned anchors.
    local originalHeight = menu:GetHeight()
    local lastOwnedHeight
    local function FitMenuHeight()
        if not menu:IsShown() then return end
        local currentHeight = menu:GetHeight()
        if lastOwnedHeight and math.abs(currentHeight - lastOwnedHeight) > 1 then
            -- A third-party addon changed the menu's requested height.
            originalHeight = math.max(originalHeight, currentHeight)
        end
        local menuTop = menu:GetTop()
        if not menuTop then return end
        local children = { menu:GetChildren() }
        local lowestBottom
        for i = 1, table.getn(children) do
            local child = children[i]
            if child:GetObjectType() == "Button" and child:IsShown() then
                local bottom = child:GetBottom()
                if bottom and (not lowestBottom or bottom < lowestBottom) then
                    lowestBottom = bottom
                end
            end
        end
        if not lowestBottom then return end
        local requiredHeight = math.ceil(menuTop - lowestBottom + 15)
        local targetHeight = math.max(originalHeight, requiredHeight)
        if math.abs(currentHeight - targetHeight) > 1 then
            menu:SetHeight(targetHeight)
            lastOwnedHeight = targetHeight
        end
    end

    local oldOnShow = menu:GetScript("OnShow")
    menu:SetScript("OnShow", function()
        if oldOnShow then oldOnShow() end
        PlaceEditButton()
        FitMenuHeight()
    end)

    local layoutWatcher = CreateFrame("Frame", nil, menu)
    layoutWatcher.elapsed = 0
    layoutWatcher:SetScript("OnUpdate", function()
        this.elapsed = this.elapsed + (arg1 or 0)
        if this.elapsed < .15 then return end
        this.elapsed = 0
        PlaceEditButton()
        FitMenuHeight()
    end)
    PlaceEditButton()

    -- Compact control strip: a mode title, a discreet Esc hint, and access to
    -- the existing /kb capture mode. The HUD remains visible while editing.
    local panel = CreateFrame("Frame", "DFRLEditModeToolbar", UIParent)
    panel:SetWidth(382)
    panel:SetHeight(58)
    panel:SetPoint("TOP", UIParent, "TOP", 0, -20)
    panel:SetFrameStrata("TOOLTIP")
    panel:SetFrameLevel(200)
    panel:EnableMouse(true)
    panel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = {left = 3, right = 3, top = 3, bottom = 3},
    })
    panel:SetBackdropColor(.02, .035, .055, .9)
    panel:SetBackdropBorderColor(.72, .58, .29, .95)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 13, -9)
    title:SetText("EDIT MODE")
    title:SetTextColor(1, .82, .28)

    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 13, 10)
    hint:SetText("Drag frames to move   |   ESC to exit")

    local keybindButton = DFRL.tools.CreateButton(panel, "Mouseover Keybinds", 132, 28)
    keybindButton:SetPoint("RIGHT", panel, "RIGHT", -9, 0)
    keybindButton:SetScript("OnClick", function()
        -- These modes must never be active at the same time: overlays conflict.
        Edit:Stop()
        if DFRL.hoverbind then DFRL.hoverbind:Start() end
    end)
    panel:Hide()

    Edit.onStart = function() panel:Show() end
    Edit.onStop = function() panel:Hide() end

    -- In 1.12/1.18 the ESC binding invokes ToggleGameMenu. Consume it while
    -- editing instead of opening the menu, clearing targets or closing windows.
    local originalToggle = ToggleGameMenu
    _G.ToggleGameMenu = function()
        if Edit:IsActive() then
            Edit:Stop()
            return
        end
        return originalToggle()
    end
    DFRL.editModeMenuInitialized = true
end
