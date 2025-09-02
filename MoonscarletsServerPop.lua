local f = CreateFrame("Frame", "WhoReportFrame", UIParent, "BasicFrameTemplateWithInset")
f:SetSize(360, 300)
f:SetPoint("CENTER")
f:Hide()
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:SetClampedToScreen(true)

f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
f.title:SetPoint("TOP", 0, -10)
f.title:SetText("MoonscarletsServerPop")

local function RunWho(zoneText, outputChannel, classFilter)
    local z = (zoneText and zoneText ~= "") and (" z-" .. zoneText) or ""
    local c = (classFilter and classFilter ~= "ALL") and (" c-" .. classFilter) or ""
    local A, H = 0, 0

    SendWho("r-human r-gnome r-dwarf r-elf" .. z .. c)
    C_Timer.After(1, function()
        local _, t = GetNumWhoResults()
        A = t
        SendWho("r-undead r-orc r-troll r-tauren" .. z .. c)
        C_Timer.After(1, function()
            local _, t = GetNumWhoResults()
            H = t
            local T = A + H
            local Ap = T > 0 and math.floor(A / T * 100) or 0
            local Hp = 100 - Ap
            local headerParts = {}
            if zoneText and zoneText ~= "" then table.insert(headerParts, "Zone: " .. zoneText) end
            if classFilter and classFilter ~= "ALL" then
                local cap = classFilter:sub(1,1):upper() .. classFilter:sub(2)
                table.insert(headerParts, "Class: " .. cap)
            end
            local header = table.concat(headerParts, " — ")

            local lines = {}
            if header ~= "" then table.insert(lines, header) end
            table.insert(lines, string.format("Alliance: %d (%d%%)", A, Ap))
            table.insert(lines, string.format("Horde: %d (%d%%)", H, Hp))
            table.insert(lines, string.format("Total: %d", T))

            if outputChannel == "LOCAL" then
                for _, L in ipairs(lines) do
                    print("|cff00ff00[MoonscarletsServerPop]|r " .. L)
                end
            elseif outputChannel == "PARTY" then
                if IsInGroup() then
                    for _, L in ipairs(lines) do
                        SendChatMessage(L, "PARTY")
                    end
                else
                    print("|cffff0000[MoonscarletsServerPop]|r Not in a party.")
                end
            elseif outputChannel == "SAY" then
                for _, L in ipairs(lines) do
                    SendChatMessage(L, "SAY")
                end
            end
        end)
    end)

    f:Hide()
end

-- Selection state
local selectedScope = "ZONE" -- "ZONE" or "TOTAL"
local selectedOutput = "LOCAL" -- "LOCAL", "PARTY", or "SAY"
local selectedClass = "ALL" -- "ALL" or class token (mage, warrior, etc.)
local selectedZoneText = "" -- user-entered zone text

-- UI: Scope Radios
local scopeLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
scopeLabel:SetPoint("TOPLEFT", 15, -35)
scopeLabel:SetText("Scope")

local scopeTotal = CreateFrame("CheckButton", nil, f, "UIRadioButtonTemplate")
scopeTotal:SetPoint("TOPLEFT", scopeLabel, "BOTTOMLEFT", 0, -6)
scopeTotal.value = "TOTAL"
local scopeTotalText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
scopeTotalText:SetPoint("LEFT", scopeTotal, "RIGHT", 4, 0)
scopeTotalText:SetText("Total")

local zoneLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
zoneLabel:SetPoint("LEFT", scopeTotalText, "RIGHT", 40, 0)
zoneLabel:SetText("Zone:")

local zoneInput = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
zoneInput:SetSize(160, 20)
zoneInput:SetAutoFocus(false)
zoneInput:SetPoint("LEFT", zoneLabel, "RIGHT", 6, 0)
zoneInput:SetText("")
zoneInput:SetScript("OnEditFocusGained", function()
    selectedScope = "ZONE"
    scopeTotal:SetChecked(false)
end)
zoneInput:SetScript("OnTextChanged", function()
    selectedScope = "ZONE"
    scopeTotal:SetChecked(false)
end)
zoneInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

local function SetScope(value)
    selectedScope = value
end
scopeTotal:SetScript("OnClick", function(self)
    scopeTotal:SetChecked(true)
    SetScope(self.value)
end)

-- UI: Output Radios
local outputLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
outputLabel:SetPoint("TOPLEFT", scopeZone, "BOTTOMLEFT", 0, -16)
outputLabel:SetText("Output")

local outLocal = CreateFrame("CheckButton", nil, f, "UIRadioButtonTemplate")
outLocal:SetPoint("TOPLEFT", outputLabel, "BOTTOMLEFT", 0, -6)
outLocal.value = "LOCAL"
local outLocalText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
outLocalText:SetPoint("LEFT", outLocal, "RIGHT", 4, 0)
outLocalText:SetText("Local")

local outParty = CreateFrame("CheckButton", nil, f, "UIRadioButtonTemplate")
outParty:SetPoint("LEFT", outLocalText, "RIGHT", 60, 0)
outParty.value = "PARTY"
local outPartyText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
outPartyText:SetPoint("LEFT", outParty, "RIGHT", 4, 0)
outPartyText:SetText("Party")

local outSay = CreateFrame("CheckButton", nil, f, "UIRadioButtonTemplate")
outSay:SetPoint("LEFT", outPartyText, "RIGHT", 60, 0)
outSay.value = "SAY"
local outSayText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
outSayText:SetPoint("LEFT", outSay, "RIGHT", 4, 0)
outSayText:SetText("Say")

local outputButtons = { outLocal, outParty, outSay }
local function SetOutput(value)
    selectedOutput = value
end
for _, b in ipairs(outputButtons) do
    b:SetScript("OnClick", function(self)
        for _, bb in ipairs(outputButtons) do bb:SetChecked(bb == self) end
        SetOutput(self.value)
    end)
end
for _, bb in ipairs(outputButtons) do bb:SetChecked(bb.value == selectedOutput) end

-- UI: Class Radios
local classLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
classLabel:SetPoint("TOPLEFT", outLocal, "BOTTOMLEFT", 0, -16)
classLabel:SetText("Class")

local classTokens = { "ALL", "priest", "warrior", "rogue", "hunter", "mage", "shaman", "paladin", "warlock", "druid" }
local classButtons = {}

local function capitalizeFirst(text)
    return text:sub(1,1):upper() .. text:sub(2)
end

local numCols = 3
local colSpacing = 110
local rowSpacing = 22
for index, token in ipairs(classTokens) do
    local btn = CreateFrame("CheckButton", nil, f, "UIRadioButtonTemplate")
    local zeroIndex = index - 1
    local col = zeroIndex % numCols
    local row = math.floor(zeroIndex / numCols)
    btn:SetPoint("TOPLEFT", classLabel, "BOTTOMLEFT", col * colSpacing, -6 - (row * rowSpacing))
    btn.value = token
    local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", btn, "RIGHT", 4, 0)
    label:SetText(token == "ALL" and "All" or capitalizeFirst(token))
    btn.text = label
    table.insert(classButtons, btn)
end

local function SetClass(value)
    selectedClass = value
end

for _, b in ipairs(classButtons) do
    b:SetScript("OnClick", function(self)
        for _, bb in ipairs(classButtons) do bb:SetChecked(bb == self) end
        SetClass(self.value)
    end)
end
for _, bb in ipairs(classButtons) do bb:SetChecked(bb.value == selectedClass) end

-- UI: Bottom Buttons
local goBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
goBtn:SetSize(100, 24)
goBtn:SetPoint("BOTTOMLEFT", 15, 12)
goBtn:SetText("Go")
goBtn:SetScript("OnClick", function()
    local zt = (selectedScope == "ZONE") and (zoneInput:GetText() or "") or ""
    RunWho(zt, selectedOutput, selectedClass)
end)

local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
cancelBtn:SetSize(100, 24)
cancelBtn:SetPoint("BOTTOMRIGHT", -15, 12)
cancelBtn:SetText("Cancel")
cancelBtn:SetScript("OnClick", function() f:Hide() end)

-- Slash command
SLASH_SERVERPOP1 = "/sp"
SlashCmdList["SERVERPOP"] = function()
    if zoneInput then
        zoneInput:SetText(GetZoneText() or "")
        selectedScope = "ZONE"
        scopeTotal:SetChecked(false)
    end
    f:Show()
end
