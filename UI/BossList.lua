--[[ UndermineLedger — boss-list popup.

Shown when the alert icon is clicked. Lists every known boss (seed +
self-learned) for the current instance-group: green if looted this reset
period, red otherwise. Frame chrome follows PallySquire/UI/Frame.lua's
BackdropTemplate + drag pattern.
]]

local ADDON, ns = ...
local UL = ns.UL

local BACKDROP = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 14,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local frame
local rows = {}

local function EnsureFrame()
	if frame then return frame end

	frame = CreateFrame("Frame", "UndermineLedgerBossListFrame", UIParent, "BackdropTemplate")
	frame:SetSize(240, 60)
	frame:SetPoint("CENTER")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetBackdrop(BACKDROP)
	frame:SetBackdropColor(0, 0, 0, 0.85)
	frame:SetFrameStrata("DIALOG")
	frame:Hide()

	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.title:SetPoint("TOP", 0, -10)

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 0, 0)
	close:SetScript("OnClick", function() frame:Hide() end)

	return frame
end

local function EnsureRow(i)
	local f = EnsureFrame()
	local row = rows[i]
	if not row then
		row = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		row:SetPoint("TOPLEFT", 16, -30 - (i - 1) * 16)
		row:SetJustifyH("LEFT")
		rows[i] = row
	end
	return row
end

function UL:RefreshBossList()
	if not frame or not frame:IsShown() then return end

	local groupKey = UL.currentGroup
	if not groupKey then
		frame:Hide()
		return
	end

	frame.title:SetText(UL.currentZoneName or groupKey)

	local bosses = ns.KnownBosses(groupKey)
	local bucket = ns.CurrentBucket(groupKey)
	local lootRec = (UL.char and UL.char.loot[groupKey]) or {}

	for i, name in ipairs(bosses) do
		local row = EnsureRow(i)
		local rec = lootRec[name]
		local looted = rec and rec.recordedBucket == bucket
		if looted then
			row:SetText("|cff00ff00" .. name .. "|r")
		else
			row:SetText("|cffff4040" .. name .. "|r")
		end
		row:Show()
	end
	for i = #bosses + 1, #rows do
		rows[i]:Hide()
	end

	frame:SetHeight(40 + math.max(#bosses, 1) * 16)
end

function UL:ToggleBossList()
	local f = EnsureFrame()
	if f:IsShown() then
		f:Hide()
	else
		f:Show()
		UL:RefreshBossList()
	end
end

function UL:HideBossList()
	if frame then frame:Hide() end
end
