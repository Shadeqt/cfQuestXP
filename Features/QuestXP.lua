local addon = cfQuestXP

local overlay
local enabled
local inited

local function GetCompletedQuestXP()
	local savedSelection = GetQuestLogSelection()
	local totalXP = 0
	for i = 1, GetNumQuestLogEntries() do
		local _, _, _, isHeader, _, isComplete = GetQuestLogTitle(i)
		if not isHeader then
			SelectQuestLogEntry(i)
			if isComplete or GetNumQuestLeaderBoards() == 0 then
				totalXP = totalXP + (GetQuestLogRewardXP() or 0)
			end
		end
	end
	SelectQuestLogEntry(savedSelection)
	return totalXP
end

local function UpdateOverlay()
	if not enabled then
		if overlay then overlay:Hide() end
		return
	end
	local bar = MainMenuExpBar
	if not bar or not overlay then return end

	local currentXP = UnitXP("player")
	local maxXP = UnitXPMax("player")
	if maxXP == 0 then overlay:Hide() return end

	local questXP = GetCompletedQuestXP()
	if questXP == 0 then overlay:Hide() return end

	local cappedQuestXP = math.min(questXP, maxXP - currentXP)
	overlay:SetMinMaxValues(0, maxXP)
	overlay:SetValue(currentXP + cappedQuestXP)
	overlay:Show()
end

local function GetBarTexture()
	return PlayerFrameHealthBar:GetStatusBarTexture():GetTexture()
end

local function SetBarTexture(bar, texture)
	local tex = bar:GetStatusBarTexture()
	local layer, sublevel
	if tex then layer, sublevel = tex:GetDrawLayer() end
	bar:SetStatusBarTexture(texture)
	if layer then bar:GetStatusBarTexture():SetDrawLayer(layer, sublevel or 0) end
end

local function ApplyBarTexture(texture)
	if MainMenuExpBar then SetBarTexture(MainMenuExpBar, texture) end
	if overlay then SetBarTexture(overlay, texture); overlay:GetStatusBarTexture():SetDrawLayer("BACKGROUND", -1) end
	if ExhaustionLevelFillBar then ExhaustionLevelFillBar:SetTexture(texture) end
	if ReputationWatchBar and ReputationWatchBar.StatusBar then SetBarTexture(ReputationWatchBar.StatusBar, texture) end
end

local function InitQuestXP()
	if inited then return end
	local bar = MainMenuExpBar
	if not bar then return end
	inited = true

	local texture = GetBarTexture()
	ApplyBarTexture(texture)

	overlay = CreateFrame("StatusBar", nil, bar)
	overlay:SetAllPoints(bar)
	overlay:SetStatusBarTexture(texture)
	overlay:GetStatusBarTexture():SetDrawLayer("BACKGROUND", -1)
	local c = QuestDifficultyColors["difficult"]
	overlay:SetStatusBarColor(c.r, c.g, c.b)
	overlay:SetMinMaxValues(0, 1)
	overlay:SetValue(0)
	overlay:SetFrameLevel(bar:GetFrameLevel())
	overlay:Hide()

	overlay:SetScript("OnEvent", UpdateOverlay)
	overlay:RegisterEvent("QUEST_LOG_UPDATE")
	overlay:RegisterEvent("PLAYER_XP_UPDATE")
	overlay:RegisterEvent("PLAYER_LEVEL_UP")

	hooksecurefunc(PlayerFrameHealthBar, "SetStatusBarTexture", function(_, tex)
		if not enabled then return end
		ApplyBarTexture(tex)
	end)
end

function addon.EnableQuestXP()
	if enabled then return end
	InitQuestXP()
	enabled = true
	UpdateOverlay()
end

function addon.DisableQuestXP()
	if not enabled then return end
	enabled = false
	if overlay then overlay:Hide() end
end
