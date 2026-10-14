-- The minimap button uses LibDBIcon when present, and the plain button when not.
local S = dofile("tests/stubs.lua")
local function boot(withLib)
  S.install()
  _G.print = function() end
  _G.LibStub, _G.WhereaboutsMinimapButton = nil, nil
  local rec = { shown = nil }
  if withLib then
    local button = S.frame("Button", nil, _G.Minimap)
    button.icon = S.frame("Texture", nil, button)
    local dbi = {
      Register = function(_, name, obj, db) rec.name, rec.obj, rec.db = name, obj, db end,
      GetMinimapButton = function() return button end,
      Show = function(_, name) rec.shown = name end,
      Hide = function() rec.shown = false end,
    }
    local ldb = { NewDataObject = function(_, name, o) o.name = name return o end, GetDataObjectByName = function() return nil end }
    _G.LibStub = function(name) return name == "LibDBIcon-1.0" and dbi or name == "LibDataBroker-1.1" and ldb or nil end
    rec.button = button
  end
  S.map(1429, 0.7)
  local ns = S.ns(); ns.IsEnabled = nil
  S.loadAll(ns)
  local core = S.frameWithEvent("ADDON_LOADED")
  core.scripts.OnEvent(core, "ADDON_LOADED", "Whereabouts")
  return ns, core, rec
end

-- With the libraries
WhereaboutsDB = nil
local ns, core, rec = boot(true)
WhereaboutsDB.minimapAngle = nil
core.scripts.OnEvent(core, "PLAYER_LOGIN")
assert(rec.name == "Whereabouts" and rec.obj.type == "launcher", "registered with LibDBIcon")
assert(rec.db == WhereaboutsDB.minimap and rec.db.minimapPos == 225 and rec.db.hide == false)
assert(ns.MinimapButton.UsingLibrary() and WhereaboutsMinimapButton == nil, "no plain button when the library is there")
assert(rec.shown == "Whereabouts")
rec.obj.OnClick(nil, "LeftButton"); assert(ns.IsEnabled(), "left-click turns sharing on")
rec.obj.OnClick(nil, "LeftButton"); assert(not ns.IsEnabled(), "and off")
local lines = {}
rec.obj.OnTooltipShow({ SetText = function(_, t) lines[#lines + 1] = t end, AddLine = function(_, t) lines[#lines + 1] = t end })
assert(lines[1]:find("^Whereabouts") and #lines >= 4, "tooltip filled")
ns.Options.Set("minimapButton", false); assert(rec.shown == false and rec.db.hide == true, "option hides it")
ns.Options.Set("minimapButton", true); assert(rec.shown == "Whereabouts" and rec.db.hide == false)

-- An angle saved by the plain button (radians) carries over, in degrees
ns, core, rec = boot(true)
WhereaboutsDB.minimapAngle = math.rad(90)
core.scripts.OnEvent(core, "PLAYER_LOGIN")
assert(math.abs(rec.db.minimapPos - 90) < 0.001, "angle migrated: " .. tostring(rec.db.minimapPos))

-- Without the libraries: the plain button, as before
WhereaboutsDB = nil
ns, core = boot(false)
core.scripts.OnEvent(core, "PLAYER_LOGIN")
assert(not ns.MinimapButton.UsingLibrary() and WhereaboutsMinimapButton, "plain button used")
assert(WhereaboutsMinimapButton.shown == true)
ns.Options.Set("minimapButton", false); assert(WhereaboutsMinimapButton.shown == false)
