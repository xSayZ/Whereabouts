local ADDON, ns = ...
local MB = {}
ns.MinimapButton = MB

local cos, sin = math.cos, math.sin -- radians (the bare globals use degrees)
local atan2 = math.atan2 or math.atan -- fallback mirrors QuestlineJournal; atan2 may be absent
local DEFAULT_ANGLE = math.rad(225)
local btn, label, inited
local DRAG_MIN = 8 -- pixels; the game starts a drag after a tiny move, which used to swallow the click
local downX, downY, moved

-- Assumes a round minimap; square-minimap addons may need the button dragged by hand.
local function place()
  local a = WhereaboutsDB.minimapAngle or DEFAULT_ANGLE
  local r = Minimap:GetWidth() / 2 + 5
  btn:ClearAllPoints()
  btn:SetPoint("CENTER", Minimap, "CENTER", cos(a) * r, sin(a) * r)
end

local function onDragUpdate()
  local mx, my = Minimap:GetCenter()
  local cx, cy = GetCursorPosition()
  local s = Minimap:GetEffectiveScale()
  if not mx or not cx then return end
  if not moved then
    if downX and (cx - downX) ^ 2 + (cy - downY) ^ 2 < (DRAG_MIN * s) ^ 2 then return end
    moved = true
  end
  WhereaboutsDB.minimapAngle = atan2(cy / s - my, cx / s - mx)
  place()
end

-- Text colour follows the sharing switch; visibility follows the option.
function MB.Refresh()
  ns.MinimapBroker.Refresh(ns.IsEnabled(), ns.Options.Get("minimapButton"))
  if not btn then return end
  if ns.IsEnabled() then
    label:SetText("ON")
    label:SetTextColor(0.1, 1, 0.1)
  else
    label:SetText("OFF")
    label:SetTextColor(1, 0.15, 0.15)
  end
  if ns.Options.Get("minimapButton") then btn:Show() else btn:Hide() end
end

-- Shared by our own button and the LibDBIcon one.
local function fillTooltip(tt)
  tt:SetText("Whereabouts " .. ns.Version.current)
  tt:AddLine(ns.Config.StatusText(), 1, 1, 1)
  if ns.Version.newest then tt:AddLine("Update available: " .. ns.Version.newest, 1, 0.82, 0) end
  tt:AddLine("Left-click: turn sharing on/off", 0.8, 0.8, 0.8)
  tt:AddLine("Right-click: settings", 0.8, 0.8, 0.8)
  tt:AddLine("Drag: move button", 0.8, 0.8, 0.8)
end

local function onEnter(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  fillTooltip(GameTooltip)
  GameTooltip:Show()
end

local function click(_, button)
  if button == "RightButton" then
    ns.Config.Open()
  elseif ns.IsEnabled() then
    ns.Disable()
  else
    ns.Enable()
  end
end

local function build()
  -- Named so button-collector addons (e.g. HidingBar) can identify it; same pattern as QuestlineJournal.
  btn = CreateFrame("Button", "WhereaboutsMinimapButton", Minimap)
  btn:SetSize(31, 31)
  btn:SetFrameStrata("MEDIUM")
  btn:SetFrameLevel(8)
  btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  btn:RegisterForDrag("LeftButton")
  btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local bg = btn:CreateTexture(nil, "BACKGROUND")
  bg:SetSize(20, 20)
  bg:SetPoint("TOPLEFT", 7, -5)
  bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  local icon = btn:CreateTexture("WhereaboutsMinimapButtonIcon", "ARTWORK") -- collectors look up <button>Icon
  icon:SetSize(17, 17)
  icon:SetPoint("TOPLEFT", 7, -6)
  icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
  icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local border = btn:CreateTexture(nil, "OVERLAY")
  border:SetSize(50, 50)
  border:SetPoint("TOPLEFT")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

  -- Dark strip keeps the ON/OFF text readable over the icon.
  local strip = btn:CreateTexture(nil, "ARTWORK", nil, 2)
  strip:SetSize(22, 10)
  strip:SetPoint("CENTER", icon, "CENTER", 0, -1)
  strip:SetColorTexture(0, 0, 0, 0.65)
  label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("CENTER", strip, "CENTER", 0, 0)
  local font, size = label:GetFont()
  if font then label:SetFont(font, size, "OUTLINE") end

  btn:SetScript("OnClick", click)
  btn:SetScript("OnMouseDown", function() downX, downY = GetCursorPosition() end)
  btn:SetScript("OnDragStart", function(self)
    GameTooltip:Hide()
    moved = false
    self:SetScript("OnUpdate", onDragUpdate)
  end)
  btn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    if not moved then click(self, "LeftButton") end -- barely moved: the player meant to click
  end)
  btn:SetScript("OnEnter", onEnter)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
  place()
end

function MB.Init()
  if inited or not Minimap then return end
  inited = true
  if not ns.MinimapBroker.Init(click, fillTooltip) then build() end
  MB.Refresh()
end
