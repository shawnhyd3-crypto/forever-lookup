# Forever Lookup

<img src="media/logo.png" alt="Forever Lookup logo" width="128" align="right">

[CurseForge](https://www.curseforge.com/wow/addons/forever-lookup) (pending moderation)

An OSRS-style wiki button for **World of Warcraft: Forever**. Click the book on your minimap, then click anything in the game: an NPC, an item in your bags, a quest, a spell, a buff, a herb. You get its exact page on Wowhead Forever, WarcraftDB Forever or warcraft.wiki.gg.

## Features

- **CTRL-C quick links.** Hover over anything and press CTRL-C: a small popup opens with the Wowhead Forever link selected. Press CTRL-C again to copy and the popup closes itself. CTRL-SHIFT-C gives the wiki page instead. Both keys are bound on first login unless you already use them (CMD-C / CMD-SHIFT-C on Mac). Works on chat links just by hovering them.
- **Your language, automatically.** Wowhead links follow the game client's language. Optional `#comments` jump.
- **No Lua error spam.** Every lookup runs behind a safety net, including hovering buffs in combat.
- **Click-anything lookup.** Left-click the minimap book to arm it. A preview follows your cursor ("Lookup: Hogger (NPC #448)"). Click to look it up. Esc or right-click cancels.
- **Hover key.** Bind "Look up what's under the mouse" (Key Bindings > AddOns > Forever Lookup) to look up action buttons and bag items without clicking them.
- **Looks things up by ID, not by name**, like the OSRS wiki's Special:Lookup. You get the right page even when names are shared. If no ID is available, it falls back to a name search instead of a dead end.
- **Three Forever databases** in one panel: Wowhead (`/forever/`), WarcraftDB Forever and warcraft.wiki.gg. It remembers the one you picked last.
- **Works on:** items, NPCs, quests (quest log and tracker), spells, buffs and debuffs, mounts, toys, currencies, achievements, world objects, and chat links (click a link while armed).
- **Panel extras:** in-game tooltip on the icon, a search box (type a name, an item ID or shift-click a link) and your last 8 lookups.
- **Safe in combat.** Forever hides some unit information from addons in combat and inside instances. Forever Lookup checks for that and offers a name search instead of throwing errors.

## Using it

| Action | How |
|---|---|
| Link for what's under the mouse | **CTRL-C** (CTRL-SHIFT-C for the alternate site) |
| Look something up by clicking | Left-click the minimap book, then click the thing |
| Check your key bindings | `/lookup keys` (also shown in the minimap book's tooltip) |
| Wowhead language | Automatic; override with `/lookup lang de` (es, fr, it, pt, ru, ko, cn, tw, mx, off, auto) |
| Open Wowhead at the comments | `/lookup comments on` |
| Change the main site | `/lookup main wowhead\|warcraftdb\|wiki` |
| Change the alternate site | `/lookup alt wowhead\|warcraftdb\|wiki` |
| Unique slash command | `/flookup` works if another addon took `/lookup` or `/wiki` |
| Full panel for every lookup | `/lookup style panel` (`/lookup style quick` to go back) |
| Search / recent lookups | Right-click the minimap book, or `/lookup` |
| Search by name or link | `/lookup Hogger` or `/lookup [shift-clicked link]` |
| Look up your target | `/lookup target` |
| Hide the minimap button | `/lookup minimap` (the addon list dropdown on the minimap also has it) |
| Troubleshoot | `/lookup debug` while hovering something |

The link appears pre-selected. Press **Ctrl+C**, then paste it in your browser.

## Why it can't open your browser

WoW does not let addons open web pages or write to your clipboard (Blizzard restricts `LaunchURL` and `CopyToClipboard` to its own code). Every link addon has the same limit. You copy with Ctrl+C.

### Optional: Forever Lookup Helper (Windows)

If you want the page to open the moment you press Ctrl+C, the `helper/` folder in this repository has a small, optional Windows tray script:

- It **only reads your clipboard**. It never touches the game, its files or its memory.
- It opens a link **only** if the entire clipboard text is one of the five Forever Lookup link shapes (Wowhead Forever, WarcraftDB Forever, warcraft.wiki.gg search). Anything else you copy is ignored. Run `ForeverLookupHelper.ps1 -Test` to see the checks.
- It is about 100 lines of plain PowerShell. Read it before you run it.

Install (Windows 10/11):

1. Download this repository and open the `helper` folder.
2. Right-click `Install-Helper.ps1` > **Run with PowerShell**. Windows may ask you to confirm because the script came from the internet.
3. A blue "i" appears in your system tray. Right-click it to pause or exit. It starts with Windows.

Uninstall: right-click `Uninstall-Helper.ps1` > Run with PowerShell.

The helper is not part of the CurseForge download. Mac is not supported.

## Known limits

- Inside dungeons, raids, battlegrounds and in combat, Forever hides NPC identities from addons. You get a name search or a "try again out of combat" message.
- Some world objects may only resolve by name.
- Clicking an action button while armed still uses it (addons cannot block clicks). Use the hover key for buttons.
- Wowhead's Forever database doesn't have every achievement yet.

## License

MIT. See `LICENSE`.
