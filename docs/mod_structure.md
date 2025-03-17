# **Mod Structure and File Organization**

## Essential Mod Files
Each DST mod consists of three primary files:

1. **`modinfo.lua`** - Contains metadata:
   - `api_version = 10` (required for DST mods)
   - Compatibility settings (`dst_compatible = true`)
   - `all_clients_require_mod` (determines if clients need the mod to join)
   - Mod configuration options

2. **`modmain.lua`** - The main execution file:
   - Registers prefabs, components, and event hooks
   - Modifies game mechanics via API functions

3. **`modworldgenmain.lua`** (optional) - Used if the mod alters world generation:
   - Adjusts terrain, resources, and spawn points

## Folder Structure
- `scripts/`: Contains all Lua scripts (prefabs, components, stategraphs, etc.)
- `images/`: Stores textures (`.tex` files) and atlases (`.xml` files)
- `anim/`: Contains compiled animation `.zip` files
- `sound/`: Holds `.fsb` sound banks for FMOD integration
- `exported/`: Spriter animation sources for auto-compilation

## Initialization Process
- `modinfo.lua` loads first to declare metadata.
- `modmain.lua` executes to register assets and hooks.
- `modworldgenmain.lua` runs (if present) before world generation.

Following this structured approach ensures **better maintainability and compatibility** with other mods.
