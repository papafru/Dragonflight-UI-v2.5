DFRL:NewDefaults("Frames", {
    enabled = {true},
})

DFRL:NewMod("Frames", 2, function()
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function()
        f:UnregisterEvent("PLAYER_ENTERING_WORLD")

        local framesToMakeMovable = {
            PlayerFrame,
            TargetFrame,
            TargetofTargetFrame,
            PartyMemberFrame1,
            PartyMemberFrame2,
            PartyMemberFrame3,
            PartyMemberFrame4,
            DFRL.mainBar,
            MultiBarBottomLeft,
            MultiBarBottomRight,
            MultiBarLeft,
            MultiBarRight,
            DFRL.newPetBar,
            DFRL.newShapeshiftBar,
            DFRL.xpBar,
            DFRL.repBar,
            DFRL.castbar,
            DFRL.targetCastbar,
            MainMenuBarBackpackButton,
            DFRL.microMenuContainer,
            DFRL.netStatsFrame,
            Minimap,
            DFRL.topPanel,
            DFRL.questframe,
            BuffButton0,
            BuffButton8,
            TempEnchant1,
            BuffButton16,
            BuffButton32,
            QuestTimerFrame,

            -- 3rd party
            DFRL.PWB_Panel,
        }

        local function SaveFramePosition(frame)
            local name = frame:GetName()
            if not name then return end

            local x, y = frame:GetLeft(), frame:GetTop()
            DFRL_FRAMEPOS[name] = {x = x, y = y}
        end

        local function RestoreFramePositions()
            if not DFRL_FRAMEPOS then return end
            for name, pos in pairs(DFRL_FRAMEPOS) do
                local frame = _G[name]
                if frame then
                    frame:ClearAllPoints()
                    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.x, pos.y)
                end
            end
        end

        -- A single controller replaces the old per-frame CTRL+SHIFT+ALT
        -- polling. The Game Menu integration lives in menu/editmode.lua.
        local Edit = DFRL.EditMode or {}
        DFRL.EditMode = Edit
        Edit.active = false
        Edit.ready = false
        Edit.overlays = {}
        Edit.dragging = {}
        Edit.restores = {}

        local grid = CreateFrame("Frame", "DFRLEditModeGrid", UIParent)
        grid:SetAllPoints(UIParent)
        grid:SetFrameStrata("BACKGROUND")
        grid:EnableMouse(false)
        grid:Hide()

        local width, height = GetScreenWidth(), GetScreenHeight()
        local ratio = width / height
        local hStep = (height * ratio) / 64
        local wStep = width / 64
        for i = 0, 64 do
            local line = grid:CreateTexture(nil, i == 32 and "BORDER" or "BACKGROUND")
            if i == 32 then line:SetTexture(.8, .6, 0) else line:SetTexture(0, 0, 0, .2) end
            line:SetPoint("TOPLEFT", grid, "TOPLEFT", i * wStep - .5, 0)
            line:SetPoint("BOTTOMRIGHT", grid, "BOTTOMLEFT", i * wStep + .5, 0)
        end
        for i = 1, floor(height / hStep) do
            local line = grid:CreateTexture(nil, i == floor(height / hStep / 2) and "BORDER" or "BACKGROUND")
            if i == floor(height / hStep / 2) then
                line:SetTexture(.8, .6, 0)
            else
                line:SetTexture(0, 0, 0, .2)
            end
            line:SetPoint("TOPLEFT", grid, "TOPLEFT", 0, -i * hStep + .5)
            line:SetPoint("BOTTOMRIGHT", grid, "TOPRIGHT", 0, -i * hStep - .5)
        end

        local function CanShowOverlay(entry)
            if not entry.frame:IsVisible() then return false end
            if entry.frame == DFRL.targetCastbar and DFRL:GetTempDB("TargetCastbar", "enemyCastbarAutoPosition") then
                return false
            end
            return true
        end

        -- The Escape menu clears the active target in the stock client.
        -- Edit Mode must offer movable placeholders even when neither target
        -- exists. Reassert visibility because FrameXML can hide the frames
        -- after a target-change event; never change the actual unit selection.
        function Edit:RefreshPreviewFrames()
            for i = 1, table.getn(self.restores) do
                local state = self.restores[i]
                if state.unit and state.frame and not state.frame:IsShown() then
                    state.frame:Show()
                end
            end
        end

        function Edit:RefreshOverlays()
            if not self.active then return end
            self:RefreshPreviewFrames()
            for i = 1, table.getn(self.overlays) do
                local entry = self.overlays[i]
                if CanShowOverlay(entry) then
                    entry.overlay:Show()
                else
                    entry.overlay:Hide()
                end
            end
        end

        local ticker = CreateFrame("Frame")
        ticker:Hide()
        ticker.elapsed = 0
        ticker:SetScript("OnUpdate", function()
            this.elapsed = this.elapsed + (arg1 or 0)
            if this.elapsed < 0.1 then return end
            this.elapsed = 0
            Edit:RefreshOverlays()
        end)

        local function TemporarilyShow(frame, unit)
            if not frame then return end
            table.insert(Edit.restores, {
                frame = frame,
                shown = frame:IsShown(),
                unit = unit,
                unitExisted = unit and UnitExists(unit) or nil,
            })
            frame:Show()
        end

        function Edit:Start()
            if self.active then return true end
            if not self.ready then return false end
            if DFRL.hoverbind and DFRL.hoverbind.active then DFRL.hoverbind:Stop() end
            self.active = true
            DFRL.activeScripts["FrameControlScript"] = true
            self.restores = {}
            -- Target must be shown before Target of Target, since the legacy
            -- client may anchor or parent the second frame to the first.
            TemporarilyShow(TargetFrame, "target")
            TemporarilyShow(TargetofTargetFrame, "targettarget")
            TemporarilyShow(DFRL.castbar)
            if DFRL.castbar then TemporarilyShow(DFRL.castbar.bar) end
            if DFRL.castbar and DFRL.castbar.bar then DFRL.castbar.bar:Hide() end
            if DFRL.targetCastbar and not DFRL:GetTempDB("TargetCastbar", "enemyCastbarAutoPosition") then
                TemporarilyShow(DFRL.targetCastbar)
            end
            TemporarilyShow(FramerateLabel)
            TemporarilyShow(DFRL.netStatsFrame)
            grid:Show()
            ticker.elapsed = 0
            ticker:Show()
            self:RefreshOverlays()
            if self.onStart then self.onStart() end
            return true
        end

        function Edit:Stop()
            if not self.active then return end
            self.active = false
            ticker:Hide()
            for i = 1, table.getn(self.overlays) do
                self.overlays[i].overlay:Hide()
            end
            -- ESC can be pressed during a drag, before the mouse-up event.
            for frame in pairs(self.dragging) do
                frame:StopMovingOrSizing()
                SaveFramePosition(frame)
            end
            self.dragging = {}
            grid:Hide()
            for i = table.getn(self.restores), 1, -1 do
                local state = self.restores[i]
                local show = state.shown
                if state.unit then
                    local existsNow = UnitExists(state.unit)
                    -- If targeting changed during Edit Mode, respect the
                    -- actual current unit rather than a stale entry state.
                    if existsNow ~= state.unitExisted then show = existsNow end
                end
                if show then state.frame:Show() else state.frame:Hide() end
            end
            self.restores = {}
            DFRL.activeScripts["FrameControlScript"] = false
            if self.onStop then self.onStop() end
        end

        function Edit:IsActive()
            return self.active
        end

        -- Position data is stored per character in the dedicated
        -- DFRL_FRAMEPOS SavedVariable. Reset all of it: restoring positions
        -- iterates this entire table, including previously registered frames.
        -- A reload rebuilds stock/addon anchors reliably in dependency order.
        function Edit:RestoreDefaultPositions()
            if not self.ready or not self.active then return false end

            -- Stop first: Stop() saves any frame still being dragged.
            -- Clearing the positions afterward prevents them being restored.
            self:Stop()
            if type(DFRL_FRAMEPOS) ~= "table" then
                DFRL_FRAMEPOS = {}
            else
                for name in pairs(DFRL_FRAMEPOS) do
                    DFRL_FRAMEPOS[name] = nil
                end
            end

            ReloadUI()
            return true
        end

        local function MakeFrameMovable(frame)
            if not frame then return end
            frame:EnableMouse(true)
            frame:SetMovable(true)

            local overlay = CreateFrame("Frame", nil, frame)
            overlay:SetPoint("TOPLEFT", frame, "TOPLEFT", -10, 10)
            overlay:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 10, -10)
            overlay:SetFrameStrata("TOOLTIP")
            overlay:SetFrameLevel(100)
            overlay:SetToplevel(true)
            overlay:EnableMouse(true)
            overlay:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 32, edgeSize = 16,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })
            overlay:SetBackdropColor(1, .82, 0, .5)
            overlay:SetBackdropBorderColor(1, .82, 0, 1)
            overlay:Hide()

            overlay:SetScript("OnMouseDown", function()
                if not Edit.active then return end
                Edit.dragging[frame] = true
                frame:StartMoving()
            end)
            overlay:SetScript("OnMouseUp", function()
                if not Edit.dragging[frame] then return end
                frame:StopMovingOrSizing()
                Edit.dragging[frame] = nil
                if frame == MultiBarBottomLeft or frame == MultiBarBottomRight then
                    DFRL:SetTempDBNoCallback("actionbars", "movable", false)
                end
                SaveFramePosition(frame)
            end)

            local function CreateDirectionButton(dir, xOffset, yOffset, text)
                local button = CreateFrame("Button", nil, overlay, "UIPanelButtonTemplate")
                button:SetWidth(14)
                button:SetHeight(14)
                button:SetPoint(dir, overlay, dir, 0, 0)
                button:SetText(text)
                button:GetNormalTexture():SetVertexColor(0, 0, 0)
                button:GetHighlightTexture():SetVertexColor(.3, .3, .3)
                button:GetPushedTexture():SetVertexColor(.2, .2, .2)
                button:SetScript("OnClick", function()
                    if not Edit.active then return end
                    -- Read the coordinates BEFORE clearing anchors.
                    local x, y = frame:GetLeft() + xOffset, frame:GetTop() + yOffset
                    frame:ClearAllPoints()
                    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
                    SaveFramePosition(frame)
                end)
            end
            CreateDirectionButton("TOP", 0, 1, "U")
            CreateDirectionButton("LEFT", -1, 0, "L")
            CreateDirectionButton("RIGHT", 1, 0, "R")
            CreateDirectionButton("BOTTOM", 0, -1, "D")

            -- Direct frame dragging is also guarded by Edit Mode; the old
            -- CTRL+SHIFT+ALT hotkey no longer activates anything.
            frame:SetScript("OnDragStart", function()
                if Edit.active then
                    Edit.dragging[frame] = true
                    frame:StartMoving()
                end
            end)
            frame:SetScript("OnDragStop", function()
                if not Edit.dragging[frame] then return end
                frame:StopMovingOrSizing()
                Edit.dragging[frame] = nil
                SaveFramePosition(frame)
            end)
            table.insert(Edit.overlays, {frame = frame, overlay = overlay})
        end

        -- make frames from list movable
        for i = 1, table.getn(framesToMakeMovable) do
            if framesToMakeMovable[i] then
                MakeFrameMovable(framesToMakeMovable[i])
            end
        end

        -- init
        RestoreFramePositions()
        Edit.ready = true
    end)

    DFRL.activeScripts["FrameControlScript"] = false
end)
