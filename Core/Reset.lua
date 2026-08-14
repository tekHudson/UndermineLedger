--[[ UndermineLedger — reset-bucket math.

Dungeon bosses reset daily; raid bosses reset on their own saved-instance
lockout (weekly for SoD raids, but tied to the actual lockout, which can be
extended/reset early by a raid leader — not just "7 days from a fixed
hour"). Both use the same trick: store the *upcoming* reset's epoch as a
"bucket" at loot time, then compare against the current bucket. This is
robust across logins on different days without needing a fixed clock time.
]]

local ADDON, ns = ...

function ns.CurrentDailyBucket()
	return time() + C_DateAndTime.GetSecondsUntilDailyReset()
end

function ns.CurrentWeeklyBucket()
	return time() + C_DateAndTime.GetSecondsUntilWeeklyReset()
end

-- Prefer the actual saved-instance lockout for this raid's zone name, if the
-- character is currently saved to it (tracks real extends/early resets).
-- Falls back to the generic weekly bucket otherwise (e.g. not yet saved, or
-- checking the Ledger window from outside the raid).
function ns.CurrentRaidBucket(zoneName)
	if zoneName and GetNumSavedInstances then
		local n = GetNumSavedInstances()
		for i = 1, n do
			-- Classic's GetSavedInstanceInfo signature: name, id, reset, difficulty,
			-- locked, extended, instanceIDMostSig, isRaid, ... — verify in-game;
			-- only the fields used below are relied on.
			local name, _, reset, _, locked, _, _, isRaid = GetSavedInstanceInfo(i)
			if isRaid and locked and name == zoneName and reset and reset > 0 then
				return time() + reset
			end
		end
	end
	return ns.CurrentWeeklyBucket()
end

-- Bucket to compare a loot record against for the given instance-group.
function ns.CurrentBucket(groupKey)
	local info = ns.Instances[groupKey]
	if not info then return ns.CurrentDailyBucket() end
	if info.type == "raid" then
		return ns.CurrentRaidBucket(info.zoneNames and info.zoneNames[1])
	end
	return ns.CurrentDailyBucket()
end
