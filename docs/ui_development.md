# **User Interface Development**

## Widget System Overview
DST’s UI is built using **widget-based hierarchy**.
- **Base classes:** `Widget`, `Screen`, `Text`, `ImageButton`
- **HUD structure:** `PlayerHud` → `Controls` → UI elements

## Creating a Custom Screen
1. Import UI components:
   ```lua
   local Screen = GLOBAL.require "widgets/screen"
   local Text = GLOBAL.require "widgets/text"
   local ImageButton = GLOBAL.require "widgets/imagebutton"
   ```
2. Define a screen class:
   ```lua
   local MyScreen = Class(Screen, function(self)
       Screen._ctor(self, "MyScreen")
       self.label = self:AddChild(Text(UIFONT, 30, "Hello World"))
   end)
   ```
3. Display with `TheFrontEnd:PushScreen(MyScreen())`.

## UI Positioning and Anchoring
- **Coordinates**: (0,0) is center, Y increases upwards.
- **Anchor points**:
  - `ANCHOR_TOP`, `ANCHOR_LEFT`, `ANCHOR_MIDDLE`
  - Use `SetVAnchor()` and `SetHAnchor()` for alignment.
- **Scaling Modes**:
  - `SCALEMODE_PROPORTIONAL` (default)
  - `SCALEMODE_FILLSCREEN` (for full-screen UI)

## Handling User Input
- Override `OnControl()` in custom screens to handle keys.
- For global hotkeys:
  ```lua
  TheInput:AddKeyHandler(function(key)
      if key == GLOBAL.KEY_T then 
          TheFrontEnd:PushScreen(MyScreen())
      end
  end)
  ```

By following these guidelines, you can create **efficient, scalable, and user-friendly** UI elements in DST mods.
