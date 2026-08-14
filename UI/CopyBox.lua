--[[ UndermineLedger — reusable copyable text window.

WoW addons can't write the OS clipboard directly, so this selects the text
for the player instead (Ctrl+C) — same pattern as RaidNamesCopy's
CreateCopyFrame. Used for History and Debug output instead of dumping
either to the chat log.
]]

local ADDON, ns = ...
local UL = ns.UL

local frame

local function EnsureFrame()
	if frame then return frame end

	frame = CreateFrame("Frame", "UndermineLedgerCopyBox", UIParent, "DialogBoxFrame")
	frame:SetSize(420, 320)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:Hide()

	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.title:SetPoint("TOP", 0, -12)

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 0, 0)
	close:SetScript("OnClick", function() frame:Hide() end)

	local scroll = CreateFrame("ScrollFrame", "UndermineLedgerCopyBoxScroll", frame, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 16, -36)
	scroll:SetPoint("BOTTOMRIGHT", -34, 40)

	local edit = CreateFrame("EditBox", nil, scroll)
	edit:SetMultiLine(true)
	edit:SetFontObject(ChatFontNormal)
	edit:SetWidth(360)
	edit:SetAutoFocus(false)
	edit:SetScript("OnEscapePressed", function() frame:Hide() end)
	scroll:SetScrollChild(edit)
	frame.edit = edit

	local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	hint:SetPoint("BOTTOM", 0, 14)
	hint:SetText("Ctrl+C to copy, Esc to close")

	return frame
end

function UL:ShowCopyBox(title, text)
	local f = EnsureFrame()
	f.title:SetText(title)
	f.edit:SetText(text)
	f.edit:HighlightText()
	f.edit:SetFocus()
	f:Show()
end
