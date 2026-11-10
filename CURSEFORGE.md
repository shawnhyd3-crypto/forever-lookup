# Forever Lookup

**An OSRS-style wiki button for WoW Forever.** Click the book on your minimap, then click anything: an NPC, an item, a quest, a spell, a buff. You get its exact page on **Wowhead Forever**, **WarcraftDB Forever** or **warcraft.wiki.gg**.

## How it works

**The fast way:** hover over anything and press **CTRL-C**. A small popup opens with the link selected. Press **CTRL-C** again to copy it; the popup closes itself. Paste it in your browser.

**CTRL-SHIFT-C** gives you the warcraft.wiki.gg page instead.

Both keys are set up automatically the first time you log in, unless you already use them for something else. On Mac they're **CMD-C** and **CMD-SHIFT-C**. Not working? Type `/lookup keys` to see what's bound.

It works on **chat links** too: just hover the link and press CTRL-C.

**The OSRS way:** left-click the **book on your minimap**. A preview follows your cursor (*Lookup: Hogger (NPC #448)*). Click the thing you want to know about.

## Features

- Looks things up **by ID, not by name**, so you land on the right page even when names are shared. Falls back to a name search when no ID is available.
- Works on items, NPCs, quests (log and tracker), spells, buffs, mounts, toys, currencies, achievements, world objects and chat links.
- One panel, three Forever databases. It remembers your favourite.
- Wowhead links follow your game language automatically.
- In-game tooltip on the result icon, a search box, and your last 8 lookups.
- **No Lua error spam, ever.** When Forever hides information from addons in combat or instances, you get a name search instead of an error.

## Commands

- `/lookup`, `/flookup` or `/wiki`: open the panel
- `/lookup <name or shift-clicked link>`: search
- `/lookup keys`: show your Forever Lookup key bindings
- `/lookup target`: look up your target
- `/lookup minimap`: show or hide the minimap button
- `/lookup main wowhead|warcraftdb|wiki`: what CTRL-C opens first
- `/lookup alt wowhead|warcraftdb|wiki`: what CTRL-SHIFT-C opens
- `/lookup comments on|off`: open Wowhead pages at the comments
- `/lookup lang auto` (default), or de, es, fr, it, pt, ru, ko, cn, tw, mx, off: Wowhead language
- `/lookup style panel`: use the full panel instead of the quick popup
- `/lookup help`

## Why Ctrl+C?

WoW doesn't let addons open web pages or write to your clipboard. Every link addon has this limit.

---

Source code, issues and an optional Windows helper that opens links in your browser as soon as you press Ctrl+C: see the GitHub repository linked on this page.
