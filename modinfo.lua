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
- Persistent notes between sessions.
- Draggable window (drag title bar).
- Auto-saves every 30 seconds.
- Enhanced Keyboard Navigation:
  - Arrow Keys for multi-line movement.
  - Home/End keys for line start/end.
  - PageUp/PageDown for multi-line jumps.
  - Ctrl+Left/Right Arrow for word jumps.
  - Shift + Navigation Keys for text selection (logical only).
- Customizable text color, background color, and transparency.
- White cursor for better visibility.
- Supports up to 10,000 characters.
- Click outside to close.

Keyboard Shortcuts:
- Press N (configurable) to toggle.
- Ctrl+S to save manually.
- Ctrl+R to reset notepad content.
- ESC to close.
- Arrow keys to navigate char by char.
- Home/End keys to jump to line start/end.
- PageUp/PageDown keys to jump ~10 lines.
- Ctrl+Left/Right Arrow keys to jump word by word.
- Shift + (Arrow/Home/End/Page/Ctrl+Arrow) to select text.
- Enter for new lines.
- Backspace/Delete to remove characters or selection.]]

author = "Lumen"
version = "0.6.0"

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
    },
    {
        name = "TEXT_COLOR",
        label = "Text Color",
        hover = "Change the color of the notepad text",
        options = {
            {description = "White", data = "WHITE"}, 
            {description = "Yellow", data = "YELLOW"},
            {description = "Light Blue", data = "LIGHT_BLUE"},
            {description = "Light Green", data = "LIGHT_GREEN"},
            {description = "Pink", data = "PINK"},
        },
        default = "WHITE",
    },
    {
        name = "BG_COLOR",
        label = "Background Color",
        hover = "Change the background color of the notepad",
        options = {
            {description = "Dark", data = "DARK"},
            {description = "Brown", data = "BROWN"},
            {description = "Grey", data = "GREY"},
            {description = "Blue", data = "BLUE"},
            {description = "Green", data = "GREEN"},
            {description = "Pink", data = "PINK"},
        },
        default = "DARK",
    },
    {
        name = "BG_OPACITY",
        label = "Background Opacity",
        hover = "Adjust the transparency of the notepad background",
        options = {
            {description = "Solid", data = 0.7},
            {description = "Semi-Transparent", data = 0.5},
            {description = "More Transparent", data = 0.3},
            {description = "Very Transparent", data = 0.1},
        },
        default = 0.7,
    }
}