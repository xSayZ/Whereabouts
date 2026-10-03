local S = dofile("tests/stubs.lua"); S.install()
S.myName = "Beta Spectator"
S.roster = { { "Alice-Realm", "MAGE" }, { "Cnas Ohlson-Realm", "WARRIOR" }, { "Beta Spectator-Realm", "MAGE" } }
local ns = S.ns(); S.loadAll(ns, "Core")
ns.Version.current = "0.3.0"
ns.Classes.Start()
ns.Comms.Start()
local handle = S.frameWithEvent("CHAT_MSG_ADDON").scripts.OnEvent
local function recv(text, sender, channel, prefix) handle(nil, "CHAT_MSG_ADDON", prefix or "WHRBT", text, channel or "GUILD", sender) end
local st = ns.Comms.stats

-- Guild only: every other channel and prefix is ignored
for _, ch in ipairs({ "PARTY", "RAID", "WHISPER", "SAY", "YELL", "INSTANCE_CHAT", "OFFICER", "CHANNEL", "guild" }) do
  recv("1|1429|500|250", "Alice-Realm", ch)
end
recv("1|1429|500|250", "Alice-Realm", "GUILD", "OTHER")
assert(ns.Roster.Count() == 0, "accepted a non-guild channel or wrong prefix")

-- A guildmate is accepted, gets updated, and is removed on OFF
recv("1|1429|500|250", "Alice-Realm"); assert(ns.Roster.Count() == 1)
recv("1|1429|510|250", "Alice-Realm"); assert(ns.Roster.Count() == 1)
recv("1|OFF", "Alice-Realm"); assert(ns.Roster.Count() == 0)

-- Sender not in the guild roster is rejected (roster is loaded), and a roster refresh is requested
recv("1|1429|500|250", "Stranger-Elsewhere")
assert(ns.Roster.Count() == 0 and st.rej == 1 and st.lastRej == "Stranger-Elsewhere")

-- Malformed and other-version messages are counted, never stored
recv("garbage", "Alice-Realm"); recv("2|1429|1|1", "Alice-Realm"); recv("1|1429|9999|1", "Alice-Realm")
assert(ns.Roster.Count() == 0 and st.bad == 3)

-- Self by name, in several formats
for _, n in ipairs({ "Beta Spectator", "Beta Spectator-Realm", "beta spectator-realm", "BETA SPECTATOR", "Betaspectator-Some Realm" }) do
  recv("1|1433|646|388", n)
end
assert(ns.Roster.Count() == 0, "self leaked in by name")
ns.Roster.Update("Beta Spectator", 1433, 1, 1); assert(ns.Roster.Count() == 0, "Roster.Update accepted self")

-- Self by echo, when the sender name matches nothing about us. Use real position messages
-- (a due version announcement would take a tick's slot, so spend that tick first).
S.now = 200; ns.Comms.Tick()
local function nextPosition(t, x) S.now, S.pos.x = t, x ns.Comms.Tick() return S.sent[#S.sent].msg end
local mine = nextPosition(205, 0.61)
assert(mine:find("^1|1429"), mine)
recv(mine, "Totally Different"); assert(ns.Roster.Count() == 0 and st.learned == nil, "first echo dropped, nothing learned yet")
local again = nextPosition(210, 0.72)
recv(again, "Totally Different")
assert(st.learned == "Totally Different", "second echo learns the sender")
recv("1|1433|700|400", "Totally Different"); assert(ns.Roster.Count() == 0, "learned self stays hidden")

-- A friend is never hidden by the self checks
recv("1|1429|605|502", "Cnas Ohlson-Realm"); assert(ns.Roster.Count() == 1)

-- Version announcements: only newer versions matter, and they go through the same guild checks
recv("1|V|0.3.0", "Alice-Realm"); recv("1|V|0.2.0", "Alice-Realm"); assert(ns.Version.newest == nil)
recv("1|V|0.9.0", "Stranger-Elsewhere"); assert(ns.Version.newest == nil, "a stranger cannot announce a version")
recv("1|V|0.9.0", "Alice-Realm"); assert(ns.Version.newest == "0.9.0")

-- Roster not loaded yet: cannot verify, so the guild channel alone applies (documented fail-open)
S.rosterLoaded = false
local ns2 = S.ns(); S.loadAll(ns2, "Core"); ns2.Comms.Start()
local h2 = S.frameWithEvent("CHAT_MSG_ADDON").scripts.OnEvent
h2(nil, "CHAT_MSG_ADDON", "WHRBT", "1|1429|1|1", "GUILD", "Whoever-Realm")
assert(ns2.Roster.Count() == 1)
h2(nil, "CHAT_MSG_ADDON", "WHRBT", "1|1429|1|1", "PARTY", "Other-Realm")
assert(ns2.Roster.Count() == 1, "wrong channel still rejected")
