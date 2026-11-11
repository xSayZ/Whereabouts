local ADDON, ns = ...
local Names = {}
ns.Names = Names

-- How guildmates' names are shown on pin labels (tooltips keep the full name). Forever names can have several words.
local ORDER = { "full", "short", "initials" }
local LABEL = { full = "Firstname Lastname", short = "F. Lastname", initials = "FL" }
local cache, mode = {}, nil

-- First character, whole even when it is a multi-byte UTF-8 letter.
local function first(w) return w:match("^[%z\1-\127\194-\244][\128-\191]*") or w end

local function build(name, m)
  if m == "initials" then return (name:gsub("%S+", first):gsub("%s+", "")) end
  if m == "short" then
    local f, rest = name:match("^(%S+)%s+(.+)$")
    if f then return first(f) .. ". " .. rest end
  end
  return name
end

-- name: the short (realm-free) character name. Cached per format, so draws never rebuild strings.
function Names.Format(name)
  local m = ns.Options.Get("nameFormat")
  if m ~= mode then wipe(cache) mode = m end
  local c = cache[name]
  if not c then
    c = build(name, m)
    cache[name] = c
  end
  return c
end

function Names.Valid(m) return LABEL[m] ~= nil end
function Names.Label(m) return LABEL[m] or LABEL.full end

function Names.Next(m)
  for i = 1, #ORDER do
    if ORDER[i] == m then return ORDER[i % #ORDER + 1] end
  end
  return ORDER[1]
end
