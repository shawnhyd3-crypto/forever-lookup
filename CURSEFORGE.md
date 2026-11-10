# Forever Lookup

**An OSRS-style wiki button for WoW Forever.** Click the book on your minimap, then click anything: an NPC, an item, a quest, a spell, a buff. You get its exact page on **Wowhead Forever**, **WarcraftDB Forever** or **warcraft.wiki.gg**.

## How it works

**The fast way:** hover over anything and press **CTRL-C**. A small popup opens with the link selected. Press **CTRL-C** again to copy it; the popup closes itself. Paste it in your browser.

**CTRL-SHIFT-C** gives you the warcraft.wiki.gg page instead.

Both keys are set up automatically the first time you log in, unless you already use them for something else.

**The OSRS way:** left-click the **book on your minimap**. A preview follows your cursor (*Lookup: Hogger (NPC #448)*). Click the thing you want to know about.

## Features

- Looks things up **by ID, not by name**, so you land on the right page even when names are shared. Falls back to a name search when no ID is available.
- Works on items, NPCs, quests (log and tracker), spells, buffs, mounts, toys, currencies, achievements, world objects and chat links.
- One panel, three Forever databases. It remembers your favourite.
- In-game tooltip on the result icon, a search box, and your last 8 lookups.
- Safe in combat: when Forever hides information from addons, you get a name search instead of an error.

## Commands

- `/lookup` or `/wiki`: open the panel
- `/lookup <name or shift-clicked link>`: search
- `/lookup target`: look up your target
- `/lookup minimap`: show or hide the minimap button
- `/lookup lang de` (or es, fr, it, pt, ru, ko, cn, tw, mx, off): Wowhead links in your language
- `/lookup alt wowhead|warcraftdb|wiki`: what CTRL-SHIFT-C opens
- `/lookup style panel`: use the full panel instead of the quick popup
- `/lookup help`

## Why Ctrl+C?

WoW doesn't let addons open web pages or write to your clipboard. Every link addon has this limit.

---

Source code, issues and an optional Windows helper that opens links in your browser as soon as you press Ctrl+C: see the GitHub repository linked on this page.
