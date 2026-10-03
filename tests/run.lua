-- Runs every tests/test_*.lua from the addon root: `lua5.1 tests/run.lua` (or `make test`).
local say = print -- tests may replace the global print; keep our own
local files = {}
local p = io.popen("ls tests/test_*.lua")
for line in p:lines() do files[#files + 1] = line end
p:close()
table.sort(files)

local failed = 0
for _, file in ipairs(files) do
  local ok, err = pcall(dofile, file)
  if ok then
    say("PASS  " .. file)
  else
    failed = failed + 1
    say("FAIL  " .. file .. "\n      " .. tostring(err))
  end
end
say(failed == 0 and ("all " .. #files .. " test files passed") or (failed .. " of " .. #files .. " failed"))
os.exit(failed == 0 and 0 or 1)
