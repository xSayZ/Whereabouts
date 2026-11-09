local S = dofile("tests/stubs.lua"); S.install()
local ns = S.ns(); S.load(ns, { "Defaults", "Options", "Names", "Themes" })
local O = ns.Options

-- Before Init the defaults are served, so nothing sees a nil
assert(O.Get("enabled") == true and O.Get("size") == 1.0)
assert(O.Set("size", 2) == false, "Set before Init must be refused")

-- Init fills defaults, cleans bad saved values, migrates the 0.1/0.2 name
WhereaboutsDB = { size = 99, alpha = "abc", theme = "nope", hideMinimap = true, enabled = "yes", minimapAngle = 1.5 }
O.Init()
assert(WhereaboutsDB.size == 2.0, "clamped to range max")
assert(WhereaboutsDB.alpha == 1.0, "unusable number falls back to default")
assert(WhereaboutsDB.theme == "classic", "unknown theme falls back to default")
assert(WhereaboutsDB.minimapButton == false and WhereaboutsDB.hideMinimap == nil, "old name migrated")
assert(WhereaboutsDB.enabled == true, "saved opt-in preserved")
assert(WhereaboutsDB.minimapAngle == 1.5, "unrelated saved data untouched")
assert(WhereaboutsDB.labels == true and WhereaboutsDB.mapButton == false)

-- Set validates and notifies only on a real change
local seen = {}
O.Subscribe(function(k, v) seen[#seen + 1] = k .. "=" .. tostring(v) end)
assert(O.Set("size", 0.74) and O.Get("size") == 0.7, "snapped to step, no float noise")
assert(O.Set("size", 0.7) == false and #seen == 1, "no change, no notification")
assert(O.Set("alpha", 0) and O.Get("alpha") == 0.2, "below minimum clamps up")
assert(O.Set("labels", false) and O.Get("labels") == false)
assert(O.Set("labels", "yes") and O.Get("labels") == true, "booleans are coerced (Lua: only nil/false are false)")
assert(O.Set("theme", "does-not-exist") == false and O.Get("theme") == "classic")
assert(O.Set("theme", "solid") and O.Get("theme") == "solid")
assert(O.Set("unknown-key", 1) == false)

-- Reset restores appearance but never touches the sharing switch
O.Set("enabled", false); O.Set("enabled", true)
O.Reset()
assert(O.Get("size") == 1.0 and O.Get("theme") == "classic" and O.Get("labels") == true)
assert(O.Get("enabled") == true, "reset must not change who can see you")
assert(ns.Defaults.enabled == true, "sharing defaults to on")

-- 0.5.0 migration: an existing install saved as off is switched on once; later choices stick
WhereaboutsDB = { enabled = false, size = 1.5 }
O.switchedOn = nil; O.Init()
assert(WhereaboutsDB.enabled == true and O.switchedOn == true and WhereaboutsDB.onByDefault == true, "old off switched on")
O.Set("enabled", false); O.switchedOn = nil; O.Init()
assert(WhereaboutsDB.enabled == false and O.switchedOn == nil, "off chosen after the switch is kept")
WhereaboutsDB = nil; O.Init()
assert(WhereaboutsDB.enabled == true and O.switchedOn == nil, "fresh install: on, nothing to announce")
