local ADDON, ns = ...

function ns.Print(msg)
  print("|cff33ccffWhereabouts:|r " .. tostring(msg))
end

function ns.IsEnabled()
  return ns.Options.Get("enabled") == true
end

local function refreshUI()
  ns.Config.Refresh()
  ns.MinimapButton.Refresh()
  ns.MapToggle.Refresh()
end

-- Single place that decides whether we should be live right now.
local function sync()
  if ns.IsEnabled() and IsInGuild() and not IsInInstance() then
    ns.Comms.Start()
    ns.Classes.Start()
  else
    ns.Comms.Stop(false) -- no OFF: either already opted out, or sends may be blocked
    ns.Classes.Stop()
    ns.Roster.Clear()
    ns.Pins.Clear()
  end
  refreshUI()
end

function ns.Enable()
  ns.Options.Set("enabled", true)
  sync()
end

function ns.Disable()
  ns.Options.Set("enabled", false)
  ns.Comms.Stop(true)
  ns.Roster.Clear()
  ns.Pins.Clear()
  refreshUI()
end

local function status()
  ns.Print(format("sharing %s | active %s | in guild %s | peers %d",
    ns.IsEnabled() and "ON" or "OFF", tostring(ns.Comms.IsRunning()),
    tostring(IsInGuild() and true or false), ns.Roster.Count()))
  if ns.IsEnabled() and IsInInstance() then ns.Print("paused: inside an instance") end
end

local function flip(key) ns.Options.Set(key, not ns.Options.Get(key)) end

local commands = {
  [""] = function() ns.Config.Open() end,
  config = function() ns.Config.Open() end,
  on = function() ns.Enable() status() end,
  off = function() ns.Disable() status() end,
  status = status,
  version = function() ns.Print("version " .. ns.Version.current) ns.Print(ns.Version.Message() or "no newer version seen") end,
  names = function() flip("labels") end,
  map = function() flip("mapButton") end,
  minimap = function() flip("minimapButton") end,
  reset = function() ns.Options.Reset() ns.Print("appearance reset to defaults") end,
  probe = function() ns.Comms.Probe() end,
  debug = function() ns.Debug.Dump() end,
  testpin = function()
    ns.Print("test pin " .. (ns.Pins.ToggleTest() and "ON: open the map, look at its centre" or "off"))
  end,
}

SLASH_WHEREABOUTS1 = "/whereabouts"
SlashCmdList["WHEREABOUTS"] = function(msg)
  local run = commands[strlower(strtrim(msg or ""))]
  if run then
    run()
  else
    ns.Print("/whereabouts (settings) | on | off | status | version | names | map | minimap | reset | probe | debug | testpin")
  end
end

-- Option changes take effect immediately, wherever they were made.
local function onOption(key)
  if key == "minimapButton" then ns.MinimapButton.Refresh()
  elseif key == "mapButton" then ns.MapToggle.Refresh()
  elseif key == "enabled" then refreshUI()
  else ns.Pins.Restyle() end -- theme, size, alpha, labels
  ns.Config.Refresh()
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 ~= ADDON then return end
    ns.Options.Init()
    ns.Options.Subscribe(onOption)
    ns.Roster.onChange = ns.Pins.Refresh
    ns.Classes.onChange = ns.Pins.Refresh
    self:UnregisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_LOGIN") -- build the minimap button here, as QuestlineJournal does
    self:RegisterEvent("PLAYER_ENTERING_WORLD") -- fires on instance transitions too
    self:RegisterEvent("PLAYER_GUILD_UPDATE")
  else
    ns.Config.Init()
    ns.MinimapButton.Init()
    sync()
  end
end)
