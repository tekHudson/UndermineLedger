--[[ UndermineLedger — instance-group data: which bosses drop Tarnished
Undermine Real, grouped by dungeon/raid, plus the zone-name -> group-key
lookup used to detect what instance the player just entered.

Boss rosters here are confirmed data (positionally derived from Tek's own
source lists), not a guess — see the plan doc for how they were derived.
Self-learning (Core/Loot.lua) still adds any newly-seen boss on top of
this at runtime, as a safety net for future SoD phases.

`zoneNames` must match the exact string GetInstanceInfo() returns for that
zone in-game (case/apostrophe-sensitive) — verify these the first time each
instance is entered; a mismatch just means the popup icon won't show for
that instance until corrected, loot tracking elsewhere is unaffected.
]]

local ADDON, ns = ...

ns.Instances = {
	-- BRD is non-linear (multiple arenas branching off a central vault), so
	-- there's no single "true" order — this follows a common full-clear route.
	BRD = { type = "dungeon", zoneNames = { "Blackrock Depths" }, bosses = {
		"Lord Incendius", "Bael'Gar", "Fineous Darkvire", "Phalanx",
		"Golem Lord Argelmach", "General Angerforge", "Ambassador Flamelash",
		"Hurley Blackbreath", "Magmus", "Emperor Dagran Thaurissan",
	} },
	-- LBRS then UBRS (this addon merges them into one group per Tek).
	BRS = { type = "dungeon", zoneNames = { "Lower Blackrock Spire", "Upper Blackrock Spire" }, bosses = {
		"Highlord Omokk", "Shadow Hunter Vosh'gajin", "War Master Voone",
		"Mother Smolderweb", "Urok Doomhowl", "Gizrul the Slavener",
		"Overlord Wyrmthalak", "Pyroguard Emberseer", "Halycon", "The Beast",
		"Warchief Rend Blackhand", "General Drakkisath",
	} },
	Scholomance = { type = "dungeon", zoneNames = { "Scholomance" }, bosses = {
		"Kirtonos the Herald", "Jandice Barov", "Rattlegore", "Marduk Blackpool",
		"Vectus", "Instructor Malicia", "The Ravenian", "Doctor Theolen Krastinov",
		"Lord Alexei Barov", "Lady Illucia Barov", "Lorekeeper Polkelt",
		"Lord Blackwood", "Ras Frostwhisper", "Darkmaster Gandling",
	} },
	-- Living side, then Undead side, Baron Rivendare last.
	Stratholme = { type = "dungeon", zoneNames = { "Stratholme" }, bosses = {
		"Timmy the Cruel", "Postmaster Malown", "Ezra Grimm", "Cannon Master Willey",
		"Ramstein the Gorger", "Magistrate Barthilas", "Grand Crusader Dathrohan",
		"Baroness Anastari", "Nerub'enkan", "Maleki the Pallid",
		"Archivist Galford", "The Unforgiven", "Balzaphon", "Malor the Zealous",
		"Baron Rivendare",
	} },
	-- Three separate wings (West/North/East) — order across wings is
	-- arbitrary since they don't chain into each other; order within each
	-- wing follows the real route.
	DireMaul = { type = "dungeon", zoneNames = { "Dire Maul" }, bosses = {
		"Zevrim Thornhoof", "Tendris Warpwood", "Hydrospawn", "Alzzin the Wildshaper",
		"Pusillin", "King Gordok",
		"Magister Kalendris", "Lethtendris", "Illyanna Ravenoak", "Immol'thar",
		"Prince Tortheldrin", "Revanchion",
	} },
	-- New Phase 8 zone — I don't have reliable encounter-order knowledge for
	-- this one, so it's left as-given (data order) until confirmed.
	DemonFallCanyon = { type = "dungeon", zoneNames = { "Demon Fall Canyon" }, bosses = {
		"Hellscream's Phantom", "Diathorus the Seeker", "Azgaloth", "Pyranis",
		"Grimroot", "The Destructor's Wraith", "Zilbagob",
	} },
	-- New Phase 7 zone — same caveat as Demon Fall Canyon, order unconfirmed.
	KarazhanCrypts = { type = "dungeon", zoneNames = { "Karazhan Crypts" }, bosses = {
		"Harbinger of Sin", "Creeping Malison", "Dark Rider", "Barian Maryla",
		"Kharon", "Kaigy Maryla", "Sairuh Maryla",
	} },
	MoltenCore = { type = "raid", zoneNames = { "Molten Core" }, bosses = {
		"Lucifron", "Magmadar", "Gehennas", "Garr", "Baron Geddon", "Shazzrah",
		"Golemagg the Incinerator", "Sulfuron Harbinger", "Ragnaros",
	} },
	BlackwingLair = { type = "raid", zoneNames = { "Blackwing Lair" }, bosses = {
		"Razorgore the Untamed", "Vaelastrasz the Corrupt", "Broodlord Lashlayer",
		"Firemaw", "Ebonroc", "Flamegor", "Chromaggus", "Nefarian",
	} },
	-- Optional animal bosses first (commonly killed early), then the 5
	-- Priests via the gong, then Mandokir/Gahz'ranka/Jin'do, Hakkar last.
	ZulGurub = { type = "raid", zoneNames = { "Zul'Gurub" }, bosses = {
		"Renataki", "Wushoolay", "Gri'lek", "Hazza'rah",
		"High Priestess Jeklik", "High Priest Venoxis", "High Priestess Mar'li",
		"High Priest Thekal", "High Priestess Arlokk", "Bloodlord Mandokir",
		"Gahz'ranka", "Jin'do the Hexxer", "Hakkar",
	} },
	AQ20 = { type = "raid", zoneNames = { "Ruins of Ahn'Qiraj" }, bosses = {
		"Kurinnaxx", "General Rajaxx", "Moam", "Buru the Gorger",
		"Ayamiss the Hunter", "Ossirian the Unscarred",
	} },
	-- Bug Trio (any 2 of 3) after Skeram, then Sartura/Fankriss/Viscidus/
	-- Huhuran, Twin Emperors together, Ouro (optional), C'Thun last.
	AQ40 = { type = "raid", zoneNames = { "Temple of Ahn'Qiraj" }, bosses = {
		"The Prophet Skeram", "Princess Yauj", "Vem", "Lord Kri",
		"Battleguard Sartura", "Fankriss the Unyielding", "Viscidus",
		"Princess Huhuran", "Emperor Vek'nilash", "Emperor Vek'lor", "Ouro",
		"C'Thun",
	} },
	Onyxia = { type = "raid", zoneNames = { "Onyxia's Lair" }, bosses = { "Onyxia" } },
	-- Open-world uniques: no zoneNames (they aren't instances, no popup icon),
	-- tracked passively and shown only in the Ledger window.
	OpenWorld = { type = "world", bosses = {
		"Azuregos", "Lord Kazzak", "Prince Thunderaan", "Taerar", "Emeriss",
		"Lethon", "Ysondre",
	} },
}

-- Display order for the Ledger window.
ns.GroupOrder = {
	"BRD", "BRS", "Scholomance", "Stratholme", "DireMaul", "DemonFallCanyon",
	"KarazhanCrypts", "MoltenCore", "BlackwingLair", "ZulGurub", "AQ20", "AQ40",
	"Onyxia", "OpenWorld",
}

-- zoneName (as returned by GetInstanceInfo()) -> group key.
ns.ZoneToGroup = {}
for key, info in pairs(ns.Instances) do
	for _, zoneName in ipairs(info.zoneNames or {}) do
		ns.ZoneToGroup[zoneName] = key
	end
end
