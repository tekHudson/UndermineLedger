--[[ UndermineLedger — zone-entry alert icon.

Shown whenever the player is inside a tracked dungeon/raid (Core/Zone.lua
decides when). Draggable, saved position, click toggles the boss-list
popup. Reuses the drag/save-position pattern from PallySquire/UI/Frame.lua.
]]

local ADDON, ns = ...
local UL = ns.UL

local icon

local function EnsureIcon()
	if icon then return icon end

	icon = CreateFrame("Button", "UndermineLedgerIcon", UIParent)
	icon:SetSize(32, 32)
	icon:SetClampedToScreen(true)
	icon:SetMovable(true)
	icon:EnableMouse(true)
	icon:RegisterForDrag("LeftButton")
	icon:SetFrameStrata("MEDIUM")

	-- Icon inset inward, border sized to fully enclose it — reversed before
	-- (icon filled the whole button, border inset outward), which let the
	-- round coin art bleed past the square ring.
	local tex = icon:CreateTexture(nil, "ARTWORK")
	tex:SetPoint("TOPLEFT", 3, -3)
	tex:SetPoint("BOTTOMRIGHT", -3, 3)
	tex:SetTexture(133799)
	icon.texture = tex

	local border = icon:CreateTexture(nil, "OVERLAY")
	border:SetAllPoints()
	border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
	icon.border = border

	if UL.opt.pos then
		local p = UL.opt.pos
		icon:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
	else
		icon:SetPoint("TOP", UIParent, "TOP", 0, -150)
	end

	icon:SetScript("OnDragStart", function(self)
		if not UL.opt.locked then self:StartMoving() end
	end)
	icon:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, relPoint, x, y = self:GetPoint()
		UL.opt.pos = { point = point, relPoint = relPoint, x = x, y = y }
	end)

	icon:SetScript("OnClick", function()
		UL:ToggleBossList()
	end)

	icon:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Tarnished Undermine Real")
		if UL.currentZoneName then
			GameTooltip:AddLine(UL.currentZoneName, 1, 1, 1)
		end
		GameTooltip:AddLine("Click for the boss list", 0.8, 0.8, 0.8)
		GameTooltip:Show()
	end)
	icon:SetScript("OnLeave", function() GameTooltip:Hide() end)

	return icon
end

function UL:ShowIcon(groupKey)
	EnsureIcon():Show()
end

function UL:HideIcon()
	if icon then icon:Hide() end
	UL:HideBossList()
end

function UL:ResetIconPosition()
	UL.opt.pos = nil
	local f = EnsureIcon()
	f:ClearAllPoints()
	f:SetPoint("TOP", UIParent, "TOP", 0, -150)
end
