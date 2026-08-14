--[[ UndermineLedger — bootstrap, shared namespace, event dispatch.

Tracks Tarnished Undermine Real boss loot (once per lockout period per
boss) across SoD dungeons and raids. See Core/Data.lua for the boss roster,
Core/Reset.lua for the daily-vs-weekly reset logic.
]]

local ADDON, ns = ...

local UL = {}
_G.UndermineLedger = UL
ns.UL = UL
ns.ADDON = ADDON

UL.version = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, "Version"))
	or GetAddOnMetadata(ADDON, "Version") or "0.0"

function UL:Print(...)
	print("|cff00ccff[UndermineLedger]|r", ...)
end

----------------------------------------------------------------------
-- Event dispatch: UL:RegisterEvent("X") -> calls UL:X(event, ...)
----------------------------------------------------------------------
local frame = CreateFrame("Frame", "UndermineLedgerEventFrame")
ns.eventFrame = frame
local registered = {}

function UL:RegisterEvent(event)
	if not registered[event] then
		registered[event] = true
		frame:RegisterEvent(event)
	end
end

function UL:UnregisterEvent(event)
	if registered[event] then
		registered[event] = nil
		frame:UnregisterEvent(event)
	end
end

frame:SetScript("OnEvent", function(_, event, ...)
	local handler = UL[event]
	if handler then
		handler(UL, event, ...)
	end
end)

----------------------------------------------------------------------
-- Bootstrap lifecycle
----------------------------------------------------------------------
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

function UL:ADDON_LOADED(_, name)
	if name ~= ADDON then return end
	UL:UnregisterEvent("ADDON_LOADED")
	UL:InitDB() -- Core/DB.lua
end

function UL:PLAYER_LOGIN()
	UL:InitUI() -- UI/Options.lua: minimap icon + options panel

	UL:RegisterEvent("PLAYER_ENTERING_WORLD")
	UL:RegisterEvent("LOOT_OPENED")

	UL:SetupSlash()
	UL:PLAYER_ENTERING_WORLD() -- catch already-in-instance-on-login

	UL:Print("v" .. UL.version .. " loaded. /ul for the ledger.")
end

----------------------------------------------------------------------
-- History / Debug — rendered into a copyable window (UI/CopyBox.lua),
-- never printed to chat. Called from Ledger buttons and the slash
-- commands below, so both paths land in the same place.
----------------------------------------------------------------------
function UL:BuildHistoryText()
	local history = UL.char and UL.char.history or {}
	if #history == 0 then
		return "No loot recorded yet."
	end
	local lines = {}
	for i = #history, 1, -1 do
		local e = history[i]
		lines[#lines + 1] = string.format("%s  %s  (%s)", date("%Y-%m-%d %H:%M", e.ts), e.boss, e.group)
	end
	return table.concat(lines, "\n")
end

function UL:ShowHistory()
	UL:ShowCopyBox("Loot History — " .. (UL.charKey or ""), UL:BuildHistoryText())
end

function UL:BuildDebugText()
	local lines = {
		"Zone: " .. (UL.currentZoneName or "(none)"),
		"Group: " .. (UL.currentGroup or "(none)"),
		"GetQuestResetTime: " .. (GetQuestResetTime and "present" or "MISSING"),
		"C_DateAndTime.GetSecondsUntilDailyReset: "
			.. ((C_DateAndTime and C_DateAndTime.GetSecondsUntilDailyReset) and "present" or "MISSING"),
		"Daily bucket: " .. tostring(ns.CurrentDailyBucket()),
	}
	if UL.currentGroup then
		local rec = UL.char and UL.char.loot[UL.currentGroup]
		lines[#lines + 1] = ""
		lines[#lines + 1] = "Loot state for " .. UL.currentGroup .. ":"
		if rec and next(rec) then
			for name, r in pairs(rec) do
				lines[#lines + 1] = string.format("  %s  count=%d  recordedBucket=%s", name, r.count, tostring(r.recordedBucket))
			end
		else
			lines[#lines + 1] = "  (none recorded yet)"
		end
	end
	return table.concat(lines, "\n")
end

function UL:ShowDebug()
	UL:ShowCopyBox("Debug Info", UL:BuildDebugText())
end

----------------------------------------------------------------------
-- Slash commands (everything here is also reachable via UI buttons —
-- see UI/Ledger.lua's History/Debug buttons and the minimap icon)
----------------------------------------------------------------------
function UL:SetupSlash()
	SLASH_UNDERMINELEDGER1 = "/undermineledger"
	SLASH_UNDERMINELEDGER2 = "/ul"
	_G.SlashCmdList["UNDERMINELEDGER"] = function(msg)
		msg = (msg or ""):lower():trim()
		if msg == "config" then
			UL:OpenOptions()
		elseif msg == "reset" then
			UL:ResetIconPosition()
		elseif msg == "history" then
			UL:ShowHistory()
		elseif msg == "debug" then
			UL:ShowDebug()
		else
			UL:ToggleLedger()
		end
	end
end
