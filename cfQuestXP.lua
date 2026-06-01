-- cfQuestXP: shows the XP from completed-but-unturned quests as a "ghost" segment on the experience
-- bar -- the gap just past your current XP -- tinted with the "difficult" quest color.

local overlay
local difficultColor = QuestDifficultyColors["difficult"]

-- The overlay is a texture on MainMenuExpBar ITSELF, in the EXACT slot the real fill occupies
-- (BACKGROUND, sublevel -1), so it inherits everything the blue fill has: the same chrome draws over
-- it (framed, no spill over the bottom edge) and it renders at the same brightness. It spans ONLY the
-- gap past current XP, so it never overlaps the fill -- the only other texture at this slot -- which
-- means no shared-sublevel draw-order race.
--
-- (Other slots failed: above the fill it sat over the bottom edge and spilled; at sublevel -2 it tied
-- with another bar texture and the undefined draw order made it render dark or light at random.)
local function CreateOverlay()
    overlay = MainMenuExpBar:CreateTexture(nil, "BACKGROUND", nil, -1)
    overlay:Hide()
end

-- Match the bar's current texture (cfFrames or another retexturer may swap it live), re-tint, and
-- reposition (SetTexture resets texcoord, so the slice must be re-applied via UpdateOverlay).
local function GetCompletedQuestXP()
    local previousSelection = GetQuestLogSelection()
    local completedQuestXP = 0
    for questIndex = 1, GetNumQuestLogEntries() do
        local _, _, _, isHeader, _, isComplete = GetQuestLogTitle(questIndex)
        if not isHeader then
            SelectQuestLogEntry(questIndex)
            if isComplete == 1 or GetNumQuestLeaderBoards() == 0 then  -- 1 = complete; -1 = failed
                completedQuestXP = completedQuestXP + GetQuestLogRewardXP()
            end
        end
    end
    SelectQuestLogEntry(previousSelection)
    return completedQuestXP
end

local function UpdateOverlay()
    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    if maxXP == 0 then overlay:Hide() return end
    local completedQuestXP = GetCompletedQuestXP()
    if completedQuestXP == 0 then overlay:Hide() return end

    -- Span only the gap between current XP and the projected total, so it never overlaps the fill.
    -- Anchor to the fill texture's right edge (not the frame) so it inherits the fill's exact start
    -- and inset height -- anchoring to the frame made it full-height and spilled over the bottom edge.
    local fillTexture = MainMenuExpBar:GetStatusBarTexture()
    local barWidth = MainMenuExpBar:GetWidth()
    local startFraction = currentXP / maxXP
    local endFraction = math.min(currentXP + completedQuestXP, maxXP) / maxXP

    overlay:ClearAllPoints()
    overlay:SetPoint("TOPLEFT", fillTexture, "TOPRIGHT", 0, 0)
    overlay:SetPoint("BOTTOMLEFT", fillTexture, "BOTTOMRIGHT", 0, 0)
    overlay:SetWidth(math.max(1, (endFraction - startFraction) * barWidth))
    overlay:SetTexCoord(startFraction, endFraction, 0, 1)
    overlay:Show()
end

local function SyncTexture()
    overlay:SetTexture(MainMenuExpBar:GetStatusBarTexture():GetTexture())
    overlay:SetVertexColor(difficultColor.r, difficultColor.g, difficultColor.b)
    UpdateOverlay()
end

CreateOverlay()
SyncTexture()
hooksecurefunc(MainMenuExpBar, "SetStatusBarTexture", SyncTexture)

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", UpdateOverlay)
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("PLAYER_XP_UPDATE")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
