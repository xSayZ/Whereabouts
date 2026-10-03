local ADDON, ns = ...
local Version = {}
ns.Version = Version

-- Where players download updates. Fill this in once the download page exists.
Version.UPDATE_URL = ""

local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
-- The .toc is the single source of truth for the version number.
Version.current = (meta and meta(ADDON, "Version")) or "0.0.0"
Version.newest = nil -- newest version heard from a guildmate, if newer than ours

local strmatch = string.match

-- Pure: "1.2.3" -> 1, 2, 3 (nil if it is not exactly x.y.z).
function Version.Parse(v)
  if type(v) ~= "string" then return end
  local a, b, c = strmatch(v, "^(%d+)%.(%d+)%.(%d+)$")
  if a then return tonumber(a), tonumber(b), tonumber(c) end
end

-- Pure: 1 if a is newer than b, -1 if older, 0 if equal, nil if either is not x.y.z.
function Version.Compare(a, b)
  local a1, a2, a3 = Version.Parse(a)
  local b1, b2, b3 = Version.Parse(b)
  if not a1 or not b1 then return end
  if a1 ~= b1 then return a1 > b1 and 1 or -1 end
  if a2 ~= b2 then return a2 > b2 and 1 or -1 end
  if a3 ~= b3 then return a3 > b3 and 1 or -1 end
  return 0
end

function Version.Link()
  return Version.UPDATE_URL ~= "" and Version.UPDATE_URL or nil
end

function Version.Message()
  if not Version.newest then return nil end
  local msg = string.format("Whereabouts %s is available (you have %s).", Version.newest, Version.current)
  return msg .. (Version.Link() and (" Download: " .. Version.Link()) or " The download link has not been set yet.")
end

-- Called with a version string heard from a guildmate. Tells the player once per newer version.
function Version.Note(v)
  if Version.Compare(v, Version.current) ~= 1 then return end
  if Version.newest and Version.Compare(v, Version.newest) ~= 1 then return end
  Version.newest = v
  ns.Print(Version.Message())
  if ns.Config then ns.Config.Refresh() end
end
