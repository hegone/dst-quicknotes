# QuickNotes: Customization Features

This document explains the customization options available in QuickNotes v0.5.0 and how they're implemented.

## Available Customization Options

QuickNotes now allows users to customize the appearance in several ways:

### Text Color Options

You can change the color of text in the notepad with these preset options:

| Option | Description | RGB Value |
|--------|-------------|-----------|
| White | Clean white text (Default) | `{ r = 1, g = 1, b = 1, a = 1 }` |
| Yellow | Warm yellow tint | `{ r = 1, g = 0.9, b = 0.5, a = 1 }` |
| Light Blue | Soft blue tone | `{ r = 0.6, g = 0.8, b = 1, a = 1 }` |
| Light Green | Gentle green shade | `{ r = 0.6, g = 1, b = 0.6, a = 1 }` |
| Pink | Subtle pink hue | `{ r = 1, g = 0.7, b = 0.9, a = 1 }` |

### Background Color Options

Background colors affect both the frame and title bar:

| Option | Description | RGB Base Value (before opacity) |
|--------|-------------|--------------------------------|
| Dark | Dark grey (Default) | `{ r = 0.1, g = 0.1, b = 0.1 }` |
| Brown | Parchment-like brown | `{ r = 0.25, g = 0.15, b = 0.1 }` |
| Grey | Neutral grey | `{ r = 0.2, g = 0.2, b = 0.23 }` |
| Blue | Dark blue tone | `{ r = 0.1, g = 0.1, b = 0.25 }` |
| Green | Deep forest green | `{ r = 0.1, g = 0.2, b = 0.15 }` |
| Pink | Soft pink shade | `{ r = 0.3, g = 0.1, b = 0.2 }` |

### Transparency Options

You can adjust how transparent the notepad background appears:

| Option | Description | Alpha Value |
|--------|-------------|-------------|
| Solid | Nearly opaque | 0.7 |
| Semi-Transparent | Moderately transparent | 0.5 |
| More Transparent | Quite see-through | 0.3 |
| Very Transparent | Highly transparent | 0.1 |

## Implementation Details

The customization system works by:

1. Defining user options in `modinfo.lua` as configurable settings
2. Loading these settings in `config.lua` using `GetModConfigData()`
3. Converting user selections to RGB color values using mapping tables
4. Applying these colors to UI elements when rendering the notepad

### Color Processing Flow

1. User selects options in the mod configuration menu
2. Settings are loaded when the mod initializes
3. `config.lua` maps selections to appropriate RGBA values 
4. UI components use these values when setting colors

### Key Files

- `modinfo.lua`: Contains the configuration options definitions
- `scripts/notepad/config.lua`: Processes user settings and maps them to actual color values
- `scripts/widgets/notepad_ui.lua`: Applies the colors to visual elements

## Using Custom Colors in Development

When creating new UI elements, use the standard color references from `config.lua` to ensure they respect user customization choices:

```lua
-- Example of using customized colors
local config = require "notepad/config"

my_element:SetTint(
    config.COLORS.FRAME_TINT.r,
    config.COLORS.FRAME_TINT.g,
    config.COLORS.FRAME_TINT.b,
    config.COLORS.FRAME_TINT.a
)
```

## Future Customization Plans

In future versions, we plan to expand customization options with:

- Font selection for different text styles
- Additional color presets with more variety
- Custom theme combinations (preconfigured color sets)
- Individual element coloring (separate title, frame, editor colors)
- Size/scale adjustment options