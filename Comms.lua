local ADDON, ns = ...
local Comms = {}
ns.Comms = Comms

local PREFIX = "WHRBT" -- wire format and protocol version live in Wire.lua
-- Guild only, by design: every send and receive uses this one constant. No option, no other chat type.
local CHANNEL = "GUILD"
Comms.PREFIX, Comms.CHANNEL = PREFIX, CHANNEL

local TICK, EXPIRE_TICK = 1, 10
local SLOW_TICK, FAST_TICK = 5, 2 -- seconds between position checks; fast while a guildmate is nearby
local NEAR_YARDS, NEAR_PERMILLE = 300, 75 -- "nearby" (the permille figure is used when the map size is unknown)
local HEARTBEAT = 30
local MOVE_THRESH, FAST_MOVE = 5, 2 -- permille
local BACKOFF, LOCKDOWN_BACKOFF = 15, 60
local VERSION_EVERY = 600 -- seconds between version announcements
local floor, abs = math.floor, math.abs
local R = Enum and Enum.SendAddonMessageResult

local running, sendTicker, expireTicker
local pending, pVer, pMap, pX, pY
local lastSent, backoffUntil, nextVer, lastTick = 0, 0, 0, 0
local fast = false
local lastMap, lastX, lastY
local sentText, sentAt = nil, 0
local st = { sent = 0, fail = 0, recv = 0, own = 0, bad = 0, rej = 0 }
Comms.stats = st

local function ownPos()
  local map, x, y = ns.OwnPos.Get()
  if map then return map, floor(x * 1000 + 0.5), floor(y * 1000 + 0.5) end
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
    local t = fast and FAST_MOVE or MOVE_THRESH
    local moved = m ~= lastMap or abs(x - lastX) > t or abs(y - lastY) > t
    if moved or now - lastSent >= HEARTBEAT then
      pending, pVer, pMap, pX, pY = ns.Wire.Pos(m, x, y), false, m, x, y -- replaces any older one
    end
  end
  flush(now)
end

-- Is another sharing guildmate within minimap range of this position (permille)?
local function peerNear(m, x, y)
  local w, h = ns.MiniView.MapYards(m)
  for name, peer in ns.Roster.Iterate() do
    if peer.mapID == m and not ns.Roster.IsSelf(name) then
      local dx, dy = (peer.x - x) / 1000, (peer.y - y) / 1000
      if w then
        if (dx * w) ^ 2 + (dy * h) ^ 2 <= NEAR_YARDS ^ 2 then return true end
      elseif (dx * 1000) ^ 2 + (dy * 1000) ^ 2 <= NEAR_PERMILLE ^ 2 then
        return true
      end
    end
  end
  return false
end

-- Runs every second and decides whether this is a tick: every 5s normally, every 2s with someone nearby.
function Comms.Pulse()
  if not running then return end
  local m, x, y = ownPos()
  fast = m ~= nil and peerNear(m, x, y)
  local now = GetTime()
  if now - lastTick >= (fast and FAST_TICK or SLOW_TICK) then
    lastTick = now
    Comms.Tick()
  end
end

function Comms.IsFast() return fast end
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
  sendTicker = C_Timer.NewTicker(TICK, Comms.Pulse)
  expireTicker = C_Timer.NewTicker(EXPIRE_TICK, function() ns.Roster.Expire(GetTime()) end)
  lastTick, fast = GetTime(), false
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
