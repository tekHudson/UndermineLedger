--[[ UndermineLedger — reset-bucket math.

Dungeon bosses reset daily; raid bosses reset on their own saved-instance
lockout (weekly for SoD raids, but tied to the actual lockout, which can be
extended/reset early by a raid leader — not just "7 days from a fixed
hour"). Both use the same trick: store the *upcoming* reset's epoch as a
"bucket" at loot time, then compare against the current bucket. This is
robust across logins on different days without needing a fixed clock time.

`C_DateAndTime.GetSecondsUntilDailyReset`/`GetSecondsUntilWeeklyReset` are
retail-era additions and may not exist on the Classic/SoD client build —
calling a nil field errors out silently (mid-event, easy to miss without an
error-display addon) and was the likely cause of loot never recording.
Everything here goes through pcall with a Classic-verified fallback
(`GetQuestResetTime`, present since vanilla) so a missing API degrades
instead of breaking loot tracking outright.
]]

local ADDON, ns = ...

-- Bucket values are rounded down to the minute so two calls made a few
-- seconds apart (record time vs. display-refresh time) land on the same
-- bucket even if the underlying "seconds remaining" API is coarser than
-- one-second precision.
local BUCKET_GRANULARITY = 60
local function RoundBucket(epoch)
	return epoch - (epoch % BUCKET_GRANULARITY)
end

-- Server-time-of-day fallback if no reset API is available at all. Most SoD
-- US realms reset at 9am server time; adjust if this doesn't match yours.
local FALLBACK_DAILY_RESET_HOUR = 9

local function FallbackSecondsUntilDailyReset()
	local t = date("*t")
	local secondsToday = t.hour * 3600 + t.min * 60 + t.sec
	local untilReset = (FALLBACK_DAILY_RESET_HOUR * 3600) - secondsToday
	if untilReset <= 0 then untilReset = untilReset + 86400 end
	return untilReset
end

function ns.CurrentDailyBucket()
	if GetQuestResetTime then
		local ok, seconds = pcall(GetQuestResetTime)
		if ok and type(seconds) == "number" then
			return RoundBucket(time() + seconds)
		end
	end
	if C_DateAndTime and C_DateAndTime.GetSecondsUntilDailyReset then
		local ok, seconds = pcall(C_DateAndTime.GetSecondsUntilDailyReset)
		if ok and type(seconds) == "number" then
			return RoundBucket(time() + seconds)
		end
	end
	return RoundBucket(time() + FallbackSecondsUntilDailyReset())
end

function ns.CurrentWeeklyBucket()
	if C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset then
		local ok, seconds = pcall(C_DateAndTime.GetSecondsUntilWeeklyReset)
		if ok and type(seconds) == "number" then
			return RoundBucket(time() + seconds)
		end
	end
	-- Last-resort fallback: next Tuesday (US reset day) at the daily reset
	-- hour. EU realms reset Wednesday — adjust WEEKLY_RESET_WDAY if needed.
	local WEEKLY_RESET_WDAY = 3 -- Lua os.date wday: 1=Sunday .. 3=Tuesday
	local dailyBucket = time() + FallbackSecondsUntilDailyReset()
	local t = date("*t", dailyBucket)
	local daysUntil = (WEEKLY_RESET_WDAY - t.wday) % 7
	return RoundBucket(dailyBucket + daysUntil * 86400)
end

-- Prefer the actual saved-instance lockout for this raid's zone name, if the
-- character is currently saved to it (tracks real extends/early resets).
-- Falls back to the generic weekly bucket otherwise (e.g. not yet saved, or
-- checking the Ledger window from outside the raid).
function ns.CurrentRaidBucket(zoneName)
	if zoneName and GetNumSavedInstances then
		local ok, n = pcall(GetNumSavedInstances)
		if ok and n then
			for i = 1, n do
				-- Classic's GetSavedInstanceInfo signature: name, id, reset,
				-- difficulty, locked, extended, instanceIDMostSig, isRaid, ... —
				-- wrapped in pcall since this hasn't been verified in-game yet.
				local infOk, name, _, reset, _, locked, _, _, isRaid = pcall(GetSavedInstanceInfo, i)
				if infOk and isRaid and locked and name == zoneName and reset and reset > 0 then
					return RoundBucket(time() + reset)
				end
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
