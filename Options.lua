local ADDON, ns = ...
local Options = {}
ns.Options = Options

local db
local listeners = {}

local function clamp(key, v)
  local r = ns.Ranges[key]
  if not r then return v end
  v = math.max(r[1], math.min(r[2], v))
  v = math.floor(v / r[3] + 0.5) * r[3]
  return math.floor(v * 100 + 0.5) / 100 -- drop float noise such as 0.30000000000000004
end

-- Returns the cleaned value, or nil when it cannot be used.
local function valid(key, v)
  local d = ns.Defaults[key]
  if type(d) == "boolean" then return v and true or false end
  if type(d) == "number" then
    v = tonumber(v)
    return v and clamp(key, v)
  end
  if key == "theme" then return ns.Themes.Exists(v) and v or nil end
  return nil
end

-- Fills in anything missing so the rest of the addon never sees a nil or a bad value.
function Options.Init()
  WhereaboutsDB = WhereaboutsDB or {}
  db = WhereaboutsDB
  if db.hideMinimap ~= nil then -- name used before 0.3.0
    db.minimapButton, db.hideMinimap = not db.hideMinimap, nil
  end
  for key, default in pairs(ns.Defaults) do
    local v
    if db[key] ~= nil then v = valid(key, db[key]) end
    if v == nil then v = default end
    db[key] = v
  end
end

function Options.Get(key)
  if db then return db[key] end
  return ns.Defaults[key]
end

-- Returns true if the value changed. Listeners run after the change.
function Options.Set(key, v)
  if not db or ns.Defaults[key] == nil then return false end
  v = valid(key, v)
  if v == nil or db[key] == v then return false end
  db[key] = v
  for i = 1, #listeners do listeners[i](key, v) end
  return true
end

function Options.Subscribe(fn)
  listeners[#listeners + 1] = fn
end

-- Everything except the sharing switch: a reset should never silently change who sees you.
function Options.Reset()
  for key, default in pairs(ns.Defaults) do
    if key ~= "enabled" then Options.Set(key, default) end
  end
end
