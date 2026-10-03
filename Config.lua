local ADDON, ns = ...
local Config = {}
ns.Config = Config

local refreshers, category, window, inited = {}, nil, nil, false

function Config.StatusText()
  if not ns.IsEnabled() then return "Off. Nobody can see you." end
  if not IsInGuild() then return "On, but you are not in a guild." end
  if IsInInstance() then return "Paused inside instances." end
  if not ns.Comms.IsRunning() then return "On, but not connected. Try /reload." end
  return format("Sharing. %d guildmate(s) visible.", ns.Roster.Count())
end

function Config.Refresh()
  for i = 1, #refreshers do refreshers[i]() end
end

-- Stock window, used only where the game's Settings panel is not available.
local function buildWindow()
  local ok, f = pcall(CreateFrame, "Frame", nil, UIParent, "BasicFrameTemplateWithInset")
  if not ok then
    f = CreateFrame("Frame", nil, UIParent)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.85)
  end
  f:SetSize(372, 450)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  local refresh = ns.Panel.Build(f)
  refreshers[#refreshers + 1] = function() if f:IsShown() then refresh() end end
  f:SetScript("OnShow", refresh)
  local acc = 0
  f:SetScript("OnUpdate", function(_, dt) -- keeps the status line live
    acc = acc + dt
    if acc >= 1 then acc = 0 refresh() end
  end)
  f:Hide()
  return f
end

function Config.Open()
  if category and Settings.OpenToCategory then
    local id = category.GetID and category:GetID() or category.ID
    if pcall(Settings.OpenToCategory, id) then return end
  end
  window = window or buildWindow()
  if window:IsShown() then window:Hide() else window:Show() end
end

-- Registers the panel under Esc > Options > AddOns when this client has that API.
function Config.Init()
  if inited then return end
  inited = true
  if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local panel = CreateFrame("Frame")
    panel.name = "Whereabouts"
    local refresh = ns.Panel.Build(panel)
    panel:SetScript("OnShow", refresh)
    refreshers[#refreshers + 1] = function() if panel:IsShown() then refresh() end end
    category = Settings.RegisterCanvasLayoutCategory(panel, "Whereabouts")
    Settings.RegisterAddOnCategory(category)
  end
  if AddonCompartmentFrame and AddonCompartmentFrame.RegisterAddon then
    AddonCompartmentFrame:RegisterAddon({
      text = "Whereabouts",
      icon = "Interface\\Icons\\INV_Misc_Map_01",
      notCheckable = true,
      registerForAnyClick = true,
      func = Config.Open,
    })
  end
end
