# **Game Architecture and Environment**

## Core Structure and Shard System
*Don't Starve Together* (DST) operates on a **client-server model** with optional **shards** to handle multi-level worlds (e.g., overworld and caves). 
- **Master server:** Runs game logic, AI, physics, and governs state changes.
- **Clients:** Handle rendering, input, and predictive movement.
- **Shard Communication:** Servers communicate between shards using RPC messages.

### Client-Server Dynamics
- **Server is authoritative:** Clients send requests; server confirms and synchronizes.
- **Local prediction:** Clients simulate movement before server confirmation for responsiveness.
- **Remote Procedure Calls (RPCs):** Used for client-to-server communication.
- **NetVars:** Synchronize data from server to clients in a bandwidth-efficient manner.

## API Capabilities and Limitations
- DST provides a Lua-based **modding API**.
- **Sandboxed environment:** Mod code runs in isolation to prevent global variable conflicts.
- **No direct file I/O:** Data storage is handled via `TheSim:SetPersistentString`.
- **Engine constraints:** Certain low-level rendering, pathfinding, and networking features are inaccessible.

## Environment Constraints
- **Lua version:** DST uses **Lua 5.1** with some modifications.
- **Memory limitations:** Mods share memory with the game; excessive memory usage can degrade performance.
- **Single-threaded execution:** Expensive calculations must be optimized to avoid frame drops.

Understanding the **architecture** is critical to writing mods that function smoothly within DST’s ecosystem.
