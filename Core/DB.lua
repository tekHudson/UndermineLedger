--[[ UndermineLedger — saved variables with a tiny recursive defaults merge.

Same pattern as PallySquire/Core/DB.lua. `profile` holds UI/options state
(shared across characters); `chars[charKey]` holds the actual loot ledger,
since Tarnished Undermine Real is per-character, not account-bound.
]]

local ADDON, ns = ...
local UL = ns.UL

----------------------------------------------------------------------
-- Defaults
----------------------------------------------------------------------
local DEFAULTS = {
	minimap = { hide = false },
	pos = nil,   -- alert icon position
	locked = false,
}

local function applyDefaults(target, defaults)
	for k, v in pairs(defaults) do
		if type(v) == "table" then
			if type(target[k]) ~= "table" then target[k] = {} end
			applyDefaults(target[k], v)
		elseif target[k] == nil then
			target[k] = v
		end
	end
	return target
end
ns.applyDefaults = applyDefaults

local function CharKey()
	return UnitName("player") .. "-" .. GetRealmName()
end
ns.CharKey = CharKey

----------------------------------------------------------------------
-- Init (called from ADDON_LOADED)
----------------------------------------------------------------------
function UL:InitDB()
	UndermineLedgerDB = UndermineLedgerDB or {}
	UndermineLedgerDB.profile = applyDefaults(UndermineLedgerDB.profile or {}, DEFAULTS)
	UL.db = UndermineLedgerDB
	UL.opt = UndermineLedgerDB.profile

	UndermineLedgerDB.chars = UndermineLedgerDB.chars or {}
	local key = CharKey()
	local char = UndermineLedgerDB.chars[key] or {}
	char.loot = char.loot or {}
	char.learned = char.learned or {}
	char.history = char.history or {} -- append-only log; see UL:LogLoot
	UndermineLedgerDB.chars[key] = char
	UL.charKey = key
	UL.char = char
end

----------------------------------------------------------------------
-- History (append-only loot log): { ts, group, boss, zone }
----------------------------------------------------------------------
local MAX_HISTORY = 500

-- Records one loot event. Distinct from UL.char.loot[group][boss], which
-- holds current per-boss state (overwritten each loot) for the red/green
-- check — this is a dated trail of every individual loot, oldest first,
-- capped so SavedVariables doesn't grow unbounded over months of play.
function UL:LogLoot(groupKey, bossName)
	if not UL.char then return end
	local history = UL.char.history
	history[#history + 1] = {
		ts = time(),
		group = groupKey,
		boss = bossName,
		zone = UL.currentZoneName,
	}
	local overflow = #history - MAX_HISTORY
	if overflow > 0 then
		for i = 1, overflow do
			table.remove(history, 1)
		end
	end
end

----------------------------------------------------------------------
-- Boss roster accessors (seed data + self-learned, merged)
----------------------------------------------------------------------

-- Ordered, de-duplicated list of every known boss for a group: seed roster
-- from Data.lua followed by any self-learned additions for this character.
function ns.KnownBosses(groupKey)
	local info = ns.Instances[groupKey]
	if not info then return {} end

	local seen, list = {}, {}
	for _, name in ipairs(info.bosses) do
		if not seen[name] then
			seen[name] = true
			list[#list + 1] = name
		end
	end

	local learned = UL.char and UL.char.learned and UL.char.learned[groupKey]
	if learned then
		for name in pairs(learned) do
			if not seen[name] then
				seen[name] = true
				list[#list + 1] = name
			end
		end
	end
	return list
end

-- Record a boss not already in the seed roster as self-learned, persisted
-- per-character. Never mutates ns.Instances (the static seed data).
function UL:LearnBoss(groupKey, bossName)
	local info = ns.Instances[groupKey]
	if not info or not UL.char then return end
	for _, name in ipairs(info.bosses) do
		if name == bossName then return end -- already in the seed roster
	end
	UL.char.learned[groupKey] = UL.char.learned[groupKey] or {}
	UL.char.learned[groupKey][bossName] = true
end
