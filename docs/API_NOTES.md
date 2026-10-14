# API notes (verified facts only, one line each)
Status key: GAME = confirmed in game by the maintainer. DOC = from published docs or third-party reports (the source of the fact).
The maintainer play-tests every release; an entry moves to GAME when that specific API is confirmed.

- DOC: Forever beta TOC interface is 16001 (warcraft.wiki.gg/wiki/TOC_format; also several shipping addons).
- DOC: Forever loads `_Camelot.toc` and `_Mainline.toc` variants; a plain `.toc` with 16001 is what this addon uses. GAME: it loads from a single unsuffixed `.toc`.
- DOC: Lua 5.1 (wowforeverguides.com addon prompts page).
- DOC: `C_ChatInfo.SendAddonMessage` returns `Enum.SendAddonMessageResult`; take the last return via `select(-1, ...)` (wiki: API_C_ChatInfo.SendAddonMessage, Patch 10.2.7 API changes).
- DOC: Enum gained `AddOnMessageLockdown` and `TargetOffline` in 12.0.0 (same wiki page).
- DOC: Per-prefix throttle; exceeding it returns `AddonMessageThrottle` (same wiki page).
- DOC: `RegisterAddonMessagePrefix` returns `Enum.RegisterAddonMessagePrefixResult` on Forever build 1.60.1.69913 (Brattlof/Firekeeper PR #6).
- DOC: Midnight blocks SendAddonMessage inside instances (third-party API summaries, not Blizzard text). Forever status: UNVERIFIED.
- DOC: Prefix max 16 chars, message max 255 chars.
- DOC: third-party kit reports SavedVariables do not persist between launches on the Forever beta (Thunderz96/forever-addon-kit). UNVERIFIED by me; harmless here since sharing defaults to off.
- UNVERIFIED: `issecretvalue` global exists on Forever (Midnight feature); code guards on its existence.
- GAME: `WorldMapFrame:GetCanvas()` exists on Forever (`/whereabouts debug`: GetCanvas true).
- DOC: `OnMapChanged`, `OnCanvasScaleChanged` exist on Forever (hooks are guarded by a type check).
- UNVERIFIED: `BasicFrameTemplateWithInset`, `UICheckButtonTemplate` exist on Forever (Config falls back to a plain panel only for the first).
- UNVERIFIED: `AddonCompartmentFrame:RegisterAddon` exists on Forever (Config skips it if absent).
- GAME: `WorldMapFrame.ScrollContainer` exists on Forever (`/whereabouts debug`: ScrollContainer true; the world-map button attached to it).
- UNVERIFIED: `Minimap` frame, `GetCursorPosition`, and textures `Interface\\Minimap\\MiniMap-TrackingBorder` / `UI-Minimap-Background` / `UI-Minimap-ZoomButton-Highlight` exist on Forever.
- UNVERIFIED: `Interface\\Icons\\INV_Misc_Map_01` exists on Forever.
- REPORTED BY USER (not tested by me): QuestlineJournal's named, library-free Button child of `Minimap` works with HidingBar on Forever; Whereabouts' button now follows that pattern.
- GAME: pins parented to the map canvas were mostly covered by Blizzard's map art; pins on their own high-level overlay (frame level 5000, clipped to the scroll area) are visible. Confirmed by the maintainer.
- DOC (unverified on Forever): `C_Map.GetMapRectOnMap(uiMapID, topUiMapID)` returns minX, maxX, minY, maxY (warcraft.wiki.gg API list); behaviour for unrelated maps is undocumented, so Project.lua checks ancestry first and sanity-checks the rect.
- UNVERIFIED: `GetNumGuildMembers`, `GetGuildRosterInfo` (class token is the 11th return), `C_GuildInfo.GuildRoster`, `GUILD_ROSTER_UPDATE`, global `CLASS_ICON_TCOORDS`, texture `Interface\\WorldStateFrame\\Icons-Classes` exist on Forever.
- DOC (archived summaries, not a current Forever copy): Blizzard UI Add-On Development Policy: free, visible code, must not negatively impact realms or other players, no ads or in-game donation requests, must follow ToU/EULA, Blizzard may disable functionality. No explicit rule about location sharing found.
- DOC: Settings category API (10.0+): `Settings.RegisterCanvasLayoutCategory(frame, name)`, `Settings.RegisterAddOnCategory(category)`, `Settings.OpenToCategory(category:GetID())` (warcraft.wiki.gg "Creating a settings menu", Patch 11.0.2 API changes). Forever: UNVERIFIED. Config.lua falls back to a stock window.
- DOC: `InterfaceOptions_AddCategory` was deprecated in 10.0.0; not used here.
- DOC: Bindings.xml: `<Binding name header runOnUp>` with `keystate` "down"/"up"; header token resolves via `BINDING_HEADER_<token>`, name via `BINDING_NAME_<name>` (warcraft.wiki.gg "Creating key bindings"). `category="ADDONS"` is what other addons use to appear under AddOns. Forever: UNVERIFIED.
- UNVERIFIED on Forever: `C_AddOns.GetAddOnMetadata` (code falls back to `GetAddOnMetadata`, then "0.0.0"), `UIPanelButtonTemplate`, `UICheckButtonTemplate`, `InputBoxTemplate`, `FontString:SetShown`.
- DESIGN NOTE: addons cannot make web requests, so the update check is a version announcement between guildmates, not a lookup.
- REPORTED (third party, verified in game by them 2026-10-02): Forever 1.60.1 loads `<Addon>_Camelot.toc` ahead of an unsuffixed TOC, and ignores `_Forever.toc` (lxhwes/GuildCrafts-Forever PR #1). Whereabouts ships one unsuffixed `.toc`; the user's own testing shows it loads.
- DOC: `C_Minimap.GetViewRadius()` returns a number in yards; on Forever 1.60.1 (warcraft.wiki.gg/wiki/API_C_Minimap.GetViewRadius). The page does not say radius or diameter; MiniView treats it as the radius. GAME: unconfirmed, check that pins reach the minimap edge at the right distance.
- DOC: `C_Map.GetWorldPosFromMapPos(uiMapID, vector2)` returns `continentID, worldPosition` (warcraft.wiki.gg). Units are not stated; MiniView measures a map's size from its (0,0) and (1,1) corners and assumes world x runs north and y runs west, so width is the change in y. If the pins are stretched the wrong way, this is the line to swap.
- UNVERIFIED on Forever: `CreateVector2D`, `GetPlayerFacing` (radians counter-clockwise from north, from other addons), CVar `rotateMinimap`. MiniView reads each through `_G` and hides the pins if one is missing.
- DOC: LibDBIcon-1.0 `Register(name, dataObject, db)`, `GetMinimapButton(name)`, `Show(name)`, `Hide(name)`; `db` is a saved table with `hide` and `minimapPos` (degrees). Needs LibStub, CallbackHandler-1.0 and LibDataBroker-1.1. Whereabouts reads `LibStub` through `_G` and falls back to MinimapCustom.lua when any are missing.
- DESIGN NOTE: fast mode sends at most one message per 2 seconds per client, against a 5 second normal tick. The per-prefix throttle was not measured; the send path already backs off on a throttle result.

