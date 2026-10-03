local S = dofile("tests/stubs.lua"); S.install()
S.tocVersion = "0.3.0"
local ns = S.ns(); S.load(ns, { "Version" })
local V = ns.Version

assert(V.current == "0.3.0", "version must come from the TOC metadata")
assert(V.Compare("0.3.1", "0.3.0") == 1 and V.Compare("0.3.0", "0.3.1") == -1)
assert(V.Compare("1.0.0", "0.9.9") == 1 and V.Compare("0.10.0", "0.9.0") == 1, "numeric, not string, compare")
assert(V.Compare("1.2.3", "1.2.3") == 0)
assert(V.Compare("1.2", "1.2.3") == nil and V.Compare("x", "1.2.3") == nil and V.Compare(nil, "1.2.3") == nil)

-- Hearing about versions
local shipped = V.UPDATE_URL
assert(shipped:match("^https://github%.com/[%w%-_]+/Whereabouts/releases$"), "shipped update link: " .. shipped)
V.UPDATE_URL = "" -- the unset path
V.Note("0.3.0"); V.Note("0.2.9"); V.Note("junk")
assert(V.newest == nil and #S.printed == 0, "equal, older and garbage versions must be ignored")
V.Note("0.4.0")
assert(V.newest == "0.4.0" and #S.printed == 1)
assert(S.printed[1]:find("0.4.0") and S.printed[1]:find("0.3.0") and S.printed[1]:find("not been set"), S.printed[1])
V.Note("0.4.0"); V.Note("0.3.5")
assert(#S.printed == 1, "must tell the player once per newer version")
V.Note("0.5.0")
assert(V.newest == "0.5.0" and #S.printed == 2)

-- The download link is a plain string that is easy to set
assert(V.Link() == nil)
V.UPDATE_URL = "https://example.invalid/whereabouts"
assert(V.Link() == "https://example.invalid/whereabouts" and V.Message():find("Download: https://example"))

-- And the link that ships is what players are told to visit
V.UPDATE_URL = shipped
assert(V.Message():find(shipped, 1, true))
