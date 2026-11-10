-- Forever Lookup: core resolution (what is under the mouse -> {kind, id, name}) and URL building.
-- Built for WoW Forever (interface 16001, WOW_PROJECT_ID == WOW_PROJECT_CAMELOT == 18).
-- Midnight "secret values" are active on Forever, so every value read from the game is
-- checked with issecretvalue before it is compared, split or used as a table key.

local ADDON_NAME, ns = ...
local FL = {}
ns.FL = FL
_G.ForeverLookup = FL

FL.version = "0.10.0"

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function isSecret(v)
	if v == nil or not issecretvalue then return false end
	return issecretvalue(v) == true
end
FL.isSecret = isSecret

-- Returns v only if it is present and readable.
local function safe(v)
	if v == nil or isSecret(v) then return nil end
	return v
end
FL.safe = safe

local function try(f, ...)
	if type(f) ~= "function" then return nil end
	local ok, a, b, c, d, e, g, h, i, j, k = pcall(f, ...)
	if ok then return a, b, c, d, e, g, h, i, j, k end
	return nil
end
FL.try = try

local function posInt(v)
	v = safe(v)
	if type(v) == "string" then v = tonumber(v) end
	if type(v) == "number" and v > 0 then return v end
	return nil
end
FL.posInt = posInt

local function cleanName(s)
	s = safe(s)
	if type(s) ~= "string" then return nil end
	s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""):gsub("|A.-|a", "")
	s = s:gsub("^%s+", ""):gsub("%s+$", "")
	if s == "" then return nil end
	return s
end
FL.cleanName = cleanName

function FL.urlencode(s)
	s = tostring(s or "")
	s = s:gsub("[^%w%-%._~ ]", function(c) return string.format("%%%02X", c:byte()) end)
	s = s:gsub(" ", "+")
	return s
end

---------------------------------------------------------------------------
-- Link targets (verified 2026-11-10)
--   Wowhead:     https://www.wowhead.com/forever/{type}={id}
--   WarcraftDB:  https://forever.warcraftdb.com/data/{type}/{id}
--   Wiki:        https://warcraft.wiki.gg/wiki/Special:Search?search={name}&go=Go
---------------------------------------------------------------------------
local WOWHEAD_TYPES = {
	item = "item", npc = "npc", quest = "quest", spell = "spell", object = "object",
	faction = "faction", currency = "currency", achievement = "achievement",
}
local WARCRAFTDB_TYPES = {
	item = "item", npc = "npc", quest = "quest", spell = "spell", object = "object", faction = "faction",
}

-- Wowhead language subdomains (like Wowhead Quick Link's prefix setting).
FL.WOWHEAD_LANGS = { de = true, es = true, fr = true, it = true, pt = true, ru = true, ko = true, cn = true, tw = true, mx = true }

function FL.WowheadHost()
	local lang = FL.db and FL.db.wowheadLang
	if lang and FL.WOWHEAD_LANGS[lang] then return lang .. ".wowhead.com" end
	return "www.wowhead.com"
end

FL.SITES = {
	{
		key = "wowhead", label = "Wowhead",
		build = function(e)
			local t = WOWHEAD_TYPES[e.kind]
			if t and e.id then return string.format("https://%s/forever/%s=%d", FL.WowheadHost(), t, e.id) end
			if e.name then return "https://" .. FL.WowheadHost() .. "/forever/search?q=" .. FL.urlencode(e.name) end
		end,
	},
	{
		key = "warcraftdb", label = "WarcraftDB",
		build = function(e)
			local t = WARCRAFTDB_TYPES[e.kind]
			if t and e.id then return string.format("https://forever.warcraftdb.com/data/%s/%d", t, e.id) end
			if e.name then return "https://forever.warcraftdb.com/search?q=" .. FL.urlencode(e.name) end
		end,
	},
	{
		key = "wiki", label = "Wiki",
		build = function(e)
			if e.name then
				return "https://warcraft.wiki.gg/wiki/Special:Search?search=" .. FL.urlencode(e.name) .. "&go=Go"
			end
		end,
	},
}

function FL.GetSite(key)
	for _, s in ipairs(FL.SITES) do
		if s.key == key then return s end
	end
	return FL.SITES[1]
end

function FL.BuildURL(e, siteKey)
	local site = FL.GetSite(siteKey)
	return try(site.build, e)
end

---------------------------------------------------------------------------
-- Entity naming / icons
---------------------------------------------------------------------------
FL.KIND_LABEL = {
	item = "Item", npc = "NPC", quest = "Quest", spell = "Spell", object = "Object",
	faction = "Faction", currency = "Currency", achievement = "Achievement",
	player = "Player", search = "Search",
}

local DEFAULT_ICONS = {
	npc = "Interface\\Icons\\INV_Misc_Head_Human_01",
	object = "Interface\\Icons\\INV_Misc_Gear_01",
	quest = "Interface\\Icons\\INV_Misc_Note_01",
	faction = "Interface\\Icons\\INV_Misc_Note_02",
	player = "Interface\\Icons\\INV_Misc_GroupLooking",
	search = "Interface\\Icons\\INV_Misc_Spyglass_03",
	achievement = "Interface\\Icons\\Achievement_General",
}
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"

function FL.Fill(e)
	local id = e.id
	if e.kind == "item" and id then
		e.name = e.name or cleanName(C_Item and try(C_Item.GetItemNameByID, id)) or cleanName(try(GetItemInfo, id))
		e.icon = e.icon or safe(C_Item and try(C_Item.GetItemIconByID, id)) or safe(try(GetItemIcon, id))
	elseif e.kind == "spell" and id then
		e.name = e.name or cleanName(C_Spell and try(C_Spell.GetSpellName, id)) or cleanName(try(GetSpellInfo, id))
		e.icon = e.icon or safe(C_Spell and try(C_Spell.GetSpellTexture, id))
	elseif e.kind == "quest" and id then
		e.name = e.name or cleanName(C_QuestLog and try(C_QuestLog.GetTitleForQuestID, id))
	elseif e.kind == "achievement" and id then
		local _, n, _, _, _, _, _, _, _, icon = try(GetAchievementInfo, id)
		e.name = e.name or cleanName(n)
		e.icon = e.icon or safe(icon)
	elseif e.kind == "currency" and id then
		local info = C_CurrencyInfo and try(C_CurrencyInfo.GetCurrencyInfo, id)
		if type(info) == "table" then
			e.name = e.name or cleanName(info.name)
			e.icon = e.icon or safe(info.iconFileID)
		end
	elseif e.kind == "faction" and id then
		local data = C_Reputation and try(C_Reputation.GetFactionDataByID, id)
		if type(data) == "table" then e.name = e.name or cleanName(data.name) end
	end
	e.icon = e.icon or DEFAULT_ICONS[e.kind] or QUESTION
	return e
end

---------------------------------------------------------------------------
-- Tooltip tracking: remember the last TooltipData each tooltip showed.
---------------------------------------------------------------------------
FL.ttData = {}

local function trackTooltip(tooltip)
	if not tooltip or FL.ttData[tooltip] ~= nil then return end
	FL.ttData[tooltip] = false
	tooltip:HookScript("OnHide", function(self) FL.ttData[self] = false end)
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
	TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes or "ALL", function(tooltip, data)
		if tooltip == GameTooltip or tooltip == ItemRefTooltip then
			FL.ttData[tooltip] = data or false
		end
	end)
end
trackTooltip(GameTooltip)
trackTooltip(ItemRefTooltip)

function FL.TooltipName(tooltip)
	if not tooltip or not tooltip.GetName then return nil end
	local fs = _G[(tooltip:GetName() or "") .. "TextLeft1"]
	return fs and cleanName(fs:GetText())
end

local TT = (Enum and Enum.TooltipDataType) or {}

-- GUID "Creature-0-<server>-<map>-<zone>-<npcID>-<spawn>"; Forever obfuscates server/spawn only.
local function idFromGUID(guid)
	guid = safe(guid)
	if type(guid) ~= "string" then return nil end
	local utype, _, _, _, _, id = strsplit("-", guid)
	return utype, tonumber(id)
end
FL.idFromGUID = idFromGUID

function FL.FromTooltipData(data, tooltip)
	if type(data) ~= "table" then return nil end
	local ty, id = safe(data.type), posInt(data.id)
	local name = tooltip and FL.TooltipName(tooltip)

	if ty == nil then return nil end
	if ty == TT.Item or ty == TT.Toy then
		if id then return { kind = "item", id = id, link = safe(data.hyperlink) } end
	elseif ty == TT.Spell or ty == TT.UnitAura then
		if id then return { kind = "spell", id = id } end
	elseif ty == TT.Mount then
		if id and C_MountJournal then
			local _, spellID = try(C_MountJournal.GetMountInfoByID, id)
			spellID = posInt(spellID)
			if spellID then return { kind = "spell", id = spellID } end
		end
	elseif ty == TT.Unit or ty == TT.Corpse then
		local utype, npcID = idFromGUID(data.guid)
		if utype == "Player" then return { kind = "player", name = name } end
		if npcID and npcID > 0 then return { kind = "npc", id = npcID, name = name } end
		if name then return { kind = "npc", name = name, partial = true } end
		return { kind = "npc", blocked = true }
	elseif ty == TT.Object then
		if id then return { kind = "object", id = id, name = name } end
		local utype, objID = idFromGUID(data.guid)
		if utype == "GameObject" and objID and objID > 0 then return { kind = "object", id = objID, name = name } end
		if name then return { kind = "object", name = name, partial = true } end
	elseif ty == TT.Currency then
		if id then return { kind = "currency", id = id } end
	elseif ty == TT.Achievement then
		if id then return { kind = "achievement", id = id } end
	elseif ty == TT.Quest then
		if id then return { kind = "quest", id = id } end
	end
	return nil
end

---------------------------------------------------------------------------
-- Hyperlinks ("|Hitem:6948:...|h[Hearthstone]|h" or "item:6948")
---------------------------------------------------------------------------
local LINK_KINDS = {
	item = "item", spell = "spell", quest = "quest", achievement = "achievement",
	currency = "currency", enchant = "spell", talent = "spell", mount = "spell",
}

function FL.FromLink(link)
	link = safe(link)
	if type(link) ~= "string" then return nil end
	local ltype, id = link:match("|H(%a+):(%d+)")
	if not ltype then ltype, id = link:match("^(%a+):(%d+)") end
	local kind = ltype and LINK_KINDS[ltype]
	id = tonumber(id)
	if kind and id and id > 0 then
		local name = link:match("|h%[(.-)%]|h")
		return { kind = kind, id = id, name = cleanName(name), link = link }
	end
	return nil
end

---------------------------------------------------------------------------
-- Frames under the mouse (quest log, objective tracker, achievement frames)
---------------------------------------------------------------------------
function FL.MouseFocus()
	if GetMouseFoci then
		local foci = GetMouseFoci()
		return foci and foci[1]
	end
	if GetMouseFocus then return GetMouseFocus() end
end

local function isDescendant(frame, ancestor)
	local depth = 0
	while frame and depth < 12 do
		if frame == ancestor then return true end
		frame = frame.GetParent and frame:GetParent()
		depth = depth + 1
	end
	return false
end
FL.isDescendant = isDescendant

function FL.FromFocus(focus)
	local f, depth = focus, 0
	while f and depth < 5 do
		if f.IsForbidden and f:IsForbidden() then return nil end
		if f == WorldFrame or f == UIParent then return nil end
		local q = posInt(f.questID) or posInt(f.poiQuestID)
		if not q and type(f.info) == "table" then q = posInt(f.info.questID) end
		if not q and posInt(f.questLogIndex) and C_QuestLog and C_QuestLog.GetInfo then
			local info = try(C_QuestLog.GetInfo, f.questLogIndex)
			if type(info) == "table" and not info.isHeader then q = posInt(info.questID) end
		end
		if q then return { kind = "quest", id = q } end
		local a = posInt(f.achievementID)
		if a then return { kind = "achievement", id = a } end
		f = f.GetParent and f:GetParent()
		depth = depth + 1
	end
	return nil
end

---------------------------------------------------------------------------
-- Main resolver: what is the player pointing at right now?
---------------------------------------------------------------------------
function FL.Resolve()
	local focus = FL.MouseFocus()

	-- 1) Chat-link tooltip (ItemRefTooltip) when hovering it
	if focus and ItemRefTooltip and ItemRefTooltip:IsShown() and isDescendant(focus, ItemRefTooltip) then
		local e = FL.FromTooltipData(FL.ttData[ItemRefTooltip], ItemRefTooltip)
		if e then return e end
	end

	-- 2) UI frames that carry their own IDs (quest log, tracker, achievements)
	if focus and focus ~= WorldFrame then
		local e = FL.FromFocus(focus)
		if e then return e end
	end

	-- 3) Whatever GameTooltip is showing (bags, bars, units, world objects, buffs...)
	if GameTooltip and GameTooltip:IsShown() then
		local e = FL.FromTooltipData(FL.ttData[GameTooltip], GameTooltip)
		if e and not e.partial and not e.blocked then return e end
		local _, link, itemID = try(GameTooltip.GetItem, GameTooltip)
		local le = FL.FromLink(link)
		if le then return le end
		if posInt(itemID) then return { kind = "item", id = posInt(itemID) } end
		local _, spellID = try(GameTooltip.GetSpell, GameTooltip)
		if posInt(spellID) then return { kind = "spell", id = posInt(spellID) } end
		if e then return e end
	end

	-- 4) World cursor (objects/units with no GameTooltip shown)
	if focus == WorldFrame and C_TooltipInfo and C_TooltipInfo.GetWorldCursor then
		local data = try(C_TooltipInfo.GetWorldCursor)
		local e = FL.FromTooltipData(data, nil)
		if e then return e end
	end

	-- 5) Name-only fallback
	local name = GameTooltip and GameTooltip:IsShown() and FL.TooltipName(GameTooltip)
	if name then return { kind = "search", name = name } end
	return nil
end

-- Short description for previews and messages.
function FL.Describe(e)
	if not e then return "nothing" end
	FL.Fill(e)
	local label = FL.KIND_LABEL[e.kind] or e.kind
	if e.blocked then return label .. " (hidden by combat restrictions)" end
	if e.name and e.id then return string.format("%s (%s #%d)", e.name, label, e.id) end
	if e.name then return string.format("%s (%s)", e.name, label) end
	if e.id then return string.format("%s #%d", label, e.id) end
	return label
end

function FL.Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff7ba4fcForever Lookup|r: " .. tostring(msg))
end
