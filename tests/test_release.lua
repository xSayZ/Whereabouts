-- Release hygiene: things that must be true before a zip is shared.
local function read(path) local f = assert(io.open(path), "missing " .. path) local s = f:read("*a") f:close() return s end
local function lines(s) local n = 0 for _ in s:gmatch("\n") do n = n + 1 end return n end
local function ls(glob) local t = {} local p = io.popen("ls " .. glob) for l in p:lines() do t[#t + 1] = l end p:close() return t end

local toc = read("Whereabouts.toc")
local version = toc:match("## Version:%s*(%S+)")
assert(version and version:match("^%d+%.%d+%.%d+$"), "TOC version must be x.y.z, got " .. tostring(version))

-- Changelog: newest entry matches the TOC; entries are in descending order
local log = read("CHANGELOG.md")
local entries = {}
for v in log:gmatch("\n## %[(%d+%.%d+%.%d+)%]") do entries[#entries + 1] = v end
assert(entries[1] == version, "CHANGELOG top entry " .. tostring(entries[1]) .. " != TOC " .. version)
local function key(v) local a, b, c = v:match("(%d+)%.(%d+)%.(%d+)") return a * 1e6 + b * 1e3 + c end
for i = 2, #entries do assert(key(entries[i]) < key(entries[i - 1]), "changelog not descending at " .. entries[i]) end

-- TOC lists every .lua file in the folder, each exists, no duplicates
local listed, seen = {}, {}
for l in toc:gmatch("[^\r\n]+") do
  local n = l:match("^(%S+%.lua)%s*$")
  if n then assert(not seen[n], "duplicate in TOC: " .. n) seen[n] = true listed[#listed + 1] = n read(n) end
end
for _, f in ipairs(ls("*.lua")) do assert(seen[f], f .. " is not listed in the TOC") end

-- 150-line cap, one GUILD constant, no leftover debugging
local guild = 0
for _, f in ipairs(listed) do
  local s = read(f)
  assert(lines(s) <= 150, f .. " has " .. lines(s) .. " lines (cap 150)")
  for _ in s:gmatch('"GUILD"') do guild = guild + 1 end
  assert(not s:find("localStorage") and not s:find("print%(%s*[\"']DEBUG"), f .. " has leftover debug output")
end
assert(guild == 1, 'the literal "GUILD" must appear exactly once (Comms.lua), found ' .. guild)

-- Key binding: Bindings.xml calls a function that Keys.lua defines, with the labels the game needs
local xml, keys = read("Bindings.xml"), read("Keys.lua")
local fn = xml:match("(%w+)%(keystate%)")
assert(fn and keys:find("function " .. fn, 1, true), "Bindings.xml calls an undefined function")
local name = xml:match('name="([%w_]+)"')
assert(keys:find("BINDING_NAME_" .. name, 1, true) and keys:find("BINDING_HEADER_", 1, true))

-- Sharing must default to off, and the update link must be a plain string setting
assert(read("Defaults.lua"):find("enabled = false"), "sharing must default to off")
assert(read("Version.lua"):find('Version.UPDATE_URL = ""', 1, true))

-- Shipped docs exist and the README stays short
assert(lines(read("README.md")) <= 60, "README should stay short")
for _, f in ipairs({ "README.md", "CHANGELOG.md" }) do read(f) end

-- .pkgmeta: every top-level file is either shipped to players or explicitly ignored
local ignore = {}
for l in read(".pkgmeta"):gmatch("[^\r\n]+") do
  local n = l:match("^%s*%-%s*(%S+)%s*$")
  if n then ignore[n] = true end
end
local shipped = { ["Whereabouts.toc"] = true, ["Bindings.xml"] = true, ["README.md"] = true, ["CHANGELOG.md"] = true }
for _, e in ipairs(ls("-A")) do
  local ok = e == ".git" or e == ".pkgmeta" or e:match("%.lua$") or e:match("^LICENSE") or shipped[e] or ignore[e]
  assert(ok, e .. " is neither shipped nor listed under ignore: in .pkgmeta (it would leak into the CurseForge zip)")
end

-- Workflows: read-only by default, one writing job, the helper scripts exist, no secrets in job-level if:
local ci, rel = read(".github/workflows/ci.yml"), read(".github/workflows/release.yml")
assert(rel:find("\npermissions:\n  contents: read\n", 1, true), "release workflow must default to read-only")
assert(select(2, rel:gsub("contents: write", "")) == 1, "exactly one release job may write")
assert(not ci:find("contents: write"), "CI must never write")
assert(rel:find("check-tag.sh", 1, true) and rel:find("release-notes.sh", 1, true), "release must verify the tag and use the changelog")
assert(not rel:find("GITHUB_OAUTH:", 1, true), "the packager must not also create the GitHub release")
assert(ci:find("luacheck", 1, true) and ci:find("make test", 1, true) and ci:find("BigWigsMods/packager", 1, true))
for _, wf in ipairs({ ci, rel }) do
  for name in wf:gmatch("scripts/([%w%-]+%.sh)") do read("scripts/" .. name) end
  assert(not wf:find("\n%s*if:[^\n]*secrets%."), "secrets cannot be used in an if: condition")
end
assert(not read(".github/workflows/release.yml"):find("@main") and not ci:find("@main"), "do not track an action's main branch")
