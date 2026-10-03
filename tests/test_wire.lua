local S = dofile("tests/stubs.lua"); S.install()
local ns = S.ns(); S.load(ns, { "Wire" })
local W = ns.Wire

assert(W.Pos(37, 500, 250) == "1|37|500|250")
assert(W.Off() == "1|OFF")
assert(W.Ver("0.3.0") == "1|V|0.3.0")

local k, m, x, y = W.Decode("1|37|500|250")
assert(k == "POS" and m == 37 and x == 500 and y == 250)
assert(W.Decode("1|OFF") == "OFF")
local kv, v = W.Decode("1|V|10.20.30")
assert(kv == "VER" and v == "10.20.30")

local bad = { "2|37|500|250", "1|37|1001|5", "1|a|b|c", "", "1|37|5", "garbage", "1|37|5|5|5",
  "2|37|500|250|a1b2c3", "1|V|1.2", "1|V|a.b.c", "1|V|1.2.3.4", "1|v|1.2.3", 5, false }
for _, b in ipairs(bad) do assert(W.Decode(b) == nil, "accepted: " .. tostring(b)) end
assert(W.Decode(string.rep("1", 40)) == nil, "over-long message accepted")
