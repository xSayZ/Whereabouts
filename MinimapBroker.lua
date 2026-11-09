local ADDON, ns = ...
local Broker = {}
ns.MinimapBroker = Broker

-- Uses LibDataBroker + LibDBIcon only when another addon already loaded them (we ship no library code).
-- Button collectors such as Leatrix Plus then show our icon, tooltip and on/off tint instead of a stand-in.
local NAME, ICON = "Whereabouts", "Interface\\Icons\\INV_Misc_Map_01"
local obj, dbi

local function lib(name)
  return LibStub and LibStub(name, true) -- a table with __call in game
end

-- Returns true when the button now lives in LibDBIcon; false means build our own.
function Broker.Init(click, fillTooltip)
  local ldb
  ldb, dbi = lib("LibDataBroker-1.1"), lib("LibDBIcon-1.0")
  if not ldb or not dbi or type(WhereaboutsDB) ~= "table" then return false end
  obj = ldb:NewDataObject(NAME, {
    type = "launcher", label = NAME, icon = ICON,
    OnClick = click,
    OnTooltipShow = fillTooltip,
  })
  if not obj then return false end -- name already taken by something else
  if type(WhereaboutsDB.minimapIcon) ~= "table" then WhereaboutsDB.minimapIcon = {} end
  if not pcall(dbi.Register, dbi, NAME, obj, WhereaboutsDB.minimapIcon) then obj = nil return false end
  return true
end

function Broker.Active() return obj ~= nil end

-- Green tint while sharing, red while off; the library button has no room for ON/OFF text.
function Broker.Refresh(on, shown)
  if not obj then return end
  obj.text = on and "ON" or "OFF"
  obj.iconR, obj.iconG, obj.iconB = on and 0.6 or 1, on and 1 or 0.35, on and 0.6 or 0.35
  WhereaboutsDB.minimapIcon.hide = not shown
  if shown then dbi:Show(NAME) else dbi:Hide(NAME) end
end
