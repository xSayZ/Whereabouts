local ADDON, ns = ...
local Panel = {}
ns.Panel = Panel

local W, O = ns.Widgets, ns.Options

local function pct(v) return format("%d%%", v * 100 + 0.5) end

local function stepper(key)
  local step = ns.Ranges[key][3]
  return function(dir) O.Set(key, O.Get(key) + dir * step) end
end

local function text(parent, font, x, y, w)
  local fs = parent:CreateFontString(nil, "OVERLAY", font)
  fs:SetPoint("TOPLEFT", x, y)
  fs:SetJustifyH("LEFT")
  if w then fs:SetWidth(w) end
  return fs
end

-- Builds every control into `parent`; returns a function that refreshes them from the current options.
function Panel.Build(parent)
  local rows, y = {}, -40
  local function add(r, gap)
    r:SetPoint("TOPLEFT", 14, y)
    y = y - (gap or 30)
    rows[#rows + 1] = r
  end
  text(parent, "GameFontNormalLarge", 16, -12):SetText("Whereabouts " .. ns.Version.current)

  add(W.Check(parent, "Share my location with my guild", ns.IsEnabled,
    function(v) if v then ns.Enable() else ns.Disable() end end))
  add(W.Cycle(parent, "Theme", function() return ns.Themes.Get(O.Get("theme")).name end,
    function() O.Set("theme", ns.Themes.Next(O.Get("theme"))) end))
  add(W.Step(parent, "Pin size", function() return O.Get("size") end, stepper("size"), pct))
  add(W.Step(parent, "Pin opacity", function() return O.Get("alpha") end, stepper("alpha"), pct))
  add(W.Check(parent, "Show names next to pins", function() return O.Get("labels") end,
    function(v) O.Set("labels", v) end))
  add(W.Check(parent, "Show minimap button", function() return O.Get("minimapButton") end,
    function(v) O.Set("minimapButton", v) end))
  add(W.Check(parent, "Show On/Off button on the world map", function() return O.Get("mapButton") end,
    function(v) O.Set("mapButton", v) end), 34)

  text(parent, "GameFontHighlightSmall", 18, y, 320):SetText(
    "To hide names while you hold a key: Esc > Options > Key Bindings > AddOns > Whereabouts.")
  y = y - 36
  add(W.Button(parent, "Reset appearance", 140, function() O.Reset() end), 36)

  local upd = text(parent, "GameFontNormal", 18, y, 320)
  local box = W.CopyBox(parent, 300)
  box:SetPoint("TOPLEFT", 22, y - 20)
  local status = text(parent, "GameFontNormalSmall", 18, y - 52, 320)

  return function()
    for i = 1, #rows do rows[i].Refresh() end
    status:SetText(ns.Config.StatusText())
    local msg = ns.Version.Message()
    upd:SetText(msg and ("Update available: " .. ns.Version.newest) or "")
    box:SetShown(msg ~= nil)
    if msg then box:SetValue(ns.Version.Link() or "Download link not set yet") end
  end
end
