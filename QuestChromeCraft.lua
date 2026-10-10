-- QuestChromeCraft (RU), 3.3.5a — inline Russian quest translation appended
-- directly inside Blizzard's own QuestLogFrame and QuestFrame (NPC
-- dialogue). Rewritten to touch ONLY those two native frames — no
-- gossip, no tooltip translation, no third-party addon integrations
-- (QuestGuru/Immersion/Storyline/WorldMap), no options UI, no slash
-- command, no chat output of any kind. Quest text is sourced entirely
-- from QuestData_RU.lua (QCC_QuestData table, scraped from Wowhead).

-- A client already running with GetLocale() == "ruRU" already shows
-- every quest's own Title/Description/Objectives natively in Russian --
-- re-adding that same text as a second inline block would just be
-- redundant. The community-comment verdict (Comments/Coords, scraped
-- from Wowhead) is NOT native client data on any locale though -- it's
-- genuinely new information the base game never shows, so it stays
-- useful (and gets shown) even on a ruRU client. QCC_IsRuClient below
-- gates only the translation half of QCC_Inline_Apply, never the
-- verdict half.
local QCC_IsRuClient = (GetLocale() == "ruRU");

local QCC_name = UnitName("player");
-- UnitClass/UnitRace return (localizedName, englishFileName) -- the
-- LOCALIZED name is what we want as the ultimate fallback if a class/race
-- isn't in QCC_RU_CLASS_NAME/QCC_RU_RACE_NAME below (still English on an
-- enUS client, but at least a real display name, not an internal file
-- token like "WARRIOR"). The file name is looked up separately, only
-- where needed, to key into those tables.
local QCC_class = UnitClass("player");
local QCC_race = UnitRace("player");

local QCC_RU_Font1 = "Interface\\AddOns\\QuestChromeCraft\\Fonts\\morpheus_ru.ttf";
local QCC_RU_Font2 = "Interface\\AddOns\\QuestChromeCraft\\Fonts\\frizquadratatt_ru.ttf";

--------------------------------------------------------------------------
-- Macro expansion for the Russian source text: $N/$C/$R/$B/$G x:y; plus
-- the |3-N(...) Cyrillic-declension tag.
--------------------------------------------------------------------------

-- Russian names for the player's own class/race, nominative case only --
-- the client is enUS, so there is no loaded Cyrillic declension DBC to
-- ask WoW itself to decline these into the |3-N(...) case the source
-- text wants (that tag only works when the CLIENT's own locale is
-- Russian, since the declension tables ship as part of the client's own
-- locale data, not something an addon can query or supply itself) -- so
-- |3-N($C)/|3-N($R) below is expanded to the plain nominative form
-- instead of a real declension.
local QCC_RU_CLASS_NAME = {
   WARRIOR = "воин", PALADIN = "паладин", HUNTER = "охотник", ROGUE = "разбойник",
   PRIEST = "жрец", DEATHKNIGHT = "рыцарь смерти", SHAMAN = "шаман", MAGE = "маг",
   WARLOCK = "чернокнижник", DRUID = "друид",
};
local QCC_RU_RACE_NAME = {
   Human = "человек", Orc = "орк", Dwarf = "дворф", NightElf = "ночной эльф",
   Scourge = "нежить", Tauren = "таурен", Gnome = "гном", Troll = "тролль",
   BloodElf = "эльф крови", Draenei = "дреней",
};

local function QCC_ExpandRuMacros(msg)
   if (msg == nil or msg == "") then
      return msg;
   end
   msg = string.gsub(msg, "|3%-%d%((%$?%a+)%)", "%1");
   -- NEW_LINE is the scraper's own line-break marker (used across every
   -- field in QuestData_RU.lua, not just Comments -- Wowhead's raw HTML
   -- has actual <br> tags/paragraph breaks that scrape_wowhead_quest.py
   -- turns into this literal marker before writing the Lua string; the
   -- addon has to turn it back into a real newline to display correctly,
   -- same as $B below).
   msg = string.gsub(msg, "NEW_LINE", "\n");
   msg = string.gsub(msg, "%$B", "\n");
   msg = string.gsub(msg, "%$N", QCC_name);
   local _, classFile = UnitClass("player");
   local _, raceFile = UnitRace("player");
   msg = string.gsub(msg, "%$C", QCC_RU_CLASS_NAME[classFile] or QCC_class);
   msg = string.gsub(msg, "%$R", QCC_RU_RACE_NAME[raceFile] or QCC_race);
   -- $G male:female; -- UnitSex("player") returns 2 for male, 3 for female.
   msg = string.gsub(msg, "%$G([^:]*):([^;]*);", function(male, female)
      if (UnitSex("player") == 3) then
         return female;
      end
      return male;
   end);

   -- Wowhead's OWN placeholder format on its already-localized /ru/ pages
   -- is different from Blizzard's raw $N/$C/$R/$G source macros above --
   -- Wowhead pre-resolves those into human-readable Russian angle-bracket
   -- tags before the scrape ever happens: <имя> for player name, <класс>/
   -- <раса> for class/race, and <мужская форма/женская форма> for any
   -- gendered word pair (confirmed live across the scraped data: hundreds
   -- of distinct pairs like <герой/героиня>, <был/была>, <готов/готова> --
   -- this is a general "pick left or right half by gender" pattern, not a
   -- fixed vocabulary to special-case). Angle-bracket tags that are NOT a
   -- slash-separated pair (<ик>, <кашляет>, <шепотом>, etc.) are NPC
   -- flavor-text stage directions, not player-substitution macros -- left
   -- untouched on purpose.
   msg = string.gsub(msg, "<имя>", QCC_name);
   msg = string.gsub(msg, "<класс>", QCC_RU_CLASS_NAME[classFile] or QCC_class);
   msg = string.gsub(msg, "<раса>", QCC_RU_RACE_NAME[raceFile] or QCC_race);
   msg = string.gsub(msg, "<([^/<>]+)/([^/<>]+)>", function(male, female)
      if (UnitSex("player") == 3) then
         return female;
      end
      return male;
   end);

   return msg;
end

local function QCC_GetQuestData(strID, field)
   if (strID == nil or strID == "0") then
      return nil;
   end
   local entry = QCC_QuestData[strID];
   if (entry == nil) then
      return nil;
   end
   return entry[field];
end

--------------------------------------------------------------------------
-- Inline translation: appends the Russian quest text directly INSIDE the
-- native QuestLogDetailScrollChildFrame / QuestDetailScrollChildFrame --
-- below whatever Blizzard's own QuestLog_Update / QuestFrame code just
-- laid out (title/objectives/description/rewards), separated by the
-- native UI-HorizontalBreak divider texture (Interface\QuestFrame\UI-
-- HorizontalBreak -- the same flourish Blizzard's own FrameXML uses
-- elsewhere in this same window, so it looks native). One shared
-- scrollbar, one parchment, exact native width.
--------------------------------------------------------------------------

local QCC_InlineDividersTop = {};    -- scrollChild -> divider texture (between native English text and title)
local QCC_InlineTitles = {};         -- scrollChild -> FontString (Morpheus, matches native quest title styling)
local QCC_InlineBodies = {};         -- scrollChild -> FontString (translated body text)
local QCC_InlineDividers = {};       -- scrollChild -> divider texture (between body and comments)
local QCC_InlineComments = {};       -- scrollChild -> FontString (Wowhead comments)

-- Finds the lowest bottom edge of the native English quest text, so the
-- translation can be anchored right after it. Anchors directly to
-- Blizzard's own named FontStrings (QuestInfoRewardText, QuestInfo
-- ObjectivesText, QuestInfoDescriptionText) instead of scanning
-- GetRegions()/GetChildren() for "whatever's currently lowest" -- this is
-- the same widget-name-based approach the original QuestTradutor addon
-- uses (confirmed by reading its source directly) instead of computing
-- geometry by hand. QuestInfoRewardText specifically is the "You will
-- receive: ..." line INSIDE the rewards section (QuestInfoRewardsFrame),
-- not the empty fixed-size QuestRewardScrollChildFrame container around
-- it -- confirmed live via in-game /run that the container's own
-- GetBottom() reports the bottom of the whole scrollable area regardless
-- of how little content is actually in it, which is what caused the
-- translation to overlap "Rewards"/"You will receive" instead of
-- appending after them. All three of these globals are shared between
-- QuestLogFrame and QuestFrame (both use the same QuestInfo_Display
-- templates), so checking GetParent() against scrollChild is required to
-- know which frame's copy is currently relevant -- a QuestInfoSpacerFrame-
-- based version of this function without that check previously broke
-- QuestLogFrame's translation entirely (silently rendered off-screen, no
-- Lua error) by picking up state left over from the other frame.
local function QCC_FindContentBottom(scrollChild)
   local lowest = nil;
   -- QuestInfoRewardText (an earlier version of this list used it) is
   -- actually unused custom "reward flavor text" per Blizzard's own
   -- QuestInfo.lua, empty on almost every real quest -- confirmed live
   -- via in-game /run: IsShown()==true but GetText()==nil and
   -- GetBottom()==nil (an empty FontString has no computable geometry).
   -- The real "You will also receive:" label is QuestInfoItemReceiveText.
   --
   -- NOT gated on GetParent()==scrollChild -- confirmed live via /run
   -- that QuestInfoItemReceiveText's actual parent is some other
   -- Blizzard-internal container (e.g. QuestInfoRewardsFrame), never the
   -- scrollChild itself, so that check always failed and silently
   -- excluded every one of these widgets no matter what. These globals
   -- exist exactly ONCE regardless of which of QuestLogFrame/QuestFrame
   -- is open (QuestInfo_Display reparents/repositions the same widgets
   -- rather than creating separate copies per frame), so IsShown() alone
   -- already tells us whether the currently-open frame is using them --
   -- no parent-matching needed at all.
   -- IsVisible(), not IsShown() -- confirmed live on a custom ruRU client
   -- (Fallen) that QuestInfoDescriptionText:IsShown() returns nil while
   -- IsVisible() returns 1 for the exact same on-screen widget. IsShown()
   -- only reads the widget's own shown flag; IsVisible() accounts for the
   -- parent chain actually being displayed, which is what we care about
   -- here. With IsShown() every widget got skipped, lowest stayed nil,
   -- and the divider anchored to scrollChild's TOP+(-6) -- landing on top
   -- of the quest's own Description heading instead of below the rewards.
   -- QuestInfoRewardsFrame is the whole rewards SECTION container (title
   -- + items + money + xp), and its GetBottom() is the true bottom of
   -- that block -- confirmed live on the Fallen client that it reports
   -- IsVisible()==1 and a real GetBottom() (~406) when the individual
   -- QuestInfoItemReceiveText/QuestInfoDescriptionText widgets somehow
   -- don't. Listed first so it wins when present. QuestInfoObjectivesText
   -- / QuestInfoDescriptionText stay as fallbacks for quests with no
   -- rewards section at all.
   -- QuestInfoRewardsFrame's own GetBottom() stops at the item row and
   -- "You will receive" line -- the XP / money / honor / talent-points
   -- rows sit BELOW it in their own widgets (confirmed live on Fallen:
   -- the divider landed exactly on the "Опыт: 975" line, i.e. one row of
   -- rewards content below where RewardsFrame's bottom reported). Include
   -- every reward sub-widget and take the lowest.
   -- QuestInfoSpacerFrame is Blizzard's own explicit end-of-content
   -- marker that QuestInfo_Display anchors last in every template
   -- (reward / log / detail) -- confirmed live on Fallen that its
   -- GetBottom() (~346) sits BELOW every individual reward widget
   -- (RewardsFrame ~406, XPFrame ~361, MoneyFrame ~378) i.e. it's the
   -- real bottom of the whole native block. Listed first so it wins; the
   -- rest stay as fallbacks for layouts where the spacer isn't shown.
   for _, widgetName in ipairs({
      "QuestInfoSpacerFrame", "QuestInfoRewardsFrame", "QuestInfoXPFrame", "QuestInfoMoneyFrame",
      "QuestInfoHonorFrame", "QuestInfoSkillPointFrame", "QuestInfoArenaPointsFrame",
      "QuestInfoItemReceiveText", "QuestInfoObjectivesText", "QuestInfoDescriptionText",
   }) do
      local widget = _G[widgetName];
      if (widget and widget:IsVisible() and widget.GetBottom) then
         local bottom = widget:GetBottom();
         if (bottom and (lowest == nil or bottom < lowest)) then
            lowest = bottom;
         end
      end
   end
   -- QuestInfoItemReceiveText is only the "You will receive:" LABEL -- the
   -- actual item icons/choice buttons (QuestInfoItem1..N, both fixed
   -- rewards and choosable ones share this same prefix per QuestInfo.lua)
   -- sit BELOW that label and were still getting overlapped by the
   -- translation even after anchoring to the label text (confirmed live
   -- via screenshot: reward item icons visible above the translation
   -- text). MAX_NUM_ITEMS in 3.3.5a's own QuestInfo.lua is well under 20.
   for i = 1, 20 do
      local widget = _G["QuestInfoItem" .. i];
      if (widget and widget:IsVisible() and widget.GetBottom) then
         local bottom = widget:GetBottom();
         if (bottom and (lowest == nil or bottom < lowest)) then
            lowest = bottom;
         end
      end
   end
   if (lowest ~= nil) then
      return lowest;
   end
   -- Fallback for anything QuestInfo_Display might show that isn't one of
   -- the three named widgets above (e.g. item-choice buttons with no
   -- accompanying text FontString) -- same generic region/child scan as
   -- before, kept only as a safety net so an unusual quest layout still
   -- gets SOME reasonable answer instead of nil.
   local regions = { scrollChild:GetRegions() };
   for _, region in ipairs(regions) do
      if (region ~= QCC_InlineDividersTop[scrollChild] and region ~= QCC_InlineDividers[scrollChild]
          and region ~= QCC_InlineTitles[scrollChild]
          and region ~= QCC_InlineBodies[scrollChild] and region ~= QCC_InlineComments[scrollChild]
          and region.IsVisible and region:IsVisible() and region.GetBottom) then
         local bottom = region:GetBottom();
         if (bottom and (lowest == nil or bottom < lowest)) then
            lowest = bottom;
         end
      end
   end
   local children = { scrollChild:GetChildren() };
   for _, child in ipairs(children) do
      if (child.IsVisible and child:IsVisible() and child.GetBottom) then
         local bottom = child:GetBottom();
         if (bottom and (lowest == nil or bottom < lowest)) then
            lowest = bottom;
         end
      end
   end
   return lowest;
end

-- Matches the native quest pane's own styling: a Morpheus-set title
-- (QuestTitleFont's own font, just re-pointed at the Cyrillic-capable
-- copy) followed by plain black body text (QuestFont's equivalent) --
-- see this addon's own screenshot-driven comparison against the native
-- enUS quest pane, which uses exactly this title/body font split, both
-- in solid black, no colored headers.
local function QCC_Inline_GetOrCreate(scrollChild, width)
   local dividerTop = QCC_InlineDividersTop[scrollChild];
   local title = QCC_InlineTitles[scrollChild];
   local body = QCC_InlineBodies[scrollChild];
   local divider = QCC_InlineDividers[scrollChild];
   local comments = QCC_InlineComments[scrollChild];
   if (dividerTop and title and body and divider and comments) then
      return dividerTop, title, body, divider, comments;
   end

   -- Layout is: dividerTop -> title -> body -> divider -> comments --
   -- checked against the real FrameXML (QuestLogFrame.xml/QuestFrame.xml
   -- both extracted and grepped directly): the native quest pane does NOT
   -- draw a UI-HorizontalBreak anywhere near the Rewards section or
   -- between quests at all (the only place that texture appears in
   -- either file is QuestGreetingFrameHorizontalBreak, part of the
   -- unrelated NPC gossip-greeting frame) -- an earlier version of this
   -- comment claimed otherwise from a misremembered screenshot, which was
   -- wrong; there is no native divider being duplicated here.
   dividerTop = scrollChild:CreateTexture(nil, "ARTWORK");
   dividerTop:SetTexture("Interface\\QuestFrame\\UI-HorizontalBreak");
   dividerTop:SetWidth(width);
   dividerTop:SetHeight(32);
   QCC_InlineDividersTop[scrollChild] = dividerTop;

   title = scrollChild:CreateFontString(nil, "ARTWORK");
   title:SetFont(QCC_RU_Font1, 18);
   title:SetTextColor(0, 0, 0);
   title:SetWidth(width);
   title:SetJustifyH("LEFT");
   title:SetJustifyV("TOP");
   QCC_InlineTitles[scrollChild] = title;

   -- Bumped 12 -> 14 (half a point up from the original size) plus
   -- SetSpacing to widen the line height by the same half-point -- the
   -- translation was reading visibly smaller/denser than the native
   -- English QuestFont body text right above it.
   body = scrollChild:CreateFontString(nil, "ARTWORK");
   body:SetFont(QCC_RU_Font2, 14);
   body:SetSpacing(0.5);
   body:SetTextColor(0, 0, 0);
   body:SetWidth(width);
   body:SetJustifyH("LEFT");
   body:SetJustifyV("TOP");
   QCC_InlineBodies[scrollChild] = body;

   divider = scrollChild:CreateTexture(nil, "ARTWORK");
   divider:SetTexture("Interface\\QuestFrame\\UI-HorizontalBreak");
   divider:SetWidth(width);
   divider:SetHeight(32);
   QCC_InlineDividers[scrollChild] = divider;

   comments = scrollChild:CreateFontString(nil, "ARTWORK");
   comments:SetFont(QCC_RU_Font2, 13);
   comments:SetSpacing(0.5);
   comments:SetTextColor(0, 0, 0);
   comments:SetWidth(width);
   comments:SetJustifyH("LEFT");
   comments:SetJustifyV("TOP");
   QCC_InlineComments[scrollChild] = comments;

   return dividerTop, title, body, divider, comments;
end

-- Hides whatever translation widgets already exist for `scrollChild`
-- WITHOUT creating them (a plain lookup, not QCC_Inline_GetOrCreate) --
-- called immediately when switching quests, before the deferred
-- QCC_Inline_Apply runs a frame later. Without this, the OLD quest's
-- translation stayed visible and on-screen for that one frame while the
-- native English text had already switched to the NEW quest underneath
-- it, which is what "overlapping text when clicking a different quest in
-- the list" turned out to be -- deferring the Apply call (to fix stale-
-- geometry reads) introduced exactly one frame where old-translation +
-- new-native-text were both on screen at once.
local function QCC_Inline_HideAll(scrollChild)
   local dividerTop = QCC_InlineDividersTop[scrollChild];
   local title = QCC_InlineTitles[scrollChild];
   local body = QCC_InlineBodies[scrollChild];
   local divider = QCC_InlineDividers[scrollChild];
   local comments = QCC_InlineComments[scrollChild];
   if (dividerTop) then dividerTop:Hide(); end
   if (title) then title:Hide(); end
   if (body) then body:Hide(); end
   if (divider) then divider:Hide(); end
   if (comments) then comments:Hide(); end
end

-- scrollChild -> its own native (Blizzard-set) height, captured the
-- FIRST time this addon ever touches it -- SetHeight only ever grew
-- scrollChild to fit a translated quest's extra text, never shrank it
-- back down afterward, so switching from a long translated quest to a
-- short/untranslated one left a large empty parchment gap below the
-- native text (confirmed live via screenshot). Restoring to this
-- remembered native height before each Apply call is what lets the
-- height correctly go back DOWN, not just up.
local QCC_NativeHeights = {};

-- Appends (or clears) the Russian translation block below whatever
-- Blizzard's own code just laid out in `scrollChild`, anchored to the
-- true current bottom (see QCC_FindContentBottom above), then grows
-- `scrollChild` itself so the shared scrollbar covers the added text.
local function QCC_Inline_Apply(scrollChild, strID, anchorWidth)
   local dividerTop, title, body, divider, comments = QCC_Inline_GetOrCreate(scrollChild, anchorWidth);

   if (QCC_NativeHeights[scrollChild] == nil) then
      QCC_NativeHeights[scrollChild] = scrollChild:GetHeight();
   end
   scrollChild:SetHeight(QCC_NativeHeights[scrollChild]);

   if (strID == nil or strID == "0") then
      dividerTop:Hide();
      title:Hide();
      body:Hide();
      divider:Hide();
      comments:Hide();
      return;
   end

   local enComments    = QCC_GetQuestData(strID, "Comments");
   -- On a ruRU client the quest's own Title/Description/Objectives/
   -- Progress/Completion are already shown natively in Russian by the
   -- base game -- re-adding them here would just duplicate what's
   -- already on screen. Only the comment-derived verdict (genuinely new
   -- information no locale's base game provides) is worth showing there,
   -- so these fields are never even read on a ruRU client.
   local ruTitle, ruDescription, ruObjectives, ruProgress, ruCompletion;
   if (not QCC_IsRuClient) then
      ruTitle       = QCC_GetQuestData(strID, "Title");
      ruDescription = QCC_GetQuestData(strID, "Description");
      ruObjectives  = QCC_GetQuestData(strID, "Objectives");
      ruProgress    = QCC_GetQuestData(strID, "Progress");
      ruCompletion  = QCC_GetQuestData(strID, "Completion");
   end

   local hasTranslation = not QCC_IsRuClient and (ruTitle ~= nil or ruDescription ~= nil or ruObjectives ~= nil);
   if (not hasTranslation and (enComments == nil or strlen(enComments) == 0)) then
      dividerTop:Hide();
      title:Hide();
      body:Hide();
      divider:Hide();
      comments:Hide();
      return;
   end

   -- Every field's raw text stores real line breaks as the literal marker
   -- NEW_LINE (both the Objectives/Description/etc scraped from Wowhead
   -- and the Comments field use this same convention) -- QCC_ExpandRuMacros
   -- only ever handled $B, never this marker, so every field except
   -- Comments (which had its own separate, correct gsub) rendered with
   -- NEW_LINE literally printed instead of an actual line break.
   -- Section labels (Цели/Прогресс/Завершение) stay pure black (the
   -- FontString's own SetTextColor below) -- only the actual translated
   -- body text is wrapped in this slightly-lighter dark gray, matching
   -- how the native English QuestFont text sits a shade lighter than a
   -- pure-black heading like Rewards/Description.
   local QCC_BODY_TEXT_COLOR = "|cff141414";
   local function QCC_ColorBodyText(text)
      return QCC_BODY_TEXT_COLOR .. text .. "|r";
   end

   local parts = {};
   if (ruDescription and strlen(ruDescription) > 0) then
      table.insert(parts, QCC_ColorBodyText(QCC_ExpandRuMacros(ruDescription)));
   end
   if (ruObjectives and strlen(ruObjectives) > 0) then
      table.insert(parts, "Цели:\n" .. QCC_ColorBodyText(QCC_ExpandRuMacros(ruObjectives)));
   end
   if (ruProgress and strlen(ruProgress) > 0) then
      table.insert(parts, "Прогресс:\n" .. QCC_ColorBodyText(QCC_ExpandRuMacros(ruProgress)));
   end
   if (ruCompletion and strlen(ruCompletion) > 0) then
      table.insert(parts, "Завершение:\n" .. QCC_ColorBodyText(QCC_ExpandRuMacros(ruCompletion)));
   end

   -- Comments are NOT run through QCC_ExpandRuMacros (they're
   -- player-written Wowhead comments, not this addon's own Russian quest
   -- text, so the $N/$C/|3-N(...)/<имя>/<X/Y> macro grammar doesn't apply
   -- to them) -- just the same NEW_LINE expansion, plus stripping
   -- Wowhead's own BBCode markup ([url=...]text[/url], [b]/[/b], etc)
   -- which otherwise showed up literally in-game. No "Комментарии:"
   -- heading and no divider above them if there's nothing to show.
   local cleanComments = "";
   if (enComments and strlen(enComments) > 0) then
      -- NEW_PARA marks the boundary BETWEEN separate comments, expanded to
      -- a blank line (same as a paragraph break) -- NEW_LINE marks line
      -- breaks WITHIN a single comment's own text and must expand
      -- separately, so a long multi-paragraph comment keeps its own
      -- internal formatting intact rather than being flattened.
      cleanComments = string.gsub(enComments, "NEW_PARA", "\n\n");
      cleanComments = string.gsub(cleanComments, "NEW_LINE", "\n");
      cleanComments = string.gsub(cleanComments, "%[url=[^%]]*%]", "");
      cleanComments = string.gsub(cleanComments, "%[/url%]", "");
      cleanComments = string.gsub(cleanComments, "%[/?[bi]%]", "");
   end

   -- dividerTop separates the native quest text from the addon block.
   -- Preferred anchor: QuestInfoSpacerFrame, Blizzard's OWN explicit
   -- end-of-content marker that QuestInfo_Display always places last in
   -- every template -- anchoring directly to its BOTTOM is exact and
   -- needs no geometry math. This replaced an earlier approach that
   -- computed an offset from scrollChild:GetTop() minus
   -- QCC_FindContentBottom() -- on a custom client (Fallen) that math
   -- kept landing the divider ON the rewards/XP rows because the
   -- individual reward widgets it scanned reported inconsistent
   -- IsShown()/IsVisible()/GetBottom(). QCC_FindContentBottom stays as
   -- the fallback for the (rare) case the spacer isn't shown.
   -- Y position comes from the spacer (or the computed content bottom),
   -- but X is ALWAYS pinned to scrollChild's own left edge -- anchoring
   -- dividerTop's X to QuestInfoSpacerFrame:BOTTOM (a CENTER point on a
   -- full-width frame) pushed the whole addon block far to the left,
   -- half off the window (confirmed live on Fallen). Compute the Y
   -- offset from scrollChild:GetTop() either way so the SetPoint anchor
   -- can stay scrollChild-relative.
   local top = scrollChild:GetTop();
   local contentBottom;
   if (QuestInfoSpacerFrame and QuestInfoSpacerFrame:IsVisible() and QuestInfoSpacerFrame:GetBottom()) then
      contentBottom = QuestInfoSpacerFrame:GetBottom();
   else
      contentBottom = QCC_FindContentBottom(scrollChild);
   end
   local offsetBelowContent;
   if (contentBottom and top) then
      offsetBelowContent = -(top - contentBottom) - 6;
   else
      offsetBelowContent = -6;
   end

   dividerTop:ClearAllPoints();
   dividerTop:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, offsetBelowContent);
   dividerTop:Show();

   if (hasTranslation) then
      title:ClearAllPoints();
      title:SetPoint("TOP", dividerTop, "BOTTOM", 0, -8);
      title:SetText((ruTitle and strlen(ruTitle) > 0) and QCC_ExpandRuMacros(ruTitle) or "");
      title:Show();

      body:ClearAllPoints();
      body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8);
      body:SetText(table.concat(parts, "\n\n"));
      body:Show();
   else
      title:Hide();
      body:Hide();
   end

   if (strlen(cleanComments) > 0) then
      -- On a ruRU client there's no translation block between dividerTop
      -- and the comments, so a SECOND divider right below the first one
      -- (with nothing in between) just renders as two stacked venzels --
      -- reuse dividerTop as the single separator there and hide `divider`
      -- entirely. On a non-ruRU client the translation title+body sit
      -- between the two, so both dividers are meaningful.
      if (hasTranslation) then
         divider:ClearAllPoints();
         divider:SetPoint("TOP", body, "BOTTOM", 0, -6);
         divider:Show();
         comments:ClearAllPoints();
         comments:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -8);
      else
         divider:Hide();
         comments:ClearAllPoints();
         comments:SetPoint("TOPLEFT", dividerTop, "BOTTOMLEFT", 0, -8);
      end

      -- Trailing "\n" gives the comments block a blank line of breathing
      -- room at the very bottom, same as the leading "\n" already used
      -- for the title -- otherwise the last comment's text sat flush
      -- against the bottom edge with no visual padding at all.
      comments:SetText(cleanComments .. "\n");
      comments:Show();
   else
      divider:Hide();
      comments:Hide();
   end

   -- Resize the scroll child to exactly fit the translation so the
   -- shared native scrollbar reaches it -- same trick Blizzard's own
   -- QuestLogSpacerFrame plays for its own dynamic content height.
   -- Always SET (not just grow) the height against the remembered native
   -- height as the floor -- growing-only left a large empty parchment gap
   -- after the comments once a shorter quest replaced a longer one that
   -- HAD grown the scroll child (confirmed live via screenshot).
   -- lastWidget is the last VISIBLE addon text: comments if shown, else
   -- body -- but on a ruRU client with no comment verdict, body is
   -- hidden too and GetTop() would be nil, so guard on IsShown() and
   -- just restore the native height in that case (nothing was added).
   local lastWidget = (strlen(cleanComments) > 0) and comments or body;
   local nativeHeight = QCC_NativeHeights[scrollChild];
   if (lastWidget:IsShown() and lastWidget:GetTop()) then
      local lastBottom = lastWidget:GetTop() - lastWidget:GetStringHeight();
      local neededHeight = (top - lastBottom) + 20;
      scrollChild:SetHeight(math.max(nativeHeight, neededHeight));
   else
      scrollChild:SetHeight(nativeHeight);
   end
end

-- Refreshes the QuestLogFrame's inline translation from whatever's
-- currently selected in the quest log.
local function QCC_Inline_RefreshQuestLog()
   local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(GetQuestLogSelection());
   local strID = (questTitle and questID and questID ~= 0) and tostring(questID) or nil;
   QCC_Inline_Apply(QuestLogDetailScrollChildFrame, strID, QuestLogDetailScrollChildFrame:GetWidth() - 10);
end

-- 3.3.5a's API has no GetQuestID() (that's a later-client addition) --
-- the only way to identify which quest QuestFrame is currently showing
-- is to match its title text against the player's own quest log, same
-- approach the original QuestTradutor:GetQuestID used. Matching by exact
-- title text can theoretically collide if two different quests happen to
-- share an identical title, but that's an extremely rare edge case for a
-- convenience translation overlay, not something worth a heavier lookup
-- for.
--
-- The quest log scan alone only ever finds ALREADY-ACCEPTED quests --
-- confirmed live: QUEST_DETAIL (a quest being OFFERED, before the player
-- has accepted it) fires while the quest doesn't exist in the log yet at
-- all, so GetQuestLogTitle never matches and the questgiver modal never
-- got a translation. QCC_QuestTitlesEN (QuestTitles_EN.lua, an
-- English-title -> id table built from QuestieDB's own data) is the
-- fallback for exactly that case.
local function QCC_FindQuestIDByTitle(title)
   if (title == nil or title == "") then
      return nil;
   end
   local numEntries = GetNumQuestLogEntries();
   for i = 1, numEntries do
      local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(i);
      if (not isHeader and questTitle == title and questID and questID ~= 0) then
         return questID;
      end
   end
   if (QCC_QuestTitlesEN) then
      local questID = QCC_QuestTitlesEN[title];
      if (questID and questID ~= 0) then
         return questID;
      end
   end
   return nil;
end

-- Refreshes the QuestFrame (NPC dialogue) inline translation.
local function QCC_Inline_RefreshQuestFrame()
   local strID = nil;
   if (QuestFrame:IsShown()) then
      local questID = QCC_FindQuestIDByTitle(GetTitleText());
      if (questID and questID ~= 0) then
         strID = tostring(questID);
      end
   end
   QCC_Inline_Apply(QuestDetailScrollChildFrame, strID, QuestDetailScrollChildFrame:GetWidth() - 10);
end

--------------------------------------------------------------------------
-- Event wiring -- only what's needed to refresh the two inline blocks
-- above. No gossip events, no chat output, no other addon's frames.
--------------------------------------------------------------------------

-- 3.3.5a has no C_Timer -- this is the standard classic-API pattern for
-- "run this once, one frame from now": an invisible driver frame whose
-- OnUpdate fires on the very next frame no matter what, then disarms
-- itself. Used to defer QCC_Inline_Apply until AFTER Blizzard's own
-- FontStrings have actually settled their real height/position --
-- SetText() does not make GetBottom()/GetStringHeight() reflect the new
-- text until the NEXT frame, so calling QCC_FindContentBottom in the same
-- frame as QuestLog_UpdateQuestDetails read stale geometry. This was
-- confirmed live to matter specifically on a quest log RE-open within the
-- same session: hooking QuestLog_UpdateQuestDetails directly (no defer)
-- fixed the very first open but made every subsequent reopen render the
-- translation overlapping the native English text, because
-- QuestLog_UpdateQuestDetails can itself run more than once while the
-- frame settles (e.g. once for the previous quest's leftover state, once
-- for the new selection) and only the LAST of those calls should trigger
-- our own layout pass -- deferring by a frame collapses any such burst
-- into a single, correctly-timed refresh.
local QCC_DeferFrame = CreateFrame("Frame");
local QCC_PendingRefresh = nil;
QCC_DeferFrame:Hide();
QCC_DeferFrame:SetScript("OnUpdate", function()
   QCC_DeferFrame:Hide();
   local refreshFn = QCC_PendingRefresh;
   QCC_PendingRefresh = nil;
   if (refreshFn) then
      refreshFn();
   end
end);

local function QCC_DeferredRefresh(refreshFn)
   QCC_PendingRefresh = refreshFn;
   QCC_DeferFrame:Show();
end

-- NOT gated on QuestLogFrame:IsShown() -- confirmed live that opening
-- quest details via a WatchFrame (tracker) click still fires
-- QuestLog_UpdateQuestDetails, but QuestLogFrame:IsShown() reads nil at
-- that point even though a "Quest Details" panel is genuinely on screen
-- (pressing L to open the full quest log instead DOES report IsShown()
-- true) -- some code path opens quest details without going through
-- QuestLogFrame:Show() first, or the frame's shown-state hasn't updated
-- yet when this hook fires. QuestLog_UpdateQuestDetails itself is only
-- ever called by Blizzard's own code when a details view is genuinely
-- about to render, so gating on it at all was redundant caution, not a
-- real requirement.
hooksecurefunc("QuestLog_UpdateQuestDetails", function()
   QCC_Inline_HideAll(QuestLogDetailScrollChildFrame);
   QCC_DeferredRefresh(QCC_Inline_RefreshQuestLog);
end);

local QCC_EventFrame = CreateFrame("Frame");
QCC_EventFrame:RegisterEvent("QUEST_DETAIL");
QCC_EventFrame:RegisterEvent("QUEST_PROGRESS");
QCC_EventFrame:RegisterEvent("QUEST_COMPLETE");
QCC_EventFrame:SetScript("OnEvent", function()
   QCC_Inline_HideAll(QuestDetailScrollChildFrame);
   QCC_DeferredRefresh(QCC_Inline_RefreshQuestFrame);
end);

QuestFrame:HookScript("OnHide", function()
   QCC_Inline_HideAll(QuestDetailScrollChildFrame);
end);
