-- cfQuestXP: overlays the XP from completed-but-unturned quests onto the experience bar,
-- tinted with the "difficult" quest color, sitting just behind the real XP fill.

local overlay
local difficultColor = QuestDifficultyColors["difficult"]
local fillLayer, fillSublevel  -- the XP-bar fill's draw layer, captured once at load (see below)

local function CreateOverlay()
    overlay = CreateFrame("StatusBar", nil, MainMenuExpBar)
    overlay:SetAllPoints(MainMenuExpBar)
    overlay:SetFrameLevel(MainMenuExpBar:GetFrameLevel())  -- equal level pairs with sublevel-1 to sit behind the fill
    overlay:Hide()
end

-- Match the XP bar's texture, pin our fill one sublevel behind the real fill, re-apply the tint
-- (SetStatusBarTexture clears both the color and the draw layer, so both must follow every time).
-- Use the layer captured at load, NOT a fresh read: this hook fires mid-way through cfFrames'
-- SetStatusBarTexture -- after the swap resets the fill to its default (ARTWORK) but before
-- cfFrames restores the real BACKGROUND layer -- so a read here returns ARTWORK and the overlay
-- jumps above the real fill and bleeds over the bar.
local function SyncTexture()
    overlay:SetStatusBarTexture(MainMenuExpBar:GetStatusBarTexture():GetTexture())
    overlay:GetStatusBarTexture():SetDrawLayer(fillLayer, fillSublevel - 1)
    overlay:SetStatusBarColor(difficultColor.r, difficultColor.g, difficultColor.b)
end

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

CreateOverlay()
-- Capture the fill's real draw layer once, while it's settled (BACKGROUND); reading it inside
-- the texture hook is unreliable (see SyncTexture).
fillLayer, fillSublevel = MainMenuExpBar:GetStatusBarTexture():GetDrawLayer()
SyncTexture()
hooksecurefunc(MainMenuExpBar, "SetStatusBarTexture", SyncTexture)

overlay:SetScript("OnEvent", UpdateOverlay)
overlay:RegisterEvent("QUEST_LOG_UPDATE")
overlay:RegisterEvent("PLAYER_XP_UPDATE")
overlay:RegisterEvent("PLAYER_LEVEL_UP")
