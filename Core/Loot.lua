--[[ UndermineLedger — loot detection.

On LOOT_OPENED, scan the loot window for Tarnished Undermine Real (item id
226404, with a name-string fallback in case the id is ever wrong). If found,
the boss is whatever's currently targeted (SoD boss corpses are looted via
right-click while targeted, same assumption other loot-tracking addons
make). Records against the current instance-group if inside one; otherwise
checks the boss name against the OpenWorld roster (Azuregos, Kazzak, the
Dragons of Nightmare, etc.) so open-world uniques still get tracked.
]]

local ADDON, ns = ...
local UL = ns.UL

local REAL_ITEM_ID = 226404
local REAL_ITEM_NAME = "Tarnished Undermine Real"

local function IsRealLink(link)
	if not link then return false end
	local id = tonumber(link:match("item:(%d+)"))
	if id == REAL_ITEM_ID then return true end
	local name = GetItemInfo(link)
	return name == REAL_ITEM_NAME
end

local function LootContainsReal()
	local numItems = GetNumLootItems and GetNumLootItems() or 0
	for i = 1, numItems do
		if IsRealLink(GetLootSlotLink(i)) then
			return true
		end
	end
	return false
end

local function ResolveOpenWorldBoss(bossName)
	for _, name in ipairs(ns.Instances.OpenWorld.bosses) do
		if name == bossName then return true end
	end
	return false
end

function UL:LOOT_OPENED()
	if not UL.char then return end
	if not LootContainsReal() then return end

	local bossName = UnitExists("target") and UnitName("target") or nil
	if not bossName then return end

	local groupKey = UL.currentGroup
	if not groupKey and ResolveOpenWorldBoss(bossName) then
		groupKey = "OpenWorld"
	end
	if not groupKey then return end

	if groupKey ~= "OpenWorld" then
		UL:LearnBoss(groupKey, bossName)
	end

	local bucket = ns.CurrentBucket(groupKey)
	UL.char.loot[groupKey] = UL.char.loot[groupKey] or {}
	local rec = UL.char.loot[groupKey][bossName] or { count = 0 }
	rec.recordedBucket = bucket
	rec.count = rec.count + 1
	rec.lastLoot = time()
	UL.char.loot[groupKey][bossName] = rec
	UL:LogLoot(groupKey, bossName)

	if UL.RefreshBossList then UL:RefreshBossList() end
	if UL.RefreshLedger then UL:RefreshLedger() end
end
