--[[
    Quick Notes - Mod Information
    
    This file defines metadata and configuration options for the Quick Notes mod.
    It provides information to the game about compatibility, versioning, and
    user-configurable settings.
]]

-- Basic mod information
name = "Quick Notes"
description = 
[[A handy notepad for jotting down notes that persist across worlds, caves, and game restarts.

Features:
- Draggable window (drag title bar)
- Auto-saves every 30 seconds
- Supports up to 10,000 characters
- Full keyboard navigation with arrow keys, Home/End, Page Up/Down
- White cursor for better visibility
- Click outside to close

Keyboard Shortcuts:
- Press N (configurable) to toggle
- Ctrl+S to save manually
- Ctrl+R to reset
- ESC to close
- Arrow keys to navigate
- Home/End to jump to start/end of line
- Page Up/Down to navigate through longer notes
- Enter for new lines]]

author = "Lumen"
version = "0.4.0"

--[[ Compatibility Settings
    These flags determine which game versions can use the mod:
    - dst_compatible: Don't Starve Together support
    - dont_starve_compatible: Single-player Don't Starve support
    - reign_of_giants_compatible: ROG DLC support
    - all_clients_require_mod: Whether all players need the mod
    - client_only_mod: Whether the mod only runs on clients
]]

api_version = 10
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
all_clients_require_mod = false
client_only_mod = true

-- Mod icon configuration
icon = "modicon.tex"
icon_atlas = "modicon.xml"

--[[ Configuration Options
    These options appear in the mod configuration menu and allow users
    to customize the mod's behavior. Each option requires:
    - name: Internal identifier
    - label: Display name in the UI
    - hover: Tooltip text
    - options: Array of possible values
    - default: Default selection
]]
configuration_options = {
    {
        name = "TOGGLE_KEY",          -- Internal name for the setting
        label = "Toggle Key",         -- Display name in mod options
        hover = "Key to toggle the notepad",  -- Tooltip text
        options = {
            {description = "N", data = "KEY_N"},  -- Default option
            {description = "H", data = "KEY_H"},  -- Alternative keys
            {description = "J", data = "KEY_J"},
            {description = "P", data = "KEY_P"},
        },
        default = "KEY_N",           -- Default key binding
    }
}