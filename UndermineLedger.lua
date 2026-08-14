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
-- Slash commands
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
		else
			UL:ToggleLedger()
		end
	end
end
