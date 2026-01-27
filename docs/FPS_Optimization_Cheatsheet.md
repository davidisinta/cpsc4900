# FPS Game Engine Optimization Cheatsheet

This document lists potential optimizations for a custom FPS engine, organized by system.

---

## 1. Rendering / GPU Optimizations

- **Frustum Culling**: Only render objects inside the camera view. Use frustum planes or octree/BVH traversal.
- **Level of Detail (LOD)**: Reduce polygon count and texture resolution for distant objects.
- **Instancing**: Draw multiple identical objects in a single GPU call to reduce draw calls.
- **Deferred Rendering**: Optimize lighting for scenes with many lights.
- **Occlusion Culling**: Skip objects blocked by walls or other geometry using CPU or GPU queries.

---

## 2. Physics / Collision Optimizations

- **Broadphase Tuning**: Adjust Bullet DBVT or SAP settings for world size and object density.
- **Collision Layers**: Only allow collisions between relevant objects (e.g., bullets vs world, player vs world).
- **Sleeping / Deactivation**: Let Bullet put static or inactive objects to sleep to reduce calculations.

---

## 3. Gameplay-Specific Optimizations

- **Hitscan Weapons**: Use raycasts for instant-hit weapons instead of simulating physics bullets.
- **Rate-Limit Effects**: Only spawn particles or sounds if visible/audible.
- **Bullet/Object Pooling**: Reuse bullets, shells, and impact effects to avoid allocations every frame.
- **AI Update Throttling**: Update distant AI less frequently; use spatial partitioning to find targets.

---

## 4. Memory / Asset Optimizations

- **Texture / Mesh Streaming**: Load high-resolution assets only for visible areas; stream in chunks for large levels.
- **Object Pooling**: Reuse frequently spawned objects to reduce memory allocation spikes.
- **Contiguous Data Structures**: Store positions, velocities, and other ECS-like data in contiguous arrays for cache efficiency.

---

## 5. Engine-Level Optimizations

- **Multi-threading**: Separate threads for physics, AI, audio, and asset loading/streaming.
- **Command Buffers**: Batch render/audio commands to reduce API call overhead.
- **Profiling & Hotspot Analysis**: Profile CPU, GPU, and memory usage to identify bottlenecks.

---

## 6. FPS-Specific Tricks

| Technique | Benefit |
|-----------|---------|
| Simplified weapon collision | Use hitscan to reduce rigidbody checks |
| Bullet trails as GPU lines | Avoid simulating fast bullets physically |
| Static geometry baking | Precompute lighting/shadows for static environment |
| Particle LOD | Reduce particle density at distance |
| Audio culling | Only play sounds near the player |
| Footstep volume scaling | Skip inaudible footsteps to save CPU/audio mixing |

---

## Recommended MVP Optimizations

1. Raycast bullets instead of physics bullets.
2. Object pooling for bullets and impact effects.
3. Distance-based sound/particle spawning (like 5m audio radius).
4. Frustum culling (optionally with BVH/octree).
5. Proper collision layers in Bullet.
6. Frequent profiling to identify real hotspots.
