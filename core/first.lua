setfenv(1, DFRL:GetEnv())

local Setup = {
    patchConfig = {
        width = 400,
        height = 210,
        timerDuration = 10,
        barWidth = 200,
        barHeight = 3,
        title = "|cFFFF0000Important Patch Warning|r",
        text = "Patch 2.0.11 implemented the pvp icon natively.\n\nDo not place the 'TargetingFrame' folder into\nyour WoW/Interface/ dir anymore.\nDeactivate module for Blizzard default.",
        additionalText = "",
        version = "2.0.11",
    },

}

function Setup:PatchWarning()
    local patchFrame = CreateFrame("Frame", "DFRL_WelcomeFrame", UIParent)
    patchFrame:SetWidth(self.patchConfig.width)
    patchFrame:SetHeight(self.patchConfig.height)
    patchFrame:SetPoint("TOP", 0, -5)
    patchFrame:SetBackdrop{ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}
    patchFrame:EnableMouse(true)

    T.GradientLine(patchFrame, "TOP", -0)
    T.GradientLine(patchFrame, "BOTTOM", 0)

    local title = DFRL.tools.CreateFont(patchFrame, 18, self.patchConfig.title)
    title:SetPoint("TOP", 0, -20)

    local fullText = self.patchConfig.text
    if self.patchConfig.additionalText ~= "" then
        fullText = fullText .. "\n\n|cFFFF0000" .. self.patchConfig.additionalText .. "|r"
    end

    local text = DFRL.tools.CreateFont(patchFrame, 15, fullText)
    text:SetPoint("TOP", title, "BOTTOM", 0, -16)
    text:SetWidth(380)

    local okBtn = DFRL.tools.CreateButton(patchFrame, "Okay", 120, 24)
    okBtn:SetPoint("BOTTOM", 0, 20)
    okBtn:Disable()

    okBtn:SetScript("OnClick", function()
        patchFrame:Hide()
        DFRL:SetTempDBNoCallback("Generic", "patchWarnVersion", self.patchConfig.version)
    end)

    local barWidth = self.patchConfig.barWidth
    local barHeight = self.patchConfig.barHeight
    local timerBar = patchFrame:CreateTexture(nil, "OVERLAY")
    timerBar:SetTexture("Interface\\Buttons\\WHITE8x8")
    timerBar:SetVertexColor(1, 0.82, 0)
    timerBar:SetPoint("BOTTOM", okBtn, "TOP", 0, 10)
    timerBar:SetWidth(barWidth)
    timerBar:SetHeight(barHeight)

    local elapsed = 0
    patchFrame:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed >= self.patchConfig.timerDuration then
            okBtn:Enable()
            timerBar:Hide()
            patchFrame:SetScript("OnUpdate", nil)
            DFRL.activeScripts["PatchWarningScript"] = false
        else
            timerBar:SetWidth(barWidth * (1 - elapsed / self.patchConfig.timerDuration))
            DFRL.activeScripts["PatchWarningScript"] = true
        end
    end)
end

DFRL.activeScripts["WelcomePageScript"] = false
DFRL.activeScripts["PatchWarningScript"] = false

-- The theme selector replaces the old Light/Dark page. Existing installations
-- are neutral and do not receive an unsolicited first-run popup.
local f = CreateFrame("Frame")
f:RegisterEvent("VARIABLES_LOADED")
f:SetScript("OnEvent", function()
    f:UnregisterEvent("VARIABLES_LOADED")
    if DFRL.theme and DFRL.theme:NeedsFirstRunChoice() and DFRL.ShowThemeWelcome then
        DFRL.ShowThemeWelcome()
    end
end)
