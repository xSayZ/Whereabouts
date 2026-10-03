-- Static checks for the addon files (tests are excluded: they replace globals on purpose).
std = "lua51"
max_line_length = false
exclude_files = { "tests/**", "dist/**", ".git/**" }

-- `local ADDON, ns = ...` is the standard addon header; not every file needs ADDON.
ignore = { "211/ADDON", "212" } -- unused ADDON, unused arguments (event handlers)

-- Globals this addon defines (keep in sync with the list in CLAUDE.md).
globals = {
  "WhereaboutsDB",
  "SlashCmdList", "SLASH_WHEREABOUTS1",
  "WhereaboutsHideNamesKey", "BINDING_HEADER_WHEREABOUTS", "BINDING_NAME_WHEREABOUTS_HIDE_NAMES",
}

-- WoW API this addon reads. Add a name here when you start using a new one.
read_globals = {
  "AddonCompartmentFrame", "Ambiguate", "CLASS_ICON_TCOORDS", "C_AddOns", "C_ChatInfo", "C_GuildInfo",
  "C_Map", "C_Timer", "CreateFrame", "Enum", "GameTooltip", "GetAddOnMetadata", "GetCursorPosition",
  "GetGuildRosterInfo", "GetNumGuildMembers", "GetTime", "GuildRoster", "IsInGuild", "IsInInstance",
  "Minimap", "RAID_CLASS_COLORS", "Settings", "UIParent", "UnitName", "WorldMapFrame", "format",
  "hooksecurefunc", "issecretvalue", "strlower", "strtrim", "wipe",
}

-- The only code in this file is a commented-out example, so `ns` looks unused.
files["UserThemes.lua"] = { ignore = { "211" } }
