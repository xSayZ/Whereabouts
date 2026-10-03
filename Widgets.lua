local ADDON, ns = ...
local W = {}
ns.Widgets = W

-- Only the two oldest stock templates (checkbox, standard button), so nothing here depends on
-- newer Blizzard dropdown or slider widgets that may differ on Forever.
local ROW_W, ROW_H = 330, 26

local function row(parent)
  local r = CreateFrame("Frame", nil, parent)
  r:SetSize(ROW_W, ROW_H)
  return r
end

local function label(r, text)
  local fs = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  fs:SetPoint("LEFT", 4, 0)
  fs:SetText(text)
  return fs
end

local function button(r, text, w)
  local b = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
  b:SetSize(w, 22)
  b:SetText(text)
  return b
end

-- get() -> boolean, set(boolean)
function W.Check(parent, text, get, set)
  local r = row(parent)
  local cb = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
  cb:SetPoint("LEFT")
  local fs = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
  fs:SetText(text)
  cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
  r.Refresh = function() cb:SetChecked(get()) end
  return r
end

-- get() -> number, bump(direction) with direction -1 or +1, fmt(number) -> text
function W.Step(parent, text, get, bump, fmt)
  local r = row(parent)
  label(r, text)
  local plus = button(r, "+", 24)
  plus:SetPoint("RIGHT")
  local val = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  val:SetPoint("RIGHT", plus, "LEFT", -6, 0)
  val:SetWidth(46)
  local minus = button(r, "-", 24)
  minus:SetPoint("RIGHT", val, "LEFT", -6, 0)
  plus:SetScript("OnClick", function() bump(1) end)
  minus:SetScript("OnClick", function() bump(-1) end)
  r.Refresh = function() val:SetText(fmt(get())) end
  return r
end

-- Click to move to the next choice. get() -> display text, advance()
function W.Cycle(parent, text, get, advance)
  local r = row(parent)
  label(r, text)
  local b = button(r, "", 150)
  b:SetPoint("RIGHT")
  b:SetScript("OnClick", advance)
  r.Refresh = function() b:SetText(get()) end
  return r
end

function W.Button(parent, text, w, onClick)
  local r = row(parent)
  local b = button(r, text, w)
  b:SetPoint("LEFT", 4, 0)
  b:SetScript("OnClick", onClick)
  r.Refresh = function() end
  return r
end

-- Read-only box whose text can be selected and copied (the game cannot open web links).
function W.CopyBox(parent, width)
  local ok, e = pcall(CreateFrame, "EditBox", nil, parent, "InputBoxTemplate")
  if not ok then e = CreateFrame("EditBox", nil, parent) end
  e:SetSize(width, 22)
  e:SetAutoFocus(false)
  e:SetFontObject("GameFontHighlightSmall")
  e:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
  e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  e:SetScript("OnTextChanged", function(self)
    if self.want and self:GetText() ~= self.want then self:SetText(self.want) end
  end)
  e.SetValue = function(self, t) self.want = t self:SetText(t) self:SetCursorPosition(0) end
  return e
end
