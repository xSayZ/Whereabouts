local ADDON, ns = ...
local Debug = {}
ns.Debug = Debug

-- Read-only report of every stage: send, receive, decode, roster, draw.
function Debug.Dump()
  local P, st = ns.Print, ns.Comms.stats
  P(format("VERSION %s | newest seen from guildmates: %s | theme %s size %s alpha %s", ns.Version.current,
    tostring(ns.Version.newest), tostring(ns.Options.Get("theme")), tostring(ns.Options.Get("size")),
    tostring(ns.Options.Get("alpha"))))
  P(format("enabled %s | running %s | guild %s | instance %s",
    tostring(ns.IsEnabled()), tostring(ns.Comms.IsRunning()),
    tostring(IsInGuild() and true or false), tostring(IsInInstance() and true or false)))
  P(format("SEND ok %d | failed %d | last failure result: %s", st.sent, st.fail, tostring(st.lastRes)))
  P(format("RECV from others %d | own echoes %d | undecodable %d | last sender: %s",
    st.recv, st.own, st.bad, tostring(st.lastSender)))
  P(format("SELF UnitName %s | last sender is me by name: %s | learned self from echo: %s", tostring(UnitName("player")),
    tostring(st.lastSender and ns.Roster.IsSelf(st.lastSender)), tostring(st.learned)))
  P(format("GUILD-ONLY rejected (sender not in guild roster) %d | last: %s | roster check %s", st.rej,
    tostring(st.lastRej), ns.Classes.known > 0 and "active" or "inactive (roster not loaded)"))
  local wm = WorldMapFrame
  P(format("MAP frame %s | GetCanvas %s | ScrollContainer %s | shown %s",
    tostring(wm ~= nil), tostring(wm and wm.GetCanvas ~= nil), tostring(wm and wm.ScrollContainer ~= nil),
    tostring(wm and wm:IsShown() or false)))
  local pm = ns.Pins
  P(format("DRAW calls %s | last result: %s | pins shown %s | viewed mapID %s",
    tostring(pm.draws), tostring(pm.why), tostring(pm.shown), tostring(pm.mapID)))
  P(format("CANVAS w %s h %s scale %s", tostring(pm.w), tostring(pm.h), tostring(pm.cs)))
  local p1, cv = pm.First(), pm.canvas
  if p1 and cv then
    P(format("PIN1 shown %s visible %s alpha %.2f level %d strata %s size %.0fx%.0f left %s bottom %s",
      tostring(p1:IsShown()), tostring(p1:IsVisible()), p1:GetEffectiveAlpha(), p1:GetFrameLevel(),
      p1:GetFrameStrata(), p1:GetWidth(), p1:GetHeight(), tostring(p1:GetLeft()), tostring(p1:GetBottom())))
    P(format("CANVAS level %d strata %s visible %s left %s bottom %s", cv:GetFrameLevel(),
      cv:GetFrameStrata(), tostring(cv:IsVisible()), tostring(cv:GetLeft()), tostring(cv:GetBottom())))
  end
  P(format("CLASSES guild members read %d", ns.Classes.known))
  local now, n = GetTime(), 0
  for name, p in ns.Roster.Iterate() do
    n = n + 1
    local vx, vy = ns.Project.Get(p, pm.mapID or 0)
    P(format("PEER %s map %d at %d,%d (%ds ago) | on viewed map: %s | class %s", name, p.mapID, p.x, p.y, now - p.t,
      vx and format("%.1f,%.1f", vx / 10, vy / 10) or "no", tostring(ns.Classes.Get(Ambiguate(name, "short")))))
  end
  if n == 0 then P("PEER none in roster") end
end
