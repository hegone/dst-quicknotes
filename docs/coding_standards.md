# **Lua Coding Standards**

## Variable Scope and Namespace
- **Use `local` for variables and functions** to avoid global namespace pollution.
- Access global game objects via `GLOBAL`, e.g., `GLOBAL.ThePlayer`.
- **Avoid modifying global tables directly** to prevent conflicts with other mods.

## Object-Oriented Patterns in DST
- DST uses a **class system** (`Class(parent, constructor_fn)`) for widgets and components.
- Call **parent methods** using `_base`, e.g.:
  ```lua
  function MyClass:OnGainFocus()
      MyClass._base.OnGainFocus(self)
  end
  ```

## Function Overriding Best Practices
- **Save original functions** before modifying:
  ```lua
  local _old_fn = SomeComponent.SomeFunction
  function SomeComponent:SomeFunction(...)
      _old_fn(self, ...)
      -- Custom logic here
  end
  ```

## Error Handling and Debugging
- Use `pcall(fn, ...)` to catch errors without crashing.
- Debug via `print()` statements in `client_log.txt` and `server_log.txt`.

## Memory Management Best Practices
- Remove unused references to allow **garbage collection**.
- Clean up event listeners and scheduled tasks:
  ```lua
  inst:RemoveEventCallback("event", callback_fn)
  inst:DoTaskInTime(0, function() end) -- One-time task
  ```

Adhering to these coding standards ensures **stability, maintainability, and compatibility** for DST mods.
