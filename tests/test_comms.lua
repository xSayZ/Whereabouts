local S = dofile("tests/stubs.lua"); S.install()
local ns = S.ns(); S.loadAll(ns, "Core")
local C = ns.Comms
ns.Version.current = "0.3.0"

local function positions() local n = 0 for _, s in ipairs(S.sent) do if s.msg:find("^1|%d+|") then n = n + 1 end end return n end
local function last() return S.sent[#S.sent].msg end

-- Start: registers and sends the first position at once. First version announcement is due 10-25s later.
C.Start()
assert(C.IsRunning() and #S.sent == 1 and last() == "1|1429|500|500", last())
assert(S.sent[1].prefix == "WHRBT")

-- Standing still: nothing more until the heartbeat
S.now = 105; C.Tick(); assert(#S.sent == 1, "no resend when still")
S.pos.x = 0.504; S.now = 110; C.Tick(); assert(#S.sent == 1, "4 permille is below the threshold")
S.pos.x = 0.51; S.now = 115; C.Tick(); assert(positions() == 2, "moved past the threshold")

-- The version announcement takes one tick's slot instead of a position (due at 120-125 after start)
S.now = 140; C.Tick()
assert(last() == "1|V|0.3.0" and positions() == 2, "version announcement, got " .. last())
S.now = 145; C.Tick(); assert(positions() == 3, "heartbeat 30s after the last position")

-- Failure backs off, then retries; lockdown backs off longer
S.sendResult = 3; S.pos.x = 0.7; S.now = 150; C.Tick(); assert(positions() == 4 and C.stats.fail == 1)
S.now = 155; C.Tick(); assert(positions() == 4, "backoff holds for 15s")
S.sendResult = 0; S.now = 166; C.Tick(); assert(positions() == 5, "retry after backoff")
S.sendResult = 11; S.pos.x = 0.1; S.now = 170; C.Tick(); assert(positions() == 6)
S.sendResult = 0; S.now = 220; C.Tick(); assert(positions() == 6, "lockdown backs off 60s")

-- Nothing while position is unavailable, in an instance, or out of a guild
S.now = 300; S.pos.x, S.pos.y = 0, 0; local n = #S.sent; C.Tick(); assert(#S.sent == n, "no position")
S.pos.x, S.pos.y = 0.3, 0.3; S.inInstance = true; C.Tick(); assert(#S.sent == n, "instance")
S.inInstance, S.inGuild = false, false; C.Tick(); assert(#S.sent == n, "no guild")
S.inGuild = true

-- Announced at 140, so the next one is due 10 minutes later (740), not before
S.now = 700; S.pos.x = 0.9; C.Tick(); assert(last() ~= "1|V|0.3.0", "not again before 10 minutes")
S.now = 800; S.pos.x = 0.3; C.Tick(); assert(last() == "1|V|0.3.0", "announced again after 10 minutes")
S.pos.x = 0.35; S.now = 805; C.Tick(); assert(last():find("^1|1429"), "position resumes next tick")
assert(C.LastSent() ~= "1|V|0.3.0", "a version message must not be remembered as our position echo")

-- A failed announcement is retried, not dropped
S.now = 1500; S.sendResult = 3; C.Tick()
assert(last() == "1|V|0.3.0" and C.stats.fail >= 1)
local k = #S.sent; S.now = 1505; C.Tick(); assert(#S.sent == k, "backoff applies to announcements too")
S.sendResult = 0; S.now = 1516; C.Tick(); assert(last() == "1|V|0.3.0" and #S.sent == k + 1, "announcement retried")

-- Stop sends one OFF and goes silent; everything went out on the guild channel
C.Stop(true)
assert(last() == "1|OFF" and not C.IsRunning())
local after = #S.sent; S.now = 2000; C.Tick(); assert(#S.sent == after, "stopped means silent")
for _, s in ipairs(S.sent) do assert(s.channel == "GUILD", "sent on " .. tostring(s.channel)) end

-- Sharing off: never send
C.Start(); local j = #S.sent; S.enabled = false; S.now = 3000; C.Tick(); assert(#S.sent == j, "sharing off must be silent")
