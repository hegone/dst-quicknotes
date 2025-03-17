# **Prefab and Entity Management**

## Prefab Structure and Lifecycle
- **Prefabs** define all game objects (items, creatures, structures).
- Created using `Prefab(name, fn, assets, dependencies)`.
- Example of a simple prefab:
  ```lua
  local function fn()
      local inst = CreateEntity()
      inst.entity:AddTransform()
      inst.entity:AddAnimState()
      inst.entity:AddNetwork()
      inst.AnimState:SetBank("myobject")
      inst.AnimState:SetBuild("myobject")
      if not TheWorld.ismastersim then return inst end
      inst:AddComponent("inventoryitem")
      return inst
  end
  return Prefab("myobject", fn, {Asset("ANIM", "anim/myobject.zip")})
  ```

## Entity Components
- Components add behaviors to prefabs (`inst:AddComponent("component")`).
- Access components via `inst.components.<name>`.
- Components can store state and handle events.

## Stategraph and Behavior System
- **Stategraphs (SG)** control animations and states.
- **Brains** manage AI behavior for creatures.
- Adding a custom action:
  ```lua
  AddAction("CUSTOM_ACTION", "Do Something", function(act)
      -- Custom action logic here
      return true
  end)
  ```

## Prefab Post-Initialization Hooks
Modify existing prefabs safely:
```lua
AddPrefabPostInit("berrybush", function(inst)
    if TheWorld.ismastersim then
        inst:AddComponent("talker")
        inst.components.talker:Say("I'm a talking berry bush!")
    end
end)
```

Following these practices ensures **efficient and flexible entity management** in DST mods.
