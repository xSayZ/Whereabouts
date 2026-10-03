-- Drives the real Core through its events and slash commands, with the whole TOC loaded.
local S = dofile("tests/stubs.lua")

local function boot(withSettings)
  S.install()
  _G.print = function(...) S.printed[#S.printed + 1] = table.concat({ ... }, " ") end -- Core's ns.Print uses print
  S.roster = { { "Cnas Ohlson-Realm", "WARRIOR" } }
  local opened, registered
  if withSettings then
    _G.Settings = {
      RegisterCanvasLayoutCategory = function(panel, name) return { panel = panel, name = name, GetID = function() return 7 end } end,
      RegisterAddOnCategory = function(c) registered = c end,
      OpenToCategory = function(id) opened = id end,
    }
  end
  S.map(1429, 0.7)
  local ns = S.ns(); ns.IsEnabled = nil -- Core defines the real one
  S.loadAll(ns)
  local core = S.frameWithEvent("ADDON_LOADED")
  core.scripts.OnEvent(core, "ADDON_LOADED", "SomeOtherAddon")
  assert(WhereaboutsDB == nil, "must ignore other addons loading")
  core.scripts.OnEvent(core, "ADDON_LOADED", "Whereabouts")
  return ns, core, function() return opened, registered end
end
local function slash(cmd) SlashCmdList.WHEREABOUTS(cmd) end

----- With the game's Settings panel -----
local ns, core, state = boot(true)
assert(WhereaboutsDB.enabled == false and WhereaboutsDB.mapButton == false, "off by default, map button off by default")
core.scripts.OnEvent(core, "PLAYER_LOGIN")
local _, registered = state()
assert(registered and registered.name == "Whereabouts", "settings category registered under AddOns")
assert(WhereaboutsMinimapButton and WhereaboutsMinimapButton.parent == _G.Minimap, "named minimap button")
assert(WhereaboutsMinimapButton.shown == true)
assert(ns.Comms.IsRunning() == false and #S.sent == 0, "nothing sent until the player opts in")

local function mapButtons()
  local n = 0
  for _, f in ipairs(S.frames) do if f.kind == "Button" and f.parent == _G.WorldMapFrame and f.w == 140 then n = n + 1 end end
  return n
end
assert(mapButtons() == 0, "the world-map On/Off button must not exist by default")
slash("map"); assert(mapButtons() == 1 and WhereaboutsDB.mapButton == true, "optional map button appears when enabled")
slash("map"); assert(WhereaboutsDB.mapButton == false)

slash("")
assert(select(1, state()) == 7, "bare /whereabouts opens the Settings category")

-- Sharing on/off, and the minimap label follows it
slash("on")
assert(WhereaboutsDB.enabled and ns.Comms.IsRunning() and #S.sent >= 1, "on starts sharing")
local label
for _, f in ipairs(S.frames) do if f.kind == "FontString" and f.text == "ON" then label = f end end
assert(label and label.tcolor[2] == 1 and label.tcolor[1] < 0.5, "ON is green")
slash("off")
assert(S.sent[#S.sent].msg == "1|OFF" and not ns.Comms.IsRunning(), "off sends one stop message")
assert(label.text == "OFF" and label.tcolor[1] == 1 and label.tcolor[2] < 0.5, "OFF is red")

-- Options through commands
slash("names"); assert(WhereaboutsDB.labels == false); slash("names"); assert(WhereaboutsDB.labels == true)
slash("minimap"); assert(WhereaboutsMinimapButton.shown == false); slash("minimap"); assert(WhereaboutsMinimapButton.shown == true)
ns.Options.Set("theme", "solid"); ns.Options.Set("size", 1.5)
slash("reset"); assert(WhereaboutsDB.theme == "classic" and WhereaboutsDB.size == 1.0)
slash("version"); assert(S.printed[#S.printed - 1]:find("version " .. S.tocVersion, 1, true))
slash("nonsense"); assert(S.printed[#S.printed]:find("/whereabouts"))

-- Leaving for an instance stops everything and clears the roster
slash("on"); ns.Roster.Update("Cnas Ohlson-Realm", 1429, 5, 5)
S.inInstance = true; core.scripts.OnEvent(core, "PLAYER_ENTERING_WORLD")
assert(not ns.Comms.IsRunning() and ns.Roster.Count() == 0, "instance: stopped and cleared")
S.inInstance = false; core.scripts.OnEvent(core, "PLAYER_ENTERING_WORLD")
assert(ns.Comms.IsRunning(), "and resumed afterwards")

-- The update notice reaches the settings panel and the minimap tooltip
ns.Version.Note("99.0.0")
local shown
for _, f in ipairs(S.frames) do if f.text and f.text:find("Update available: 99.0.0", 1, true) then shown = f end end
assert(shown, "settings panel shows the update line")
assert(S.printed[#S.printed]:find("99.0.0"), "chat message")

-- Key binding: global function and labels the game needs
assert(type(WhereaboutsHideNamesKey) == "function" and BINDING_NAME_WHEREABOUTS_HIDE_NAMES and BINDING_HEADER_WHEREABOUTS)
WhereaboutsHideNamesKey("down"); WhereaboutsHideNamesKey("up")

----- Without the Settings API: falls back to the stock window -----
ns, core = boot(false)
core.scripts.OnEvent(core, "PLAYER_LOGIN")
slash("")
local win
for _, f in ipairs(S.frames) do if f.template == "BasicFrameTemplateWithInset" then win = f end end
assert(win and win.shown, "fallback window opens")
slash(""); assert(win.shown == false, "and toggles closed")
