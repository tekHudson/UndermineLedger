--[[ UndermineLedger — zone-entry detection.

Resolves the current zone against the instance-group table and shows/hides
the alert icon accordingly. Lower/Upper Blackrock Spire both resolve to the
single "BRS" group via Data.lua's zoneNames list.
]]

local ADDON, ns = ...
local UL = ns.UL

-- Returns groupKey (or nil), zoneName, instanceType.
local function ResolveGroup()
	local name, instanceType = GetInstanceInfo()
	if instanceType ~= "party" and instanceType ~= "raid" then
		return nil, name, instanceType
	end
	return ns.ZoneToGroup[name], name, instanceType
end
ns.ResolveGroup = ResolveGroup

function UL:PLAYER_ENTERING_WORLD()
	local groupKey, zoneName = ResolveGroup()
	UL.currentGroup = groupKey
	UL.currentZoneName = zoneName

	if groupKey then
		UL:ShowIcon(groupKey)
	else
		UL:HideIcon()
	end
end
