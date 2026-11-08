local ADDON, ns = ...
local Layer = {}
ns.Layer = Layer

-- Quest-type pin templates from Blizzard's Mainline map code. Templates the client lacks are skipped.
local QUEST = {
  "QuestPinTemplate", "QuestOfferPinTemplate", "StorylineQuestPinTemplate", "WorldMap_WorldQuestPinTemplate",
  "WorldQuestPinTemplate", "BonusObjectivePinTemplate", "ThreatObjectivePinTemplate",
}

local function scan(wm, template, low)
  for pin in wm:EnumeratePinsByTemplate(template) do
    local l = pin.GetFrameLevel and pin:GetFrameLevel()
    if l and (not low or l < low) then low = l end
  end
  return low
end

-- Other addons that use the map's pin system: any template with "quest" in its name (not area blobs).
local function questLike(t)
  local s = type(t) == "string" and strlower(t)
  return s and s:find("quest", 1, true) and not s:find("blob", 1, true)
end

local function lowest(wm)
  local low
  for i = 1, #QUEST do low = scan(wm, QUEST[i], low) end
  if type(wm.pinPools) == "table" then
    for t in pairs(wm.pinPools) do
      if questLike(t) then low = scan(wm, t, low) end
    end
  end
  return low
end

-- Overlay frame level for this draw: just under the lowest quest marker on the map, so markers
-- stay visible and clickable. Without quest markers (or with the option off) pins stay on top.
function Layer.Level(wm)
  Layer.why = "on top"
  if not ns.Options.Get("underQuests") then return ns.PinPool.TOP end
  if type(wm.EnumeratePinsByTemplate) ~= "function" then Layer.why = "no pin enumeration" return ns.PinPool.TOP end
  local ok, low = pcall(lowest, wm)
  if not ok then Layer.why = "enumeration failed" return ns.PinPool.TOP end
  if not low or low < 3 then return ns.PinPool.TOP end
  Layer.why = "under quest markers at " .. low
  return low - 2 -- pins are the overlay's children, one level above it
end
