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
	UndermineLedgerDB.chars[key] = UndermineLedgerDB.chars[key] or { loot = {}, learned = {} }
	UL.charKey = key
	UL.char = UndermineLedgerDB.chars[key]
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
