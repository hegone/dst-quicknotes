# Don't Starve Together Modding Constraints and Conventions

## 1. Game Architecture and Environment

### 1.1 Core Game Structure
- **Shard System**: DST divides the world into shards (overworld and caves) that operate as separate instances
- **Client-Server Architecture**: All game logic runs on the server, with clients receiving updates
- **Authority Model**: Server has final authority on game state; client-side mods cannot directly modify server state

### 1.2 API Limitations
- **Engine Access**: Limited to exposed Lua API; no direct C++ engine access
- **Global State**: Game maintains global tables (`_G`, `GLOBAL`) with predefined structure
- **Component System**: Game uses component-based entity architecture

### 1.3 Environment Constraints
- **Lua Version**: DST uses a modified Lua 5.1 implementation
- **Memory Limits**: Limited memory for mod assets and runtime allocation
- **Sandbox Restrictions**: Mods run in a restricted environment with limited file system and network access

## 2. Mod Structure and Organization

### 2.1 Required Files
- **modinfo.lua**: Contains metadata and configuration options
- **modmain.lua**: Primary entry point for mod execution
- **modworldgenmain.lua**: (Optional) For world generation mods

### 2.2 Folder Organization
- **scripts/**: Contains mod-specific Lua scripts
- **scripts/prefabs/**: Prefab definitions
- **scripts/widgets/**: UI widget definitions
- **scripts/components/**: Entity component definitions
- **images/**: Image assets and atlases
- **sound/**: Sound assets
- **anim/**: Animation files

### 2.3 Mod API Integration
- **GetModConfigData()**: Accessing configuration options
- **AddPrefabPostInit()**: Hooking into existing prefabs
- **AddComponentPostInit()**: Hooking into existing components
- **AddPlayerPostInit()**: Hooking into player initialization
- **AddSimPostInit()**: Hooking into simulation initialization

## 3. Lua Coding Standards for DST

### 3.1 Variable Scope Management
- **Local Variables**: Always use `local` for variables to prevent global namespace pollution
- **GLOBAL Access**: Use `GLOBAL` or import specific globals with `local X = GLOBAL.X`
- **Namespacing**: Prefix unique functions and variables to avoid conflicts

### 3.2 Class System
- **Class Definition**: Use DST's Class() system for object-oriented programming
- **Inheritance**: Extend existing classes with proper call to parent constructor
- **Component Structure**: Follow component pattern for entity behavior

### 3.3 Memory Management
- **Closure Management**: Avoid creating unnecessary closures in loops
- **Table Reuse**: Reuse tables where possible instead of creating new ones
- **Reference Cleanup**: Remove references to objects no longer needed

### 3.4 Error Handling
- **Protected Calls**: Use `pcall()` for operations that might fail
- **Error Logging**: Use `print()` or `GLOBAL.dumptable()` for debugging
- **Graceful Degradation**: Handle errors without breaking gameplay

## 4. User Interface System

### 4.1 Widget Hierarchy
- **Widget Base Class**: All UI elements derive from `Widget` class
- **Screen System**: Modal interfaces use the `Screen` class system
- **Parent-Child Relationship**: Maintain proper parent-child widget relationships

### 4.2 Widget Types and Limitations
- **Widget Methods**: Different widget types have different available methods
  - `Image`: Can use `SetTexture()`, `SetSize()`, `SetTint()`
  - `Text`: Can use `SetString()`, `SetColour()`, but not `SetTint()`
  - `TextEdit`: Can use `SetString()`, `SetEditing()`, but not `SetTint()`
  - `Button`: Has specific click handlers and states

### 4.3 UI Positioning and Sizing
- **Anchoring System**: Use `SetVAnchor()` and `SetHAnchor()` for screen positioning
- **Scale Modes**: Set appropriate `SCALEMODE_*` for screen scaling behavior
- **Positioning Units**: Game uses a center-origin coordinate system

### 4.4 Input Handling
- **Focus Management**: Properly handle widget focus gain/loss with OnGainFocus/OnLoseFocus
- **Event Propagation**: Return true from handlers to consume events
- **Input Priorities**: Honor the focus and input hierarchies

## 5. Prefab and Entity System

### 5.1 Prefab Structure
- **Entity Creation**: Use `CreateEntity()` to create new entities
- **Component Addition**: Add components with `inst:AddComponent()`
- **Network Views**: Set network variables with proper replication settings

### 5.2 Component Architecture
- **Component Definition**: Define components with standard interfaces
- **Lifecycle Hooks**: Implement OnLoad, OnSave, OnRemove when needed
- **Replicated Properties**: Mark properties for network replication when needed

### 5.3 State System
- **State Graph**: Use state graphs for complex entity behavior
- **State Events**: Handle state transitions with events
- **Animation States**: Sync states with animations

## 6. Graphics and Asset Management

### 6.1 Asset Registration
- **Register Assets**: Use `Assets = {}` table in modmain.lua
- **Asset Types**: Specify correct asset types (ANIM, ATLAS, SOUND, etc.)
- **Asset Path**: Use correct path relative to mod root

### 6.2 Texture and Atlas System
- **Atlas Format**: Create proper XML atlas files for textures
- **TEX Format**: Use .tex files for game textures
- **UV Coordinates**: Specify correct UV coordinates in atlas XML

### 6.3 Animation System
- **Spriter Format**: Use Spriter for complex animations
- **Build/Anim Files**: Create proper build/anim files
- **Symbol Swapping**: Use symbol swapping for variations

## 7. Networking and Multiplayer Considerations

### 7.1 Network Variables
- **NetVars**: Use NetVars for replicated data
- **RPC System**: Use SendRPCToServer/Client for events
- **Authority Checks**: Always check authority before state changes

### 7.2 Synchronization Patterns
- **Deterministic Behavior**: Ensure deterministic behavior for synced events
- **Event Buffering**: Buffer rapid events to reduce network load
- **Client Prediction**: Use client prediction when appropriate

### 7.3 Client vs. Server Mods
- **Client-Only Mods**: Set `client_only_mod = true` in modinfo.lua
- **Client-Server Compatibility**: Ensure client-server protocol compatibility
- **Required Mods**: Use `all_clients_require_mod` appropriately

## 8. Performance Optimization

### 8.1 Update Scheduling
- **Task Scheduling**: Use inst:DoTaskInTime() or inst:DoPeriodicTask()
- **Frame Counting**: Distribute heavy operations across frames
- **Update Frequency**: Limit update frequency to necessary rate

### 8.2 Resource Usage
- **Asset Loading**: Load assets only when needed
- **Memory Usage**: Minimize memory footprint, especially for textures
- **CPU Hotspots**: Optimize frequently called functions

### 8.3 Optimization Techniques
- **Caching**: Cache expensive calculations
- **Event Reduction**: Use events sparingly
- **Render Optimization**: Optimize rendering with proper widget hierarchy

## 9. Saves and Persistence

### 9.1 Save Data Structure
- **OnSave/OnLoad**: Implement for component data persistence
- **Data Serialization**: Only save serializable data types
- **Save Compatibility**: Handle version changes gracefully

### 9.2 Persistent Storage Types
- **World Data**: Stored in world save files
- **Player Data**: Stored in player save files
- **Mod Data**: Use TheSim:SetPersistentString() for mod-specific data

### 9.3 Save Corruption Prevention
- **Safe Saving**: Implement safe saving patterns with temp files
- **Validation**: Validate data on load
- **Error Recovery**: Implement fallbacks for corrupt saves

## 10. Community Conventions and Best Practices

### 10.1 Documentation Standards
- **Code Comments**: Document non-obvious code thoroughly
- **Function Documentation**: Document parameters and return values
- **Modinfo Description**: Provide clear, detailed mod descriptions

### 10.2 Mod Compatibility
- **Compatibility Hooks**: Provide hooks for other mods
- **Global Namespace**: Avoid polluting global namespace
- **API Versioning**: Handle API changes gracefully

### 10.3 Publishing Standards
- **Version Numbering**: Use semantic versioning
- **Change Logs**: Document changes between versions
- **Steam Workshop Tags**: Use appropriate tags for discoverability

## 11. Low-Level Implementation Details

### 11.1 Function Overriding Patterns
- **Component Function Override**: Store original, then replace with extended version
- **Safe Override**: Always call original function when appropriate
- **Method Wrapping**: Use function wrapping to extend behavior

### 11.2 Memory Access Patterns
- **Table Access**: Optimize table access patterns
- **Upvalue Management**: Manage upvalues carefully
- **Table Creation**: Minimize table creation in hot code paths

### 11.3 Performance Critical Code
- **String Concatenation**: Avoid in loops, use table.concat()
- **Table Iteration**: Use ipairs() for arrays, pairs() for sparse tables
- **Math Operations**: Cache math results when possible