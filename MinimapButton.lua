local ADDON, ns = ...
local MB = {}
ns.MinimapButton = MB

-- Uses LibDBIcon (the standard button, which button-collector addons recognise) when it is
-- installed. Otherwise the plain button in MinimapCustom.lua is used. Both look and act the same.
local NAME, ICON = "Whereabouts", "Interface\\Icons\\INV_Misc_Map_01"
local dbi, label, inited

local function libs()
  local stub = _G.LibStub
  if not stub then return end
  local icon, broker = stub("LibDBIcon-1.0", true), stub("LibDataBroker-1.1", true)
  if icon and broker then return icon, broker end
end

function MB.Click(_, button)
  if button == "RightButton" then ns.Config.Open()
  elseif ns.IsEnabled() then ns.Disable()
  else ns.Enable() end
end

function MB.Tooltip(tip)
  tip:SetText("Whereabouts " .. ns.Version.current)
  tip:AddLine(ns.Config.StatusText(), 1, 1, 1)
  if ns.Version.newest then tip:AddLine("Update available: " .. ns.Version.newest, 1, 0.82, 0) end
  tip:AddLine("Left-click: turn sharing on/off", 0.8, 0.8, 0.8)
  tip:AddLine("Right-click: settings", 0.8, 0.8, 0.8)
end

-- The ON/OFF text on top of the icon, as on the plain button.
local function decorate(b)
  if not (b and b.icon) then return end
  local strip = b:CreateTexture(nil, "ARTWORK", nil, 2)
  strip:SetSize(22, 10)
  strip:SetPoint("CENTER", b.icon, "CENTER", 0, -1)
  strip:SetColorTexture(0, 0, 0, 0.65)
  label = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("CENTER", strip, "CENTER", 0, 0)
  local font, size = label:GetFont()
  if font then label:SetFont(font, size, "OUTLINE") end
end

function MB.Refresh()
  if not inited then return end
  if not dbi then return ns.MinimapCustom.Refresh() end
  local show = ns.Options.Get("minimapButton")
  WhereaboutsDB.minimap.hide = not show
  if label then
    label:SetText(ns.IsEnabled() and "ON" or "OFF")
    if ns.IsEnabled() then label:SetTextColor(0.1, 1, 0.1) else label:SetTextColor(1, 0.15, 0.15) end
  end
  if show then dbi:Show(NAME) else dbi:Hide(NAME) end
end

function MB.Init()
  if inited or not Minimap then return end
  inited = true
  local icon, broker = libs()
  if not icon then ns.MinimapCustom.Init() return MB.Refresh() end
  local angle = WhereaboutsDB.minimapAngle -- position saved by the plain button, in radians
  WhereaboutsDB.minimap = WhereaboutsDB.minimap or { minimapPos = angle and math.deg(angle) % 360 or 225 }
  local obj = broker:GetDataObjectByName(NAME) or broker:NewDataObject(NAME,
    { type = "launcher", icon = ICON, text = NAME, OnClick = MB.Click, OnTooltipShow = MB.Tooltip })
  icon:Register(NAME, obj, WhereaboutsDB.minimap)
  dbi = icon
  decorate(icon:GetMinimapButton(NAME))
  MB.Refresh()
end

function MB.UsingLibrary() return dbi ~= nil end
