local ADDON, ns = ...

-- Key binding: hold to hide names on the map. The binding itself is declared in Bindings.xml and
-- calls the one global function below; the two BINDING_ strings are how the game labels it.
BINDING_HEADER_WHEREABOUTS = "Whereabouts"
BINDING_NAME_WHEREABOUTS_HIDE_NAMES = "Hold to hide names on the map"

function WhereaboutsHideNamesKey(keystate)
  ns.Pins.SetNamesHeld(keystate == "down")
end
