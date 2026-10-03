local ADDON, ns = ...
local Pool = {}
ns.PinPool = Pool

-- Pins live on their own overlay instead of inside the map canvas: Blizzard's map art and
-- overlays out-rank anything parented to the canvas. The overlay sits far above them in the
-- same strata and is clipped to the scroll area so pins cannot leak over the quest panel.
local OVERLAY_LEVEL = 5000
local pool, overlay = {}, nil

local function hideTip() GameTooltip:Hide() end

local function onEnter(self)
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetText(self.label or "?")
  local info = self.pm and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(self.pm)
  GameTooltip:AddLine(format("%s  %.1f, %.1f", info and info.name or "", (self.px or 0) / 10, (self.py or 0) / 10), 1, 1, 1)
  GameTooltip:Show()
end

function Pool.Overlay(wm)
  if overlay then return overlay end
  overlay = CreateFrame("Frame", nil, wm)
  overlay:SetAllPoints(wm.ScrollContainer or wm)
  overlay:SetFrameStrata(wm:GetFrameStrata())
  overlay:SetFrameLevel(OVERLAY_LEVEL)
  if overlay.SetClipsChildren then overlay:SetClipsChildren(true) end
  return overlay
end

function Pool.Get(i, parent)
  local p = pool[i]
  if not p then
    p = ns.PinArt.New(parent, onEnter, hideTip)
    pool[i] = p
  end
  return p
end

function Pool.Count() return #pool end
function Pool.At(i) return pool[i] end

function Pool.HideFrom(n)
  for i = n, #pool do pool[i]:Hide() end
end

-- Anchor offsets are in the pin's own units: canvas units times the canvas/pin effective-scale ratio.
function Pool.Put(p, canvas, x, y, w, h)
  local f = canvas:GetEffectiveScale() / p:GetEffectiveScale()
  p:ClearAllPoints()
  p:SetPoint("CENTER", canvas, "TOPLEFT", x / 1000 * w * f, -y / 1000 * h * f)
  p:Show()
end
