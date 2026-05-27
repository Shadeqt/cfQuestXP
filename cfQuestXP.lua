-- cfQuestXP: overlays the XP from completed-but-unturned quests onto the experience bar,
-- tinted with the "difficult" quest color, sitting just behind the real XP fill.

local overlay

-- Sum XP from quests that are complete (or have no objectives) but not yet turned in.
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
    overlay:SetMinMaxValues(0, maxXP)
    overlay:SetValue(currentXP + math.min(completedQuestXP, maxXP - currentXP))
    overlay:Show()
end

-- Mirror the XP bar's own texture and draw layer, one sublevel behind so the real fill wins.
local function SyncTexture()
    local barTexture = MainMenuExpBar:GetStatusBarTexture()
    overlay:SetStatusBarTexture(barTexture:GetTexture())
    local drawLayer, sublevel = barTexture:GetDrawLayer()
    overlay:GetStatusBarTexture():SetDrawLayer(drawLayer, sublevel - 1)
end

overlay = CreateFrame("StatusBar", nil, MainMenuExpBar)
overlay:SetAllPoints(MainMenuExpBar)
overlay:SetFrameLevel(MainMenuExpBar:GetFrameLevel())  -- equal level pairs with sublevel-1 to sit behind the fill
local difficultColor = QuestDifficultyColors["difficult"]
overlay:SetStatusBarColor(difficultColor.r, difficultColor.g, difficultColor.b)
overlay:Hide()

-- texture: match the bar now, and keep matching it when anything repaints it
SyncTexture()
hooksecurefunc(MainMenuExpBar, "SetStatusBarTexture", SyncTexture)

-- events last
overlay:SetScript("OnEvent", UpdateOverlay)
overlay:RegisterEvent("QUEST_LOG_UPDATE")
overlay:RegisterEvent("PLAYER_XP_UPDATE")
overlay:RegisterEvent("PLAYER_LEVEL_UP")
