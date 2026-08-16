--[[ UndermineLedger — loot detection.

On LOOT_OPENED, scan the loot window for Tarnished Undermine Real (item id
226404, with a name-string fallback in case the id is ever wrong). If found,
the boss is whatever's currently targeted (SoD boss corpses are looted via
right-click while targeted, same assumption other loot-tracking addons
make). Records against the current instance-group if inside one; otherwise
checks the boss name against the OpenWorld roster (Azuregos, Kazzak, the
Dragons of Nightmare, etc.) so open-world uniques still get tracked.

Every run through LOOT_OPENED writes a step-by-step trace into
UL.lastLootTrace (overwritten each time, not printed anywhere) so a failed
loot can be diagnosed via the Debug button/window instead of guessing.
]]

local ADDON, ns = ...
local UL = ns.UL

local REAL_ITEM_ID = 226404
local REAL_ITEM_NAME = "Tarnished Undermine Real"

-- Tarnished Undermine Real may loot as a currency-type slot rather than a
-- regular item — currency links use the "currency:<id>" hyperlink format
-- instead of "item:<id>", which the id match needs to catch too. A blank
-- bracketed display name ("[]") on an otherwise-valid link is also a sign
-- the client hasn't cached that item/currency's name yet; matching on id
-- doesn't depend on the name being cached, so it still works either way.
local function IsRealLink(link)
	if not link then return false end
	local id = tonumber(link:match("item:(%d+)") or link:match("currency:(%d+)"))
	if id == REAL_ITEM_ID then return true end
	local name = GetItemInfo(link)
	return name == REAL_ITEM_NAME
end

local function ResolveOpenWorldBoss(bossName)
	for _, name in ipairs(ns.Instances.OpenWorld.bosses) do
		if name == bossName then return true end
	end
	return false
end

local function JoinValues(...)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[i] = tostring((select(i, ...)))
	end
	return table.concat(parts, ", ")
end

function UL:LOOT_OPENED()
	local trace = {}
	UL.lastLootTrace = trace
	local function log(...)
		trace[#trace + 1] = JoinValues(...)
	end

	log("LOOT_OPENED @", date("%H:%M:%S"))

	if not UL.char then
		log("ABORT: UL.char is nil (DB not initialized yet)")
		return
	end

	local numItems = GetNumLootItems and GetNumLootItems() or 0
	log("GetNumLootItems:", numItems)

	local foundLink
	for i = 1, numItems do
		local link = GetLootSlotLink and GetLootSlotLink(i)
		local infoText = GetLootSlotInfo and JoinValues(GetLootSlotInfo(i)) or "(no GetLootSlotInfo)"
		log("  slot", i, "info=[" .. infoText .. "]", "link=", link)
		if IsRealLink(link) then
			foundLink = link
		end
	end

	if not foundLink then
		log("ABORT: no Tarnished Undermine Real (id " .. REAL_ITEM_ID .. ") found in this loot window")
		return
	end
	log("MATCH: Real found -", foundLink)

	local targetExists = UnitExists("target")
	local bossName = targetExists and UnitName("target") or nil
	log("target exists:", targetExists, "target name:", bossName)
	if not bossName then
		log("ABORT: no current target to attribute the loot to")
		return
	end

	local groupKey = UL.currentGroup
	log("UL.currentGroup:", groupKey, "UL.currentZoneName:", UL.currentZoneName)
	if not groupKey and ResolveOpenWorldBoss(bossName) then
		groupKey = "OpenWorld"
		log("not in a tracked instance, but", bossName, "matched the OpenWorld roster")
	end
	if not groupKey then
		log("ABORT: not in a tracked instance and", bossName, "isn't a known open-world boss")
		return
	end

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

	log("RECORDED:", bossName, "in", groupKey, "bucket=", bucket, "count=", rec.count)

	if UL.RefreshBossList then UL:RefreshBossList() end
	if UL.RefreshLedger then UL:RefreshLedger() end
end
