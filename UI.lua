-- Forever Lookup: minimap wiki button, armed "click anything" mode, result panel, slash commands.

local ADDON_NAME, ns = ...
local FL = ns.FL

local DEFAULTS = { site = "wowhead", history = {}, minimapAngle = 200, hideMinimap = false }
local HISTORY_MAX = 8
local db

BINDING_HEADER_FOREVERLOOKUP = "Forever Lookup"
BINDING_NAME_FOREVERLOOKUP_HOVER = "Look up what's under the mouse"
BINDING_NAME_FOREVERLOOKUP_ARM = "Arm lookup (click anything)"
BINDING_NAME_FOREVERLOOKUP_PANEL = "Open lookup panel / search"

---------------------------------------------------------------------------
-- Result panel
---------------------------------------------------------------------------
local panel = CreateFrame("Frame", "ForeverLookupFrame", UIParent, "BackdropTemplate")
panel:SetSize(400, 300)
panel:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
panel:SetFrameStrata("DIALOG")
panel:SetToplevel(true)
panel:SetClampedToScreen(true)
panel:SetMovable(true)
panel:EnableMouse(true)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
panel:Hide()
tinsert(UISpecialFrames, "ForeverLookupFrame")

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", 0, -16)
title:SetText("Forever Lookup")

local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -6, -6)

-- Search box
local search = CreateFrame("EditBox", "ForeverLookupSearchBox", panel, "InputBoxTemplate")
search:SetSize(270, 20)
search:SetPoint("TOPLEFT", 24, -40)
search:SetAutoFocus(false)
search:SetMaxLetters(80)
local searchHint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
searchHint:SetPoint("LEFT", search, "RIGHT", 8, 0)
searchHint:SetText("Enter to search")

-- Result header
local icon = panel:CreateTexture(nil, "ARTWORK")
icon:SetSize(40, 40)
icon:SetPoint("TOPLEFT", 22, -72)
local iconHit = CreateFrame("Frame", nil, panel)
iconHit:SetAllPoints(icon)
iconHit:EnableMouse(true)

local nameText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
nameText:SetPoint("RIGHT", panel, "RIGHT", -24, 0)
nameText:SetJustifyH("LEFT")
nameText:SetWordWrap(false)

local subText = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
subText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -4)
subText:SetPoint("RIGHT", panel, "RIGHT", -24, 0)
subText:SetJustifyH("LEFT")

-- Site buttons
local siteButtons = {}
for i, site in ipairs(FL.SITES) do
	local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	b:SetSize(110, 22)
	b:SetPoint("TOPLEFT", 22 + (i - 1) * 118, -124)
	b:SetText(site.label)
	b.siteKey = site.key
	siteButtons[i] = b
end

-- URL box (read-only feel)
local urlBox = CreateFrame("EditBox", "ForeverLookupURLBox", panel, "InputBoxTemplate")
urlBox:SetSize(350, 20)
urlBox:SetPoint("TOPLEFT", 26, -158)
urlBox:SetAutoFocus(false)
urlBox:SetMaxLetters(512)
local urlHint = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
urlHint:SetPoint("TOPLEFT", urlBox, "BOTTOMLEFT", -2, -4)
urlHint:SetText("Press Ctrl+C to copy, then paste it in your browser.")

-- History
local histLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
histLabel:SetPoint("TOPLEFT", 22, -202)
histLabel:SetText("Recent")
local histButtons = {}
for i = 1, HISTORY_MAX do
	local b = CreateFrame("Button", nil, panel)
	b:SetSize(176, 16)
	local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
	b:SetPoint("TOPLEFT", 22 + col * 180, -218 - row * 17)
	b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	b.text:SetAllPoints()
	b.text:SetJustifyH("LEFT")
	b.text:SetWordWrap(false)
	b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	histButtons[i] = b
end

local current, currentURL

local function RefreshHistory()
	for i, b in ipairs(histButtons) do
		local h = db and db.history[i]
		if h then
			b.entry = h
			b.text:SetText(h.name or ((FL.KIND_LABEL[h.kind] or h.kind) .. (h.id and (" #" .. h.id) or "")))
			b:Show()
		else
			b.entry = nil
			b:Hide()
		end
	end
	histLabel:SetShown(db and #db.history > 0)
end

local function AddHistory(e)
	if not db or e.blocked or not (e.id or e.name) then return end
	local entry = { kind = e.kind, id = e.id, name = e.name }
	for i = #db.history, 1, -1 do
		local h = db.history[i]
		if h.kind == entry.kind and h.id == entry.id and h.name == entry.name then table.remove(db.history, i) end
	end
	table.insert(db.history, 1, entry)
	while #db.history > HISTORY_MAX do table.remove(db.history) end
end

local function SelectURL()
	urlBox:SetText(currentURL or "")
	urlBox:SetFocus()
	urlBox:HighlightText()
	urlBox:SetCursorPosition(0)
	urlBox:HighlightText()
end

local function SetSite(key)
	if not current then return end
	local url = FL.BuildURL(current, key)
	if not url then return end
	db.site = key
	currentURL = url
	for _, b in ipairs(siteButtons) do
		b:SetEnabled(FL.BuildURL(current, b.siteKey) ~= nil)
		if b.siteKey == key then b:LockHighlight() else b:UnlockHighlight() end
	end
	SelectURL()
end

function FL.Show(e)
	if not e then return end
	FL.Fill(e)
	current = e
	icon:SetTexture(e.icon)
	nameText:SetText(e.name or (FL.KIND_LABEL[e.kind] or "Unknown"))
	local label = FL.KIND_LABEL[e.kind] or e.kind
	if e.blocked then
		subText:SetText(label .. " · hidden by combat restrictions, try again out of combat")
	elseif e.id then
		subText:SetText(string.format("%s · ID %d · WoW Forever", label, e.id))
	else
		subText:SetText(label .. " · name search (no ID available)")
	end
	-- pick preferred site, else first that can build a URL
	local key = db.site
	if not FL.BuildURL(e, key) then
		key = nil
		for _, s in ipairs(FL.SITES) do
			if FL.BuildURL(e, s.key) then key = s.key break end
		end
	end
	panel:Show()
	if key then
		SetSite(key)
		AddHistory(e)
	else
		currentURL = nil
		urlBox:SetText("")
		for _, b in ipairs(siteButtons) do b:SetEnabled(false); b:UnlockHighlight() end
	end
	RefreshHistory()
end

for _, b in ipairs(siteButtons) do
	b:SetScript("OnClick", function(self) SetSite(self.siteKey) end)
end
for _, b in ipairs(histButtons) do
	b:SetScript("OnClick", function(self)
		if self.entry then FL.Show({ kind = self.entry.kind, id = self.entry.id, name = self.entry.name }) end
	end)
end

urlBox:SetScript("OnTextChanged", function(self, userInput)
	if userInput then SelectURL() end -- keep it read-only
end)
urlBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
urlBox:SetScript("OnEscapePressed", function() panel:Hide() end)
urlBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

search:SetScript("OnEnterPressed", function(self)
	local text = FL.cleanName(self:GetText())
	self:ClearFocus()
	if not text then return end
	local e = FL.FromLink(text)
	local id = tonumber(text:match("^(%d+)$") or "")
	if not e and id then e = { kind = "item", id = id } end
	FL.Show(e or { kind = "search", name = text })
end)
search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

iconHit:SetScript("OnEnter", function(self)
	if not current or not current.id then return end
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	local ok = false
	if current.kind == "item" then
		ok = pcall(GameTooltip.SetItemByID, GameTooltip, current.id)
	elseif current.kind == "spell" then
		ok = pcall(GameTooltip.SetSpellByID, GameTooltip, current.id)
	elseif current.kind == "quest" or current.kind == "achievement" or current.kind == "currency" then
		ok = pcall(GameTooltip.SetHyperlink, GameTooltip, current.kind .. ":" .. current.id)
	end
	if ok then GameTooltip:Show() else GameTooltip:Hide() end
end)
iconHit:SetScript("OnLeave", function() GameTooltip:Hide() end)

panel:SetScript("OnShow", function() RefreshHistory() end)

function ForeverLookup_TogglePanel()
	if panel:IsShown() then panel:Hide() else
		panel:Show()
		if not current then
			icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
			nameText:SetText("Search or click the book")
			subText:SetText("Left-click the minimap book, then click anything in game.")
			for _, b in ipairs(siteButtons) do b:SetEnabled(false) end
		end
		search:SetFocus()
	end
end

---------------------------------------------------------------------------
-- Armed mode (the OSRS wiki-button flow)
---------------------------------------------------------------------------
local banner = CreateFrame("Frame", "ForeverLookupArmBanner", UIParent)
banner:SetSize(10, 10)
banner:SetFrameStrata("TOOLTIP")
banner:Hide()
tinsert(UISpecialFrames, "ForeverLookupArmBanner") -- Esc cancels
banner.text = banner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
banner.text:SetPoint("BOTTOMLEFT", banner, "TOPRIGHT", 14, -6)
banner.text:SetJustifyH("LEFT")
banner.sub = banner:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
banner.sub:SetPoint("TOPLEFT", banner.text, "BOTTOMLEFT", 0, -2)
banner.sub:SetText("Click to look up  ·  Esc or right-click to cancel")

local armEvents = CreateFrame("Frame")
local elapsedPreview = 0

local function SetLookupCursor()
	pcall(SetCursor, "INSPECT_CURSOR")
end

banner:SetScript("OnUpdate", function(self, elapsed)
	local scale = UIParent:GetEffectiveScale()
	local x, y = GetCursorPosition()
	self:ClearAllPoints()
	self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
	SetLookupCursor()
	elapsedPreview = elapsedPreview + elapsed
	if elapsedPreview > 0.1 then
		elapsedPreview = 0
		local e = FL.Resolve()
		self.text:SetText("Lookup: " .. (e and FL.Describe(e) or "|cff999999point at something|r"))
	end
end)

function FL.Disarm()
	if not FL.armed then return end
	FL.armed = false
	armEvents:UnregisterEvent("GLOBAL_MOUSE_DOWN")
	banner:Hide()
	pcall(ResetCursor)
	if FL.minimapButton then FL.minimapButton.icon:SetDesaturated(false) end
end

function FL.Arm()
	if FL.armed then return end
	FL.armed = true
	elapsedPreview = 1
	banner:Show()
	armEvents:RegisterEvent("GLOBAL_MOUSE_DOWN")
	if FL.minimapButton then FL.minimapButton.icon:SetDesaturated(true) end
end

banner:SetScript("OnHide", function() FL.Disarm() end)

armEvents:SetScript("OnEvent", function(_, event, button)
	if event ~= "GLOBAL_MOUSE_DOWN" or not FL.armed then return end
	local focus = FL.MouseFocus()
	if focus and FL.minimapButton and focus == FL.minimapButton then return end -- let the button toggle itself
	if button == "RightButton" then FL.Disarm() return end
	local e = FL.Resolve()
	local hadCursor = GetCursorInfo() ~= nil
	if not e then
		-- Chat links resolve on mouse-up via SetItemRef; give that a moment before giving up.
		C_Timer.After(0.35, function()
			if FL.armed then FL.Disarm(); FL.Print("nothing to look up there.") end
		end)
		return
	end
	FL.Disarm()
	FL.Show(e)
	-- A left-click on a bag/bank item would pick it up; put it back.
	if not hadCursor then
		C_Timer.After(0.2, function()
			if GetCursorInfo() ~= nil then ClearCursor() end
		end)
	end
end)

-- Clicking a chat link while armed looks it up.
if SetItemRef then
	hooksecurefunc("SetItemRef", function(link, text)
		if not FL.armed then return end
		local e = FL.FromLink(text) or FL.FromLink(link)
		if e then FL.Disarm(); FL.Show(e) end
	end)
end

function ForeverLookup_ToggleArm()
	if FL.armed then FL.Disarm() else FL.Arm() end
end

function ForeverLookup_HoverLookup()
	local e = FL.Resolve()
	if e then FL.Show(e) else FL.Print("nothing under the mouse to look up.") end
end

---------------------------------------------------------------------------
-- Minimap "wiki" button (drag to move around the minimap edge)
---------------------------------------------------------------------------
local function CreateMinimapButton()
	local b = CreateFrame("Button", "ForeverLookupMinimapButton", Minimap)
	b:SetSize(31, 31)
	b:SetFrameStrata("MEDIUM")
	b:SetFrameLevel(8)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	b:RegisterForDrag("LeftButton")
	b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	local overlay = b:CreateTexture(nil, "OVERLAY")
	overlay:SetSize(53, 53)
	overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	overlay:SetPoint("TOPLEFT")
	local bg = b:CreateTexture(nil, "BACKGROUND")
	bg:SetSize(20, 20)
	bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	bg:SetPoint("TOPLEFT", 7, -5)
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetSize(17, 17)
	b.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
	b.icon:SetPoint("TOPLEFT", 7, -6)

	local function UpdatePosition()
		local angle = math.rad(db.minimapAngle or 200)
		local radius = (Minimap:GetWidth() / 2) + 5
		b:ClearAllPoints()
		b:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
	end
	b.UpdatePosition = UpdatePosition

	b:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", function()
			local mx, my = Minimap:GetCenter()
			local scale = Minimap:GetEffectiveScale()
			local cx, cy = GetCursorPosition()
			cx, cy = cx / scale, cy / scale
			db.minimapAngle = math.deg(math.atan2(cy - my, cx - mx)) % 360
			UpdatePosition()
		end)
	end)
	b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

	b:SetScript("OnClick", function(_, mouse)
		if mouse == "RightButton" then
			FL.Disarm()
			ForeverLookup_TogglePanel()
		else
			ForeverLookup_ToggleArm()
		end
	end)
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("Forever Lookup")
		GameTooltip:AddLine("Left-click: then click anything to look it up", 1, 1, 1)
		GameTooltip:AddLine("Right-click: search and recent lookups", 1, 1, 1)
		GameTooltip:AddLine("Drag: move around the minimap", 0.7, 0.7, 0.7)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)

	UpdatePosition()
	b:SetShown(not db.hideMinimap)
	FL.minimapButton = b
end

-- Addon compartment (the addon list dropdown on the minimap)
function ForeverLookup_OnCompartmentClick(_, mouse)
	if mouse == "RightButton" then ForeverLookup_TogglePanel() else ForeverLookup_ToggleArm() end
end
function ForeverLookup_OnCompartmentEnter(_, frame)
	GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
	GameTooltip:AddLine("Forever Lookup")
	GameTooltip:AddLine("Left-click: arm lookup  ·  Right-click: panel", 1, 1, 1)
	GameTooltip:Show()
end
function ForeverLookup_OnCompartmentLeave() GameTooltip:Hide() end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
local function DebugDump()
	local data = FL.ttData[GameTooltip]
	if type(data) ~= "table" then FL.Print("GameTooltip has no data right now.") return end
	local function show(v)
		if v == nil then return "nil" end
		if FL.isSecret(v) then return "<secret>" end
		return tostring(v)
	end
	FL.Print(string.format("type=%s id=%s guid=%s", show(data.type), show(data.id), show(data.guid)))
	FL.Print("resolves to: " .. FL.Describe(FL.Resolve()))
end

SLASH_FOREVERLOOKUP1 = "/lookup"
SLASH_FOREVERLOOKUP2 = "/wiki"
SlashCmdList.FOREVERLOOKUP = function(msg)
	msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
	local cmd = msg:lower()
	if cmd == "" then
		ForeverLookup_TogglePanel()
	elseif cmd == "arm" then
		ForeverLookup_ToggleArm()
	elseif cmd == "target" then
		local guid = UnitGUID("target")
		local utype, id = FL.idFromGUID(guid)
		local name = FL.cleanName(UnitName("target"))
		if utype == "Player" then FL.Show({ kind = "player", name = name })
		elseif id then FL.Show({ kind = "npc", id = id, name = name })
		elseif name then FL.Show({ kind = "npc", name = name })
		else FL.Print("no readable target (combat restrictions may hide it).") end
	elseif cmd == "minimap" then
		db.hideMinimap = not db.hideMinimap
		if FL.minimapButton then FL.minimapButton:SetShown(not db.hideMinimap) end
		FL.Print("minimap button " .. (db.hideMinimap and "hidden" or "shown") .. ".")
	elseif cmd == "debug" then
		DebugDump()
	elseif cmd == "help" then
		FL.Print("/lookup  open panel  ·  /lookup <name or link>  search  ·  /lookup arm  ·  /lookup target  ·  /lookup minimap  ·  /lookup debug")
	else
		local e = FL.FromLink(msg)
		FL.Show(e or { kind = "search", name = FL.cleanName(msg) })
	end
end

---------------------------------------------------------------------------
-- Init
---------------------------------------------------------------------------
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
	if name ~= ADDON_NAME then return end
	self:UnregisterEvent("ADDON_LOADED")
	ForeverLookupDB = ForeverLookupDB or {}
	db = ForeverLookupDB
	for k, v in pairs(DEFAULTS) do
		if db[k] == nil then db[k] = (type(v) == "table") and {} or v end
	end
	CreateMinimapButton()
	if not db.seenIntro then
		db.seenIntro = true
		FL.Print("click the book on your minimap, then click anything to look it up. Type /lookup help for more.")
	end
end)
