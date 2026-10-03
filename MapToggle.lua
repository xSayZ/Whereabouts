local ADDON, ns = ...
local Toggle = {}
ns.MapToggle = Toggle

local btn, label

local function paint()
  label:SetText(ns.IsEnabled() and "Whereabouts: |cff00ff00On|r" or "Whereabouts: |cffff2020Off|r")
end

-- Plain Button (no template) pinned to the map's bottom-left; shows only while the map is open.
local function create()
  local wm = WorldMapFrame
  if btn or not wm or not wm.ScrollContainer then return end
  local sc = wm.ScrollContainer
  btn = CreateFrame("Button", nil, wm)
  btn:SetSize(140, 22)
  btn:SetPoint("BOTTOMLEFT", sc, "BOTTOMLEFT", 8, 58)
  btn:SetFrameLevel(sc:GetFrameLevel() + 510)
  local bg = btn:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0, 0, 0, 0.6)
  btn:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
  btn:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.15)
  label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("CENTER")
  btn:SetScript("OnClick", function()
    if ns.IsEnabled() then ns.Disable() else ns.Enable() end
  end)
  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Share location with guild")
    GameTooltip:AddLine("Click to toggle. " .. ns.Config.StatusText(), 1, 1, 1, true)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Optional and off by default. Retried on every refresh in case the map UI loads late.
function Toggle.Refresh()
  if ns.Options.Get("mapButton") then
    create()
    if btn then paint() btn:Show() end
  elseif btn then
    btn:Hide()
  end
end
