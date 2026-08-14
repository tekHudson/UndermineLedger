# UndermineLedger

A World of Warcraft Classic (Season of Discovery) addon that tracks
**Tarnished Undermine Real** boss loot.

Tarnished Undermine Real can be looted once per lockout period per boss.
Dungeon bosses reset daily; raid bosses reset on their own instance
lockout (weekly, unless extended/reset early). UndermineLedger shows a
small icon when you enter a qualifying dungeon or raid — click it for a
red/green list of that instance's bosses (red = not yet looted this
period, green = already looted). A separate Ledger window (minimap icon,
or `/ul`) summarizes everything you've looted across every tracked
instance, not just the one you're standing in.

## Commands

- `/ul` — toggle the Ledger window
- `/ul config` — open options
- `/ul reset` — reset the alert icon's position
- `/ul history` — print the last 10 dated loot events for this character
- `/ul debug` — dump current zone/group, which reset API is present, and
  raw loot state for the current instance-group

## Notes

- Loot tracking is per-character (the currency itself isn't account bound).
- A dated history log (character, boss, zone, timestamp) is kept alongside
  the current per-boss red/green state — `/ul history` to view it. Capped
  at the last 500 events per character.
- The boss roster is self-learning: any boss seen dropping a Real that
  isn't already known gets added automatically and remembered, so future
  SoD phases that add bosses don't require an addon update to be tracked.
- Azuregos, Lord Kazzak, Prince Thunderaan, and the four Dragons of
  Nightmare (Taerar, Emeriss, Lethon, Ysondre) are open-world uniques, not
  instances — they're tracked passively and shown only in the Ledger
  window, not via the zone-entry popup.
