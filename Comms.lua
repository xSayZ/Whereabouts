local ADDON, ns = ...
local Comms = {}
ns.Comms = Comms

local PREFIX = "WHRBT" -- wire format and protocol version live in Wire.lua
-- Guild only, by design: every send and receive uses this one constant. No option, no other chat type.
local CHANNEL = "GUILD"
Comms.PREFIX, Comms.CHANNEL = PREFIX, CHANNEL

local TICK, EXPIRE_TICK = 5, 10
local HEARTBEAT = 30
local MOVE_THRESH = 5 -- permille
local BACKOFF, LOCKDOWN_BACKOFF = 15, 60
local VERSION_EVERY = 600 -- seconds between version announcements
local floor, abs = math.floor, math.abs
local R = Enum and Enum.SendAddonMessageResult

local running, sendTicker, expireTicker
local pending, pVer, pMap, pX, pY
local lastSent, backoffUntil, nextVer = 0, 0, 0
local lastMap, lastX, lastY
local sentText, sentAt = nil, 0
local st = { sent = 0, fail = 0, recv = 0, own = 0, bad = 0, rej = 0 }
Comms.stats = st

local function ownPos()
  if not C_Map then return end
  local map = C_Map.GetBestMapForUnit("player")
  if not map then return end
  local pos = C_Map.GetPlayerMapPosition(map, "player")
  if not pos then return end
  local x, y = pos:GetXY()
  if not x or not y then return end
  if issecretvalue and (issecretvalue(x) or issecretvalue(y)) then return end
  if x == 0 and y == 0 then return end -- API's "no position" value
  return map, floor(x * 1000 + 0.5), floor(y * 1000 + 0.5)
end

local function flush(now)
  if not pending or now < backoffUntil then return end
  local res = select(-1, C_ChatInfo.SendAddonMessage(PREFIX, pending, CHANNEL))
  if res == true or (R and res == R.Success) then
    if pVer then
      nextVer = now + VERSION_EVERY
    else
      sentText, sentAt, lastSent, lastMap, lastX, lastY = pending, now, now, pMap, pX, pY
    end
    pending = nil
    return
  end
  st.fail, st.lastRes = st.fail + 1, res
  local locked = R and R.AddOnMessageLockdown ~= nil and res == R.AddOnMessageLockdown
  backoffUntil = now + (locked and LOCKDOWN_BACKOFF or BACKOFF)
end

-- At most one message per tick. A due version announcement takes the slot for one tick.
function Comms.Tick()
  if not running or not ns.IsEnabled() then return end
  if IsInInstance() or not IsInGuild() then return end
  local now = GetTime()
  if now >= nextVer then
    if not (pending and pVer) then pending, pVer = ns.Wire.Ver(ns.Version.current), true end
  else
    local m, x, y = ownPos()
    if not m then pending = nil return end
    local moved = m ~= lastMap or abs(x - lastX) > MOVE_THRESH or abs(y - lastY) > MOVE_THRESH
    if moved or now - lastSent >= HEARTBEAT then
      pending, pVer, pMap, pX, pY = ns.Wire.Pos(m, x, y), false, m, x, y -- replaces any older one
    end
  end
  flush(now)
end

function Comms.IsRunning() return running == true end
function Comms.LastSent() return sentText, sentAt end -- Inbox uses this to recognise our own echo

local function regOk(r)
  if r == true then return true end
  local E = Enum and Enum.RegisterAddonMessagePrefixResult
  return E ~= nil and (r == E.Success or r == E.DuplicatePrefix)
end

function Comms.Start()
  if running then return end
  local r = C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
  if not regOk(r) then
    ns.Print("prefix registration refused: " .. tostring(r))
    return
  end
  running, st.me = true, UnitName("player")
  pending, pVer, lastSent, backoffUntil, lastMap, sentText, sentAt = nil, false, 0, 0, nil, nil, 0
  nextVer = GetTime() + 10 + (GetTime() * 1000 % 15) -- first announcement after 10-25s, spread out
  ns.Inbox.Start()
  sendTicker = C_Timer.NewTicker(TICK, Comms.Tick)
  expireTicker = C_Timer.NewTicker(EXPIRE_TICK, function() ns.Roster.Expire(GetTime()) end)
  Comms.Tick()
end

-- sendOff: tell peers to drop our pin (only valid on an explicit opt-out).
function Comms.Stop(sendOff)
  if not running then return end
  if sendOff and IsInGuild() and not IsInInstance() then
    C_ChatInfo.SendAddonMessage(PREFIX, ns.Wire.Off(), CHANNEL) -- best effort; peers expire us anyway
  end
  running, pending = false, nil
  ns.Inbox.Stop()
  if sendTicker then sendTicker:Cancel() end
  if expireTicker then expireTicker:Cancel() end
  sendTicker, expireTicker = nil, nil
end

-- Sends nothing. Prints what this client exposes so API_NOTES can be filled in.
function Comms.Probe()
  local m, x, y = ownPos()
  ns.Print(m and ns.Wire.Pos(m, x, y) or "own position unavailable")
  ns.Print("SendAddonMessageResult enum: " .. tostring(R ~= nil)
    .. ", lockdown: " .. tostring(R and R.AddOnMessageLockdown))
  ns.Print("issecretvalue: " .. tostring(issecretvalue ~= nil)
    .. ", inInstance: " .. tostring(IsInInstance()) .. ", inGuild: " .. tostring(IsInGuild()))
end
