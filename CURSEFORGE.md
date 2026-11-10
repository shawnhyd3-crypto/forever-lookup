# Forever Lookup

**An OSRS-style wiki button for WoW Forever.** Click the book on your minimap, then click anything: an NPC, an item, a quest, a spell, a buff. You get its exact page on **Wowhead Forever**, **WarcraftDB Forever** or **warcraft.wiki.gg**.

## How it works

1. **Left-click the book** on your minimap. A preview follows your cursor: *Lookup: Hogger (NPC #448)*.
2. **Click the thing** you want to know about.
3. The panel opens with the link selected. **Press Ctrl+C** and paste it in your browser.

Prefer a key? Bind **"Look up what's under the mouse"** under Key Bindings > AddOns > Forever Lookup. Best for action buttons and bag items.

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
- `/lookup help`

## Why Ctrl+C?

WoW doesn't let addons open web pages or write to your clipboard. Every link addon has this limit.

---

Source code, issues and an optional Windows helper that opens links in your browser as soon as you press Ctrl+C: see the GitHub repository linked on this page.
