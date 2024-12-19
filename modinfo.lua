name = "Quick Notes"
description = 

[[A handy notepad for jotting down notes that persist across worlds, caves, and game restarts.

Features:
- Draggable window (drag title bar)
- Auto-saves every 30 seconds
- Supports up to 10,000 characters
- Click outside to close

Keyboard Shortcuts:
- Press N (configurable) to toggle
- Ctrl+S to save manually
- ESC to close
- Enter for new lines]]

author = "Lumen"
version = "0.1.1"

-- DST compatibility
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
all_clients_require_mod = false
client_only_mod = true

-- Mod icon (removed to resolve warning)
modicon = "modicon.tex"
icon_atlas = "modicon.xml"

-- Configuration options
configuration_options = {
    {
        name = "TOGGLE_KEY",
        label = "Toggle Key",
        hover = "Key to toggle the notepad",
        options = {
            {description = "N", data = "KEY_N"},
            {description = "H", data = "KEY_H"},
            {description = "J", data = "KEY_J"},
            {description = "P", data = "KEY_P"},
        },
        default = "KEY_N",
    }
} 