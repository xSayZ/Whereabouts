-- Minimal fake of the WoW API, just enough to run the addon files offline (Lua 5.1).
-- Usage: local S = dofile("tests/stubs.lua"); S.install(); local ns = S.ns(); S.loadAll(ns)
local S = {}
local REAL_PRINT = print

local function frame(kind, name, parent, template)
  local f = { kind = kind, name = name, parent = parent, template = template, es = 1, scale = 1,
              alpha = 1, shown = true, events = {}, scripts = {}, texts = {}, level = 1 }
  if parent and parent.es then f.es = parent.es end
  function f:SetScript(n, fn) self.scripts[n] = fn end
  function f:GetScript(n) return self.scripts[n] end
  function f:HookScript(n, fn) self.scripts["hook" .. n] = fn end
  function f:RegisterEvent(e) self.events[e] = true end
  function f:UnregisterEvent(e) self.events[e] = nil end
  function f:Show() self.shown = true end
  function f:Hide() self.shown = false end
  function f:SetShown(b) self.shown = b and true or false end
  function f:IsShown() return self.shown end
  function f:IsVisible() return self.shown end
  function f:SetPoint(...) self.pt = { ... } end
  function f:ClearAllPoints() self.pt = nil end
  function f:SetAllPoints() end
  function f:SetSize(w, h) self.w, self.h = w, h end
  function f:GetWidth() return self.w or 0 end
  function f:GetHeight() return self.h or 0 end
  function f:SetScale(s) self.scale = s self.es = ((self.parent and self.parent.es) or 1) * s end
  function f:GetScale() return self.scale end
  function f:GetEffectiveScale() return self.es end
  function f:SetAlpha(a) self.alpha = a end
  function f:GetAlpha() return self.alpha end
  function f:SetFrameLevel(l) self.level = l end
  function f:GetFrameLevel() return self.level end
  function f:SetFrameStrata(s) self.strata = s end
  function f:GetFrameStrata() return self.strata or "HIGH" end
  function f:SetText(t) self.text = t end
  function f:GetText() return self.text or "" end
  function f:SetChecked(b) self.checked = b end
  function f:GetChecked() return self.checked end
  function f:SetTexture(t) self.tex = t self.color = nil end
  function f:SetColorTexture(r, g, b) self.color = { r, g, b } self.tex = nil end
  function f:SetTexCoord(...) self.tc = { ... } end
  function f:SetVertexColor(...) self.vc = { ... } end
  function f:SetTextColor(r, g, b) self.tcolor = { r, g, b } end
  function f:GetFont() return "Fonts\\FRIZQT__.TTF", 10, "" end
  function f:SetFont(font, size, flags) self.flags = flags end
  local function region(kind, parent)
    local r = frame(kind, nil, parent)
    if S.frames then S.frames[#S.frames + 1] = r end
    return r
  end
  function f:CreateTexture() return region("Texture", self) end
  function f:CreateFontString() return region("FontString", self) end
  function f:GetHighlightTexture() return frame("Texture", nil, self) end
  function f:SetClipsChildren(b) self.clips = b end
  function f:Click() if self.scripts.OnClick then self.scripts.OnClick(self, "LeftButton") end end
  -- Any other method (CamelCase) is a no-op; plain fields stay nil like on a real frame.
  setmetatable(f, { __index = function(_, k)
    if type(k) == "string" and k:match("^%u") then return function() end end
  end })
  return f
end
S.frame = frame

function S.install()
  _G.print = REAL_PRINT
  S.now, S.sent, S.printed, S.frames, S.tickers = 100, {}, {}, {}, {}
  S.sendResult, S.inGuild, S.inInstance, S.enabled = 0, true, false, true
  S.roster, S.rosterLoaded, S.myName = {}, true, "Me"
  S.pos = { map = 1429, x = 0.5, y = 0.5 }
  _G.WhereaboutsDB, _G.SlashCmdList = nil, {}
  _G.format, _G.strlower = string.format, string.lower
  _G.strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
  _G.GetTime = function() return S.now end
  _G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
  _G.hooksecurefunc = function() end
  _G.Ambiguate = function(n) return (n:gsub("%-.*", "")) end
  _G.UnitName = function() return S.myName end
  _G.IsInGuild = function() return S.inGuild end
  _G.IsInInstance = function() return S.inInstance end
  _G.GetCursorPosition = function() return 0, 0 end
  _G.Enum = { SendAddonMessageResult = { Success = 0, AddonMessageThrottle = 3, AddOnMessageLockdown = 11 },
              RegisterAddonMessagePrefixResult = { Success = 0, DuplicatePrefix = 1 } }
  _G.CreateFrame = function(kind, name, parent, template)
    local f = frame(kind, name, parent, template)
    S.frames[#S.frames + 1] = f
    if name then _G[name] = f end
    return f
  end
  _G.UIParent, _G.GameTooltip, _G.Minimap = frame("Frame"), frame("GameTooltip"), frame("Frame")
  _G.Minimap.w = 140
  _G.C_Timer = { NewTicker = function(_, fn)
    local t = { fn = fn, Cancel = function(self) self.cancelled = true end }
    S.tickers[#S.tickers + 1] = t
    return t
  end }
  _G.C_ChatInfo = {
    RegisterAddonMessagePrefix = function() return true end,
    SendAddonMessage = function(prefix, msg, channel)
      S.sent[#S.sent + 1] = { prefix = prefix, msg = msg, channel = channel }
      return S.sendResult
    end,
  }
  _G.C_Map = {
    GetBestMapForUnit = function() return S.pos.map end,
    GetPlayerMapPosition = function() return { GetXY = function() return S.pos.x, S.pos.y end } end,
    GetMapInfo = function(id) return { parentMapID = (S.parents or {})[id] or 0, name = "Map" .. id } end,
    GetMapRectOnMap = function(id, top) return unpack(S.rects[id .. ":" .. top] or {}) end,
  }
  S.parents, S.rects = {}, {}
  _G.GetNumGuildMembers = function() return S.rosterLoaded and #S.roster or 0 end
  _G.GetGuildRosterInfo = function(i)
    local m = S.roster[i]
    return m[1], nil, nil, nil, nil, nil, nil, nil, nil, nil, m[2]
  end
  _G.RAID_CLASS_COLORS = { WARRIOR = { r = 0.78, g = 0.61, b = 0.43 }, MAGE = { r = 0.25, g = 0.78, b = 0.92 } }
  _G.CLASS_ICON_TCOORDS = { WARRIOR = { 0, 0.25, 0, 0.25 }, MAGE = { 0.25, 0.5, 0, 0.25 } }
  _G.WorldMapFrame, _G.Settings, _G.AddonCompartmentFrame, _G.C_AddOns = nil, nil, nil, nil
  _G.GetAddOnMetadata = function(_, field) return field == "Version" and S.tocVersion end
  S.tocVersion = S.readTocVersion()
end

-- A fake world map: ScrollContainer.Child is the canvas (no GetCanvas, as seen on Forever).
function S.map(mapID, canvasScale)
  local canvas = frame("Frame", nil, nil)
  canvas.w, canvas.h, canvas.scale, canvas.es = 1000, 600, canvasScale or 0.7, canvasScale or 0.7
  local wm = frame("Frame", "WorldMapFrame")
  wm.GetCanvas = nil
  setmetatable(wm, nil)
  wm.IsShown, wm.HookScript, wm.GetFrameStrata = function() return true end, function() end, function() return "HIGH" end
  wm.GetFrameLevel, wm.SetFrameLevel = function() return 1 end, function() end
  local sc = frame("Frame", nil, wm)
  sc.Child = canvas
  wm.ScrollContainer, wm.mapID = sc, mapID
  _G.WorldMapFrame = wm
  return wm, canvas
end

function S.ns()
  local ns = { Print = function(m) S.printed[#S.printed + 1] = m end }
  ns.IsEnabled = function() return S.enabled end
  return ns
end

function S.readTocVersion()
  local f = io.open("Whereabouts.toc")
  local v = f and f:read("*a"):match("## Version:%s*([%d%.]+)")
  if f then f:close() end
  return v
end

function S.load(ns, names)
  for _, n in ipairs(names) do assert(loadfile(n .. ".lua"))("Whereabouts", ns) end
end

-- Loads every .lua file listed in the .toc, in order. Also proves the .toc is loadable.
function S.loadAll(ns, skip)
  local f = assert(io.open("Whereabouts.toc"))
  for line in f:lines() do
    local n = line:match("^(%S+)%.lua%s*$")
    if n and n ~= skip then assert(loadfile(n .. ".lua"))("Whereabouts", ns) end
  end
  f:close()
end

-- Forces the coalesced pin redraw to run now.
function S.redraw()
  for _, f in ipairs(S.frames) do
    if not f.parent and f.scripts.OnUpdate then f:Show() f.scripts.OnUpdate(f, 1) return end
  end
end

function S.frameWithEvent(ev)
  for i = #S.frames, 1, -1 do if S.frames[i].events[ev] then return S.frames[i] end end -- newest first
end

return S
