local ADDON, ns = ...
local Wire = {}
ns.Wire = Wire

local VERSION = 1 -- bump on ANY format change; unknown versions are ignored by receivers
local MAX_LEN = 32
local format, strmatch, tonumber = string.format, string.match, tonumber

-- Pure functions: no game calls, checkable offline.
function Wire.Pos(mapID, x, y)
  return format("%d|%d|%d|%d", VERSION, mapID, x, y)
end

function Wire.Off()
  return VERSION .. "|OFF"
end

-- Addon version announcement, e.g. "1|V|0.3.0". Older builds treat it as unreadable and ignore it.
function Wire.Ver(version)
  return format("%d|V|%s", VERSION, version)
end

-- Returns "POS", mapID, x, y | "OFF" | "VER", version | nil (reject).
function Wire.Decode(msg)
  if type(msg) ~= "string" or #msg > MAX_LEN then return end
  local v, rest = strmatch(msg, "^(%d+)|(.+)$")
  if tonumber(v) ~= VERSION then return end
  if rest == "OFF" then return "OFF" end
  local ver = strmatch(rest, "^V|(%d+%.%d+%.%d+)$")
  if ver then return "VER", ver end
  local m, x, y = strmatch(rest, "^(%d+)|(%d+)|(%d+)$")
  if not m then return end
  m, x, y = tonumber(m), tonumber(x), tonumber(y)
  if x > 1000 or y > 1000 then return end
  return "POS", m, x, y
end
