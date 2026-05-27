local addon = cfQuestXP
local K = addon.KEYS
local F = addon.GUI

function addon.InitSettings()
	local panel = CreateFrame("Frame", "cfQuestXPSettingsPanel")
	panel.name = "cfQuestXP"
	panel:Hide()

	local title = F.Title(panel, "cfQuestXP")

	F.Checkbox(panel, title, "Show completed quest XP overlay", K.ENABLED, {
		onEnable = addon.EnableQuestXP,
		onDisable = addon.DisableQuestXP,
	})

	panel:SetScript("OnShow", F.MakeSettingsPanelDraggable)

	local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name, panel.name)
	Settings.RegisterAddOnCategory(category)
end
