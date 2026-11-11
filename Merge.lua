local ADDON, ns = ...
local Merge = {}
ns.Merge = Merge

-- Shared by the world map and the minimap: collect visible peers, merge the ones whose pins would
-- overlap, then fill one pin per group. Arrays are reused; nothing here allocates per draw.
local names, peers, xs, ys, tags, txs, tys = {}, {}, {}, {}, {}, {}, {}
local of, cx, cy, size, lead, ctag = {}, {}, {}, {}, {}, {}
Merge.FADE = 0.2 -- alpha of a pin under the mouse, so whatever is beneath shows through
local n, k = 0, 0

function Merge.Reset() n, k = 0, 0 end
function Merge.Count() return k end
function Merge.At(c) return cx[c], cy[c] end

-- x, y in any unit; Run's distance uses the same unit. With a tag (a zone's mapID), the peer
-- groups with others of the same tag at tx, ty instead of by distance.
function Merge.Add(name, peer, x, y, tag, tx, ty)
  n = n + 1
  names[n], peers[n], xs[n], ys[n] = name, peer, x, y
  tags[n], txs[n], tys[n] = tag or false, tx, ty
end

-- Greedy: each peer joins the nearest group closer than d, else starts one. Groups are few.
function Merge.Run(d)
  local d2 = d * d
  for i = 1, n do
    local tag, best, bd = tags[i], nil, d2
    for c = 1, k do
      if tag then
        if ctag[c] == tag then best = c break end
      elseif not ctag[c] then
        local dx, dy = xs[i] - cx[c], ys[i] - cy[c]
        local dd = dx * dx + dy * dy
        if dd < bd then best, bd = c, dd end
      end
    end
    if best then
      local s = size[best] + 1
      if not tag then
        cx[best] = cx[best] + (xs[i] - cx[best]) / s
        cy[best] = cy[best] + (ys[i] - cy[best]) / s
      end
      size[best] = s
      if names[i] < names[lead[best]] then lead[best] = i end -- stable label whatever the order
      of[i] = best
    else
      k = k + 1
      cx[k], cy[k], size[k], lead[k], ctag[k] = tag and txs[i] or xs[i], tag and tys[i] or ys[i], 1, i, tag
      of[i] = k
    end
  end
  for c = 1, k do -- alone in a zone: show where they actually are
    if ctag[c] and size[c] == 1 then cx[c], cy[c] = xs[lead[c]], ys[lead[c]] end
  end
  return k
end

-- Fills pin p for group c with the current theme. Text and skin change only when the group does.
function Merge.Fill(p, c, th)
  local s, li = size[c], lead[c]
  local key, zone = names[li], s > 1 and ctag[c] or nil
  if p.key ~= key or p.count ~= s or p.zone ~= zone then
    p.key, p.count, p.zone = key, s, zone
    p.label = Ambiguate(key, "short")
    if zone then
      p.name:SetText(format("%s (%d)", Merge.ZoneName(zone), s))
    else
      local shown = ns.Names.Format(p.label)
      p.name:SetText(s > 1 and format("%s +%d", shown, s - 1) or shown)
    end
    ns.PinArt.SetCount(p, s)
  end
  local cls = ns.Classes.Get(p.label)
  if p.theme ~= th or p.cls ~= cls then ns.PinArt.Skin(p, th, cls) end
  local peer = peers[li]
  p.px, p.py, p.pm = peer.x, peer.y, peer.mapID
  local m, mp = p.members, p.mpeers
  local j = 0
  for i = 1, n do
    if of[i] == c then
      j = j + 1
      m[j], mp[j] = names[i], peers[i]
    end
  end
  for i = j + 1, #m do m[i], mp[i] = nil, nil end
end

function Merge.ZoneName(id)
  local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(id)
  return info and info.name or "?"
end

-- Keeps the hover fade while draws reapply the opacity setting.
function Merge.Alpha(p, a) p:SetAlpha(p.hovered and Merge.FADE or a) end

local function classColor(short)
  local cls = ns.Classes.Get(short)
  local cc = cls and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
  if cc then return cc.r, cc.g, cc.b end
  return 1, 0.82, 0
end

local function where(peer)
  local info = peer.mapID and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(peer.mapID)
  return format("%s  %.1f, %.1f", info and info.name or "", (peer.x or 0) / 10, (peer.y or 0) / 10)
end

-- Tooltip for both maps: one player, or every player in a merged pin in their class colour.
function Merge.OnEnter(self)
  if ns.Options.Get("hoverFade") then
    self.hovered = true
    self:SetAlpha(Merge.FADE)
  end
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  local m = self.members
  if not m or #m < 2 then
    GameTooltip:SetText(self.label or "?") -- full name: the pin label may be shortened
    local lvl = self.label and ns.Classes.Level(self.label)
    if lvl then
      local r, g, b = classColor(self.label)
      GameTooltip:AddLine(format("Level %d %s", lvl, ns.Classes.ClassName(self.label) or ""), r, g, b)
    end
    GameTooltip:AddLine(where({ mapID = self.pm, x = self.px, y = self.py }), 1, 1, 1)
  else
    GameTooltip:SetText(self.zone and format("%s: %d guildmates", Merge.ZoneName(self.zone), #m)
      or format("%d guildmates", #m))
    for i = 1, #m do
      local short = Ambiguate(m[i], "short")
      local lvl = ns.Classes.Level(short)
      local r, g, b = classColor(short)
      GameTooltip:AddLine(format(lvl and "%s (%d)   %s" or "%s%s   %s", short, lvl or "",
        where(self.mpeers[i])), r, g, b)
    end
  end
  GameTooltip:Show()
end

function Merge.OnLeave(self)
  GameTooltip:Hide()
  if self.hovered then
    self.hovered = false
    self:SetAlpha(ns.Options.Get("alpha"))
  end
end
