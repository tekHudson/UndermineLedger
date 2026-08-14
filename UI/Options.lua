--[[ UndermineLedger — minimap icon + options panel.

Minimap icon/LDB pattern copied from EasyMount/UI/Options.lua. Options
panel uses the modern Settings API with a legacy fallback, same as
PallySquire/UI/Options.lua — no Ace3 config tables.
]]

local ADDON, ns = ...
local UL = ns.UL

function UL:InitUI()
	local LDB = LibStub("LibDataBroker-1.1", true)
	local LDBIcon = LibStub("LibDBIcon-1.0", true)

	if LDB then
		local ldbObject = LDB:NewDataObject(ADDON, {
			type = "data source",
			text = "UndermineLedger",
			icon = "Interface\\Icons\\INV_Misc_Coin_02",
			OnClick = function() UL:ToggleLedger() end,
			OnTooltipShow = function(tooltip)
				tooltip:AddLine("UndermineLedger")
				tooltip:AddLine("Click to open the Ledger", 1, 1, 1)
			end,
		})
		if LDBIcon then
			LDBIcon:Register(ADDON, ldbObject, UL.opt.minimap)
		end
	end

	UL:CreateOptionsPanel()
end

function UL:CreateOptionsPanel()
	local panel = CreateFrame("Frame", "UndermineLedgerOptionsPanel", UIParent)
	panel.name = "UndermineLedger"

	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("UndermineLedger")

	local minimapCheck = CreateFrame("CheckButton", "UndermineLedgerMinimapCheck", panel, "InterfaceOptionsCheckButtonTemplate")
	minimapCheck:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
	minimapCheck.Text:SetText("Show minimap icon")
	minimapCheck:SetScript("OnClick", function(self)
		UL.opt.minimap.hide = not self:GetChecked()
		local LDBIcon = LibStub("LibDBIcon-1.0", true)
		if LDBIcon then
			if UL.opt.minimap.hide then
				LDBIcon:Hide(ADDON)
			else
				LDBIcon:Show(ADDON)
			end
		end
	end)

	panel:SetScript("OnShow", function()
		minimapCheck:SetChecked(not UL.opt.minimap.hide)
	end)

	if Settings and Settings.RegisterCanvasLayoutCategory then
		local category = Settings.RegisterCanvasLayoutCategory(panel, "UndermineLedger")
		Settings.RegisterAddOnCategory(category)
		UL.optionsCategory = category
	elseif InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(panel)
	end
	UL.optionsPanel = panel
end

function UL:OpenOptions()
	if Settings and Settings.OpenToCategory and UL.optionsCategory then
		Settings.OpenToCategory(UL.optionsCategory:GetID())
	elseif InterfaceOptionsFrame_OpenToCategory then
		InterfaceOptionsFrame_OpenToCategory(UL.optionsPanel)
		InterfaceOptionsFrame_OpenToCategory(UL.optionsPanel)
	end
end
