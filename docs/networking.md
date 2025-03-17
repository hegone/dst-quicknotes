# **Networking and Multiplayer Considerations**

## Client-Server Synchronization
DST runs on a **client-server model**:
- **The server is authoritative** over world state and logic.
- Clients predict certain actions (e.g., movement) but must sync with the server.

## NetVars (Server → Client Sync)
- **NetVars** efficiently synchronize data between the server and clients.
- Example:
  ```lua
  inst.mystate = net_bool(inst.GUID, "mymod.mystate", "mystatedirty")
  inst:ListenForEvent("mystatedirty", function(inst)
      print("State changed:", inst.mystate:value())
  end)
  ```

## RPCs (Client → Server Communication)
- Remote Procedure Calls allow clients to request actions from the server.
- Register an RPC handler:
  ```lua
  AddModRPCHandler("MyMod", "DoSomething", function(player)
      print(player.name .. " triggered an action!")
  end)
  ```
- Trigger from the client:
  ```lua
  SendModRPCToServer(GetModRPC("MyMod", "DoSomething"))
  ```

## Best Practices for Efficient Networking
- **Minimize unnecessary NetVar updates** to reduce bandwidth.
- **Throttle RPC calls** to avoid spamming the server.
- **Use `ismastersim` checks** to avoid executing server-side code on clients.

Understanding these concepts ensures **smooth multiplayer performance and synchronization** in DST mods.
