-- The release helper scripts, run for real through bash.
local function sh(cmd)
  local p = io.popen(cmd .. ' 2>&1; echo "EXIT:$?"')
  local out = p:read("*a")
  p:close()
  local code = tonumber(out:match("EXIT:(%d+)%s*$"))
  return code, (out:gsub("EXIT:%d+%s*$", ""):gsub("%s+$", ""))
end
local toc = assert(io.open("Whereabouts.toc")):read("*a")
local version = toc:match("## Version:%s*(%S+)")

-- check-tag: accepts the current version (and its alpha/beta tags), refuses everything else
local code, out = sh("bash scripts/check-tag.sh v" .. version)
assert(code == 0 and out == version, out)
assert(sh("bash scripts/check-tag.sh v" .. version .. "-beta.2") == 0)
assert(sh("bash scripts/check-tag.sh v" .. version .. "-alpha.1") == 0)
for _, bad in ipairs({ "v99.0.0", version, "v" .. version .. "-rc.1", "v" .. version .. "-gamma.1", "v1.2", "", "vX.Y.Z" }) do
  assert(sh("bash scripts/check-tag.sh '" .. bad .. "'") ~= 0, "accepted tag: '" .. bad .. "'")
end

-- release-notes: exactly one section, no neighbours, fails for an unknown version
code, out = sh("bash scripts/release-notes.sh " .. version)
assert(code == 0 and out:find("^### %u") and not out:find("%[0%.2%.0%]") and not out:find("^## "), out:sub(1, 80))
code, out = sh("bash scripts/release-notes.sh 0.2.0")
assert(code == 0 and not out:find("0%.1%.0%]") and not out:find("%[0%.3%.0%]"))
assert(sh("bash scripts/release-notes.sh 9.9.9") ~= 0, "unknown version must fail")
assert(sh("bash scripts/release-notes.sh nonsense") ~= 0)

-- check-zip: a good zip passes; stray repo files, a missing TOC file, or a second top folder fail
if sh("command -v zip") ~= 0 then print("  (zip not installed: check-zip tests skipped)") return end
local tmp = select(2, sh("mktemp -d"))
local function build(name, files, extra)
  sh(string.format("rm -rf %s/%s && mkdir -p %s/%s/Whereabouts", tmp, name, tmp, name))
  sh(string.format("cp %s %s/%s/Whereabouts/", files, tmp, name))
  if extra then sh(string.format("cd %s/%s && %s", tmp, name, extra)) end
  sh(string.format("cd %s/%s && zip -qr out.zip *", tmp, name))
  return string.format("%s/%s/out.zip", tmp, name)
end
local runtime = "Whereabouts.toc Bindings.xml *.lua README.md CHANGELOG.md"
code, out = sh("bash scripts/check-zip.sh " .. build("good", runtime))
assert(code == 0 and out:find("zip layout ok"), out)
assert(sh("bash scripts/check-zip.sh " .. build("leak", runtime, "mkdir Whereabouts/tests && echo x > Whereabouts/tests/t.lua")) ~= 0, "tests/ leaked")
assert(sh("bash scripts/check-zip.sh " .. build("make", runtime, "echo x > Whereabouts/Makefile")) ~= 0, "Makefile leaked")
assert(sh("bash scripts/check-zip.sh " .. build("missing", runtime, "rm Whereabouts/Core.lua")) ~= 0, "TOC file missing")
assert(sh("bash scripts/check-zip.sh " .. build("nobind", "Whereabouts.toc *.lua README.md CHANGELOG.md")) ~= 0, "Bindings.xml missing")
assert(sh("bash scripts/check-zip.sh " .. build("stray", runtime, "echo x > stray.txt")) ~= 0, "file outside Whereabouts/")
sh("rm -rf " .. tmp)
