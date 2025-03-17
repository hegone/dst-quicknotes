# **Asset Management and Graphics**

## Texture and Atlas Files
DST uses **.tex** textures and **.xml** atlases:
- Convert PNGs to `.tex` using **Klei's autocompiler**.
- Example atlas structure:
  ```xml
  <Atlas>
      <Texture filename="myimage.tex" />
      <Elements>
          <Element name="myimage.tex" u1="0" u2="1" v1="0" v2="1" />
      </Elements>
  </Atlas>
  ```
- **Inventory icons** must be **64x64 pixels**.

## Animations (Spriter and .zip)
- DST uses **Spriter** (`.scml` files) for animations.
- Compiled into `.zip` containing `anim.bin` and `build.bin`.
- Prefabs must set animation bank and build:
  ```lua
  inst.AnimState:SetBank("myanim")
  inst.AnimState:SetBuild("myanim")
  inst.AnimState:PlayAnimation("idle")
  ```

## Using Existing Assets
- Reuse game assets where possible:
  ```lua
  inst.AnimState:SetBuild("rabbit") -- Use the default rabbit build
  ```
- UI elements can reference existing game atlases:
  ```lua
  local bg = self:AddChild(Image("images/global.xml", "square.tex"))
  ```

## Sound Assets
- DST uses **FMOD** for sound.
- Custom sounds are stored in `.fsb` banks and referenced:
  ```lua
  inst.SoundEmitter:PlaySound("mod_sounds/mysound")
  ```

## Optimization Tips
- Keep texture sizes reasonable (power of two dimensions preferred).
- Avoid excessive animations or large UI textures.

Following these guidelines ensures **efficient asset handling** in DST mods.
