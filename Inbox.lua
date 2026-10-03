local ADDON, ns = ...
local Inbox = {}
ns.Inbox = Inbox

local PREFIX, CHANNEL = ns.Comms.PREFIX, ns.Comms.CHANNEL
local ECHO_WINDOW = 3 -- seconds in which an identical message is treated as our own echo
local st = ns.Comms.stats
local hits = {}
local frame = CreateFrame("Frame")

local function onEvent(_, _, prefix, text, channel, sender)
  if prefix ~= PREFIX or channel ~= CHANNEL then return end
  if issecretvalue and (issecretvalue(text) or issecretvalue(sender)) then return end
  -- Our own echo: identical to what we just sent. Works whatever name format Forever uses for us;
  -- two such matches from one sender mark that sender as us for good.
  local sent, at = ns.Comms.LastSent()
  if text == sent and GetTime() - at < ECHO_WINDOW then
    hits[sender] = (hits[sender] or 0) + 1
    if hits[sender] >= 2 then ns.Roster.MarkSelf(sender) st.learned = sender end
    st.own = st.own + 1
    return
  end
  if ns.Roster.IsSelf(sender) then st.own = st.own + 1 return end
  local kind, a, x, y = ns.Wire.Decode(text)
  if not kind then st.bad = st.bad + 1 return end
  -- Belt and braces: the server already restricts GUILD, but also require the sender to be in
  -- our guild roster. nil means the roster has not loaded yet, so only the channel check applies.
  if ns.Classes.IsMember(Ambiguate(sender, "short")) == false then
    st.rej, st.lastRej = st.rej + 1, sender
    ns.Classes.Refresh() -- roster may just be stale (new member)
    return
  end
  st.recv, st.lastSender = st.recv + 1, sender
  if kind == "POS" then
    ns.Roster.Update(sender, a, x, y)
  elseif kind == "OFF" then
    ns.Roster.Remove(sender)
  else -- "VER"
    ns.Version.Note(a)
  end
end
frame:SetScript("OnEvent", onEvent)

function Inbox.Start()
  wipe(hits)
  frame:RegisterEvent("CHAT_MSG_ADDON")
end

function Inbox.Stop()
  frame:UnregisterEvent("CHAT_MSG_ADDON")
end
