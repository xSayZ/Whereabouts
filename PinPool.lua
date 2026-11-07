local ADDON, ns = ...
local Pool = {}
ns.PinPool = Pool

-- Pins live on their own overlay instead of inside the map canvas: Blizzard's map art and
-- overlays out-rank anything parented to the canvas. The overlay sits far above them in the
-- same strata and is clipped to the scroll area so pins cannot leak over the quest panel.
Pool.TOP = 5000 -- see Layer.lua for when the overlay drops below quest markers
local pool, overlay = {}, nil

function Pool.Overlay(wm)
  if overlay then return overlay end
  overlay = CreateFrame("Frame", nil, wm)
  overlay:SetAllPoints(wm.ScrollContainer or wm)
  overlay:SetFrameStrata(wm:GetFrameStrata())
  overlay:SetFrameLevel(Pool.TOP)
  if overlay.SetClipsChildren then overlay:SetClipsChildren(true) end
  return overlay
end

function Pool.Get(i, parent)
  local p = pool[i]
  if not p then
    p = ns.PinArt.New(parent, ns.Merge.OnEnter, ns.Merge.OnLeave)
    pool[i] = p
  end
  return p
end

function Pool.Count() return #pool end
function Pool.At(i) return pool[i] end

function Pool.HideFrom(n)
  for i = n, #pool do pool[i]:Hide() end
end

-- x, y in canvas units from its top left. Anchor offsets are in the pin's own units: canvas units
-- times the canvas/pin effective-scale ratio.
function Pool.Put(p, canvas, x, y)
  local f = canvas:GetEffectiveScale() / p:GetEffectiveScale()
  p:ClearAllPoints()
  p:SetPoint("CENTER", canvas, "TOPLEFT", x * f, -y * f)
  p:Show()
end
