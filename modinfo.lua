name = "Quick Notes"
description = "A handy notepad for jotting down notes that persist across caves and reloads!"
author = "Lumen"
version = "1.0.0"

-- DST compatibility
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
all_clients_require_mod = false
client_only_mod = true

-- Mod icon (removed to resolve warning)

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