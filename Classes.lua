local ADDON, ns = ...
local Classes = {}
ns.Classes = Classes

-- Class comes from the guild roster, not the wire protocol, so the protocol stays v1.
local byName, lastScan, started = {}, -60, false
local frame = CreateFrame("Frame")
Classes.known = 0
Classes.onChange = nil -- Core wires this to Pins.Refresh

local function scan()
  local now = GetTime()
  if now - lastScan < 30 then return end
  local total = GetNumGuildMembers and GetNumGuildMembers() or 0
  if total == 0 then return end -- roster not loaded yet; try again on the next event
  lastScan, Classes.known = now, total
  for i = 1, total do
    local name, _, _, _, _, _, _, _, _, _, class = GetGuildRosterInfo(i)
    if name and class then byName[Ambiguate(name, "short")] = class end
  end
  if Classes.onChange then Classes.onChange() end
end
frame:SetScript("OnEvent", scan)

-- Ask the server for a fresh roster (at most every 30s) when we meet a name we do not know.
local lastAsk = -60
function Classes.Refresh()
  local now = GetTime()
  if now - lastAsk < 30 then return end
  lastAsk = now
  if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster()
  elseif GuildRoster then GuildRoster() end
end

function Classes.Start()
  if started then return end
  started = true
  frame:RegisterEvent("GUILD_ROSTER_UPDATE")
  if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster()
  elseif GuildRoster then GuildRoster() end
  scan()
end

function Classes.Stop()
  started = false
  frame:UnregisterEvent("GUILD_ROSTER_UPDATE")
end

function Classes.Get(shortName) return byName[shortName] end

-- true/false once the roster has loaded, nil while it has not (cannot verify yet).
function Classes.IsMember(shortName)
  if Classes.known == 0 then return nil end
  return byName[shortName] ~= nil
end
