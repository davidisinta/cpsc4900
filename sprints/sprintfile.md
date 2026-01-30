# 7-Week Timeline (Sprints) — Code Deliverables Focus

> Goal by end of Week 7: a playable FPS demo built on your engine, with measurable performance toggles (frustum culling, mipmaps, octree, audio distance culling) and a repeatable benchmark scene.

---

## Sprint 1 (Week 1) — Engine Bootstrap + “Proof of Life”
**Objective:** establish a stable runtime loop and modern OpenGL rendering baseline.

**Deliverables (checklist):**
- [X] Project builds on your target machine (clean build, single command)
- [X] Window + OpenGL 3.3+ context creation (SDL/GLFW)
- [X] Main loop with fixed/variable timestep support (basic timing subsystem)
- [X] FPS camera + mouse/keyboard input
- [X] Basic shader pipeline (compile/link, hot-reload optional)
- [X] Render a simple scene (triangle/cube) + depth testing enabled

**Definition of done:** you can move a camera in a 3D scene at stable FPS, with a minimal renderer.

---

## Sprint 2 (Week 2) — Core Engine Architecture + Library Integration (Minimal)
**Objective:** set up the engine “spine” and integrate core external libraries at the thinnest working level.

**Deliverables (checklist):**
- [ ] Scene + entity model (IDs/handles, transform component)
- [ ] Transform system (local/world matrices, parent-child optional)
- [ ] Basic engine modules layout (Render / Physics / Audio / Assets)
- [ ] Assimp loads a model file successfully (even if not fully rendered yet)
- [ ] Bullet world initializes + steps (gravity demo)
- [ ] FMOD initializes + plays a test sound

**Definition of done:** engine initializes and shuts down cleanly with all core libraries working.

---

## Sprint 3 (Week 3) — Rendering Subsystem + Resource Manager v1
**Objective:** make rendering real (meshes/materials) and prevent duplicate asset loads.

**Deliverables (checklist):**
- [ ] Mesh abstraction (VBO/EBO/VAO) + draw API
- [ ] Material abstraction (shader + textures + uniforms)
- [ ] Basic lighting pass (directional or point light)
- [ ] Texture loader + sampler state configuration
- [ ] Resource Manager v1:
  - [ ] Cache for models/textures/sounds (keyed by path/ID)
  - [ ] Reference-count or shared-handle ownership model
  - [ ] Avoid duplicate loads across entities
- [ ] Render an imported model via Assimp (one static mesh is enough)

**Definition of done:** you can place multiple entities referencing the same assets without reloading.

---

## Sprint 4 (Week 4) — Physics + Raycast API + FPS Gameplay Core
**Objective:** make the game loop playable with “hitscan” shooting built on raycasts.

**Deliverables (checklist):**
- [ ] Collision shapes for world + targets (AABB/box/sphere ok)
- [ ] Physics update integrated with engine tick
- [ ] Raycast API (origin, direction, max distance, hit result)
- [ ] Player controller (movement + grounded checks optional)
- [ ] Shooting system (hitscan raycast → hit feedback)
- [ ] Score + accuracy metric (hits vs misses)
- [ ] Spawn system for targets (basic shapes) + reset/restart

**Definition of done:** you can walk around and shoot targets; score/accuracy updates.

---

## Sprint 5 (Week 5) — Performance Features v1 (Mips + Frustum Culling + Octree)
**Objective:** implement the key engine-side performance techniques.

**Deliverables (checklist):**
- [ ] Mipmapping integrated into texture pipeline
  - [ ] Generate mip chain on load
  - [ ] Correct min/mag filters + anisotropy optional
- [ ] Frustum culling v1:
  - [ ] Extract frustum planes from camera matrices
  - [ ] Bounding volume tests (sphere/AABB) per renderable
  - [ ] Culling reduces submitted draw calls
- [ ] Octree v1 (static partition):
  - [ ] Insert static scene geometry / renderables
  - [ ] Query by frustum (candidate set)
  - [ ] Optional: query for raycasts (candidate pruning)
- [ ] Debug overlays:
  - [ ] Draw bounding volumes
  - [ ] Visualize frustum
  - [ ] Optional: visualize octree nodes

**Definition of done:** toggling culling on/off changes draw-call count and performance in dense scenes.

---

## Sprint 6 (Week 6) — UI/HUD + Weapons + Game States + Audio Distance Culling
**Objective:** add the “game wrapper” (menu/HUD/settings), weapon selection, and audio optimization.

**Deliverables (checklist):**
- [ ] Game state machine: MENU / PLAYING / PAUSED / RESULTS
- [ ] Menu GUI:
  - [ ] Start game / restart / quit
  - [ ] Settings: mouse sensitivity, weapon selection
- [ ] HUD:
  - [ ] Crosshair
  - [ ] Score + accuracy
  - [ ] Current weapon + ammo (ammo optional)
- [ ] Weapon system:
  - [ ] Data-driven weapon stats (fire rate, spread, range, damage)
  - [ ] Weapon switching
- [ ] Audio distance culling:
  - [ ] Only play/stream sounds within radius of player
  - [ ] Volume attenuation by distance (simple curve ok)

**Definition of done:** polished gameplay loop with menus + HUD; audio does not play when irrelevant/far.

---

## Sprint 7 (Week 7) — Benchmarking Harness + Performance Pass + Demo Packaging
**Objective:** produce measurable results and a stable demo build.

**Deliverables (checklist):**
- [ ] “Stress scene” generator:
  - [ ] Spawn N targets / props with shared assets
  - [ ] Parameterize N and distribution
- [ ] Performance instrumentation:
  - [ ] FPS + frame time (avg + p95/p99) logging
  - [ ] Draw-call count + visible count
  - [ ] Optional: CPU timings per subsystem (render/physics/audio)
- [ ] Runtime toggles (must-have for A/B):
  - [ ] Frustum culling on/off
  - [ ] Octree on/off
  - [ ] Mipmaps on/off
  - [ ] Audio distance culling on/off
- [ ] Stability pass:
  - [ ] Fix crashes/leaks, remove per-frame allocations where possible
  - [ ] Validate deterministic gameplay loop + restart
- [ ] Demo packaging:
  - [ ] README build/run instructions + controls
  - [ ] “Demo script” (what to show in 2–3 minutes)

**Definition of done:** one command launches the demo; you can reproduce performance comparisons reliably.

---

## Notes (Scope Discipline)
- Keep occlusion culling as a **stretch goal** unless everything above is stable.
- Prioritize “toggleable features + measurement harness” — that’s what makes performance claims credible.
