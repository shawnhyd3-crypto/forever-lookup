# Changelog

## 0.10.0 (2026-11-10)

Quick-link mode, inspired by Wowhead Quick Link.

- Hover over anything and press **CTRL-C**: a small popup opens with the link selected. Press CTRL-C again to copy; the popup closes itself.
- **CTRL-SHIFT-C** gives an alternate link (warcraft.wiki.gg by default; change with `/lookup alt`).
- Both keys are bound automatically on first login, only if you haven't bound them and nothing else uses them.
- Popup has one-click buttons for Wowhead, WarcraftDB and Wiki, plus "More" for the full panel.
- `/lookup lang de|es|fr|it|pt|ru|ko|cn|tw|mx|off`: Wowhead links in your language.
- `/lookup style panel` brings back the full panel for every lookup.
- The minimap book and armed click mode now use the quick popup too.

## 0.9.0 (2026-11-10)

First public beta.

- Minimap book button: left-click arms "click anything" lookup with a live cursor preview, right-click opens the panel.
- Hover-lookup and arm keybindings; addon compartment entry.
- ID-based lookups for items, NPCs, quests, spells, auras, mounts, toys, currencies, achievements, world objects and chat links.
- Links for Wowhead Forever, WarcraftDB Forever and warcraft.wiki.gg, with name-search fallback.
- Panel with search box, in-game tooltip and history of the last 8 lookups.
- Checks Forever's addon restrictions before reading unit data.
- Slash commands: /lookup (/wiki), target, minimap, debug, help.
