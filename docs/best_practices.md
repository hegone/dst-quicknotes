# **Community Best Practices and Conventions**

## Code Quality and Documentation
- **Use clear naming conventions** for functions and variables.
- **Add comments** for complex logic and workarounds.
- Include a **README** for large mods with usage instructions.

## Mod Compatibility and Interoperability
- Avoid modifying global game data destructively.
- Use `ModManager.mods` to detect other mods and ensure compatibility:
  ```lua
  for _, mod in ipairs(ModManager.mods) do
      if mod.modinfo.name == "TargetMod" then
          print("Compatible mod detected!")
      end
  end
  ```

## Versioning and Updates
- Use **semantic versioning** (`major.minor.patch`) in `modinfo.lua`.
- Provide a **changelog** on the Steam Workshop page.
- Test updates before publishing to avoid breaking existing saves.

## Publishing and User Support
- **Provide a detailed description** on the Workshop page.
- List **known issues and workarounds**.
- Encourage users to report bugs with `client_log.txt` or `server_log.txt`.

Following these best practices ensures **high-quality, user-friendly, and maintainable** DST mods.
