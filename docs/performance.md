# **Performance Optimization**

## CPU and Memory Optimization
- **Avoid per-frame computations** where possible.
- Use **event-driven updates** instead of polling.
- Utilize **Lua's garbage collection** wisely by removing unused references.

## Task Scheduling
- Use `DoPeriodicTask(interval, fn)` for recurring tasks.
- Example:
  ```lua
  inst:DoPeriodicTask(5, function() print("Running every 5 seconds!") end)
  ```

## Profiling Performance
- Use DST's built-in **profiler** to analyze mod performance.
- Press `ALT+/` to record profiling data.
- Load profiling results in `chrome://tracing` for detailed insights.

## Reducing Network Overhead
- Use **NetVars efficiently** (e.g., `net_smallbyte` instead of `net_int` for small values).
- Aggregate network updates instead of sending multiple small updates.

## Memory Management Best Practices
- Clean up event listeners to prevent memory leaks:
  ```lua
  inst:RemoveEventCallback("event", callback_fn)
  ```
- Avoid excessive object creation inside loops.
- Use table pooling if needed.

By following these optimization strategies, mods can **improve performance and reduce lag**, ensuring a smooth experience for players.
