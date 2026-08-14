--[[ UndermineLedger — Ledger summary window.

Opened via the minimap icon or `/ul`. Unlike the BossList popup (current
instance only), this iterates every instance-group with a scrollable list,
red/green per boss, plus a running total for the period.
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
local lines = {}

local function EnsureFrame()
	if frame then return frame end

	frame = CreateFrame("Frame", "UndermineLedgerFrame", UIParent, "BackdropTemplate")
	frame:SetSize(300, 420)
	frame:SetPoint("CENTER")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetBackdrop(BACKDROP)
	frame:SetBackdropColor(0, 0, 0, 0.9)
	frame:SetFrameStrata("DIALOG")
	frame:Hide()

	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	frame.title:SetPoint("TOP", 0, -12)
	frame.title:SetText("Undermine Ledger")

	frame.total = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.total:SetPoint("TOP", frame.title, "BOTTOM", 0, -6)

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 0, 0)
	close:SetScript("OnClick", function() frame:Hide() end)

	local historyBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	historyBtn:SetSize(80, 20)
	historyBtn:SetPoint("TOPLEFT", 12, -40)
	historyBtn:SetText("History")
	historyBtn:SetScript("OnClick", function() UL:ShowHistory() end)

	local debugBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	debugBtn:SetSize(80, 20)
	debugBtn:SetPoint("LEFT", historyBtn, "RIGHT", 6, 0)
	debugBtn:SetText("Debug")
	debugBtn:SetScript("OnClick", function() UL:ShowDebug() end)

	local scroll = CreateFrame("ScrollFrame", "UndermineLedgerScroll", frame, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 12, -66)
	scroll:SetPoint("BOTTOMRIGHT", -30, 12)

	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(1, 1)
	scroll:SetScrollChild(content)
	frame.content = content

	return frame
end

local function EnsureLine(i)
	local f = EnsureFrame()
	local line = lines[i]
	if not line then
		line = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		line:SetPoint("TOPLEFT", 4, -(i - 1) * 16)
		line:SetJustifyH("LEFT")
		lines[i] = line
	end
	return line
end

function UL:RefreshLedger()
	if not frame or not frame:IsShown() then return end

	local i = 0
	local totalLooted, totalKnown = 0, 0

	for _, groupKey in ipairs(ns.GroupOrder) do
		local info = ns.Instances[groupKey]
		local bosses = ns.KnownBosses(groupKey)
		if info and #bosses > 0 then
			i = i + 1
			local header = EnsureLine(i)
			header:SetText("|cffffd100" .. groupKey .. "|r")
			header:Show()

			local bucket = ns.CurrentBucket(groupKey)
			local lootRec = (UL.char and UL.char.loot[groupKey]) or {}

			for _, name in ipairs(bosses) do
				i = i + 1
				local line = EnsureLine(i)
				local rec = lootRec[name]
				local looted = rec and rec.recordedBucket == bucket
				totalKnown = totalKnown + 1
				if looted then
					totalLooted = totalLooted + 1
					line:SetText("  |cff00ff00" .. name .. "|r")
				else
					line:SetText("  |cffff4040" .. name .. "|r")
				end
				line:Show()
			end
		end
	end

	for j = i + 1, #lines do
		lines[j]:Hide()
	end

	frame.content:SetHeight(math.max(i, 1) * 16 + 10)
	frame.total:SetText(string.format("%d / %d looted this period", totalLooted, totalKnown))
end

function UL:ToggleLedger()
	local f = EnsureFrame()
	if f:IsShown() then
		f:Hide()
	else
		f:Show()
		UL:RefreshLedger()
	end
end
