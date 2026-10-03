local ADDON, ns = ...
local Art = {}
ns.PinArt = Art

Art.BASE_SCALE = 0.75 -- multiplied by the player's size setting
local CLASSES = "Interface\\WorldStateFrame\\Icons-Classes"
local MAP = "Interface\\Icons\\INV_Misc_Map_01"

function Art.New(parent, onEnter, onLeave)
  local p = CreateFrame("Frame", nil, parent)
  p:SetSize(31, 31)
  p:EnableMouse(true)
  p.bg = p:CreateTexture(nil, "BACKGROUND")
  p.edge = p:CreateTexture(nil, "BACKGROUND")
  p.icon = p:CreateTexture(nil, "ARTWORK")
  p.ring = p:CreateTexture(nil, "OVERLAY")
  p.name = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  p:SetScript("OnEnter", onEnter)
  p:SetScript("OnLeave", onLeave)
  return p
end

local function classColor(class)
  return class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
end

local function skinIcon(p, th, class)
  local mode = th.icon or "class"
  local size = th.iconSize or (th.ring and 17 or 22)
  p.icon:ClearAllPoints()
  p.icon:SetSize(size, size)
  p.icon:SetPoint("CENTER", 0, th.ring and 1 or 0)
  p.edge:Hide()
  if mode == "solid" then
    local c = classColor(class)
    p.edge:ClearAllPoints()
    p.edge:SetSize(size + 2, size + 2)
    p.edge:SetPoint("CENTER")
    p.edge:SetColorTexture(0, 0, 0, 1)
    p.edge:Show()
    p.icon:SetColorTexture(c and c.r or 1, c and c.g or 0.82, c and c.b or 0, 1)
  elseif mode == "class" then
    local t = class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    if t then
      p.icon:SetTexture(CLASSES)
      p.icon:SetTexCoord(t[1], t[2], t[3], t[4])
    else
      p.icon:SetTexture(th.fallbackIcon or MAP)
      p.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end
  else
    p.icon:SetTexture(mode)
    p.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  end
end

local function skinFrame(p, th)
  if th.ring then
    local c = th.ringColor or { 1, 1, 1 }
    p.ring:SetTexture(th.ring)
    p.ring:SetVertexColor(c[1], c[2], c[3])
    p.ring:ClearAllPoints()
    p.ring:SetSize(50, 50)
    p.ring:SetPoint("TOPLEFT")
    p.ring:Show()
  else
    p.ring:Hide()
  end
  if th.background then
    local size = (th.iconSize or (th.ring and 17 or 22)) + 3
    p.bg:SetTexture(th.background)
    p.bg:ClearAllPoints()
    p.bg:SetSize(size, size)
    p.bg:SetPoint("CENTER", th.ring and 1.5 or 0, th.ring and 0.5 or 0)
    p.bg:Show()
  else
    p.bg:Hide()
  end
end

local function skinLabel(p, th, class)
  local lb = th.label or {}
  local font, size = p.name:GetFont()
  if font then p.name:SetFont(font, size, lb.outline == false and "" or "OUTLINE") end
  local c = lb.color
  if type(c) == "table" then
    p.name:SetTextColor(c[1], c[2], c[3])
  else
    local cc = classColor(class)
    if cc then p.name:SetTextColor(cc.r, cc.g, cc.b) else p.name:SetTextColor(1, 0.82, 0) end
  end
  p.name:ClearAllPoints()
  p.name:SetPoint("LEFT", p, "LEFT", th.ring and 28 or 24, 0)
end

-- Applies a theme (and the player's class) to one pin.
function Art.Skin(p, th, class)
  p.theme, p.cls = th, class
  skinFrame(p, th)
  skinIcon(p, th, class)
  skinLabel(p, th, class)
end
