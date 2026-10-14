local S = dofile("tests/stubs.lua"); S.install()
local ns = S.ns(); S.loadAll(ns, "Core")
ns.Options.Init()
local C = ns.Comms
ns.Version.current = "0.5.0"
local function positions() local n = 0 for _, s in ipairs(S.sent) do if s.msg:find("^1|%d+|") then n = n + 1 end end return n end

-- Nobody nearby: checks every 5 seconds, 5 permille threshold (a 3 permille step is not sent)
C.Start(); assert(positions() == 1 and C.IsFast() == false)
ns.Roster.Update("Bob-Realm", 1429, 900, 500) -- 1600 yards away
S.pos.x = 0.503
for t = 101, 106 do S.now = t C.Pulse() end
assert(positions() == 1 and C.IsFast() == false, "still below the threshold, no one near")

-- Someone within 300 yards: fast mode, checks every 2 seconds, 2 permille threshold
ns.Roster.Update("Bob-Realm", 1429, 520, 500) -- 80 yards east
S.now = 107; C.Pulse(); assert(C.IsFast() == true and positions() == 2, "3 permille counts as movement in fast mode")
S.pos.x = 0.506; S.now = 108; C.Pulse(); assert(positions() == 2, "not due yet, 2s have not passed since the last check")
S.now = 109; C.Pulse(); assert(positions() == 3, "checked again after 2s")
S.pos.x = 0.5065; S.now = 111; C.Pulse(); assert(positions() == 3, "under 2 permille")

-- Other map, or yourself nearby, does not trigger fast mode
ns.Roster.Update("Bob-Realm", 1436, 500, 500); S.now = 113; C.Pulse(); assert(C.IsFast() == false)
ns.Roster.Update("Bob-Realm", 1429, 900, 500); ns.Roster.Update("Me", 1429, 500, 500)
S.now = 115; C.Pulse(); assert(C.IsFast() == false, "own entry does not count")

-- Unknown map size: falls back to a permille radius
S.yards[1429] = nil
local ns2 = ns; ns2.MiniView.MapYards(0) -- (cache is per map id; use a fresh map)
S.pos.map = 77; S.yards[77] = nil
ns.Roster.Update("Zed-Realm", 77, 540, 500); S.now = 120; C.Pulse(); assert(C.IsFast() == true, "40 permille is near")
ns.Roster.Update("Zed-Realm", 77, 700, 500); S.now = 125; C.Pulse(); assert(C.IsFast() == false)

-- Stopped means silent
C.Stop(false); local n = #S.sent; S.now = 200; C.Pulse(); assert(#S.sent == n)
