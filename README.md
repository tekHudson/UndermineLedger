# UndermineLedger

A World of Warcraft Classic (Season of Discovery) addon that tracks
**Tarnished Undermine Real** boss loot.

Tarnished Undermine Real can be looted once per lockout period per boss.
Dungeon bosses reset daily; raid bosses reset on their own instance
lockout (weekly, unless extended/reset early). UndermineLedger shows a
small icon when you enter a qualifying dungeon or raid — click it for a
red/green list of that instance's bosses (red = not yet looted this
period, green = already looted). Click the minimap icon to open the
Ledger window, which summarizes everything you've looted across every
tracked instance (not just the one you're standing in), and has
**History** and **Debug** buttons that open a copyable text window
(select-all + Ctrl+C, same pattern as RaidNamesCopy) — nothing prints to
chat.

## Commands

Everything below is also reachable by clicking: the alert icon opens the
boss list, the minimap icon opens the Ledger, and the Ledger has History/
Debug buttons. The slash commands are just shortcuts to the same windows.

- `/ul` — toggle the Ledger window
- `/ul config` — open options
- `/ul reset` — reset the alert icon's position
- `/ul history` — open the copyable loot-history window
- `/ul debug` — open the copyable debug-info window (current zone/group,
  which reset API is present, raw loot state for the current instance)

## Notes

- Loot tracking is per-character (the currency itself isn't account bound).
- A dated history log (character, boss, zone, timestamp) is kept alongside
  the current per-boss red/green state — History button (or `/ul history`)
  to view it. Capped at the last 500 events per character.
- The boss roster is self-learning: any boss seen dropping a Real that
  isn't already known gets added automatically and remembered, so future
  SoD phases that add bosses don't require an addon update to be tracked.
- Azuregos, Lord Kazzak, Prince Thunderaan, and the four Dragons of
  Nightmare (Taerar, Emeriss, Lethon, Ysondre) are open-world uniques, not
  instances — they're tracked passively and shown only in the Ledger
  window, not via the zone-entry popup.
