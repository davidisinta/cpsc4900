# 14-Day Sprint Plan — FPS Game Engine

**Total hours: ~150 (10-12 hrs/day, no days off)**  
**Start: March 31, 2026**  
**End: April 13, 2026**

---

## Days 1-2: Raycasting + Shooting (12 hrs/day)

### Day 1

- [ ] Add raycast C API bindings to `bullet_c_api.d`
  - `b3CreateRaycastCommand`
  - `b3CreateRaycastBatchCommand`
  - `b3GetRaycastInformation`
  - `b3RayHitInfo` struct in `types.d`
  - `b3RaycastInformation` struct in `types.d`
- [ ] Add `raycast(vec3 from, vec3 to)` method to `PhysicsWorld`
  - Returns: hit entity ID, hit position, hit normal (or miss)
- [ ] Smoke test: cast ray straight down from cube, confirm it hits ground

### Day 2

- [ ] Wire mouse click to raycast from camera position along forward vector
- [ ] On hit, destroy target entity (remove from Bullet, EntityManager, SceneTree)
  - Bind `b3InitRemoveBodyCommand` in `bullet_c_api.d`
  - Add `removeBody(uint entityId)` to `PhysicsWorld`
- [ ] Spawn 10 cubes at various positions as targets
- [ ] Add crosshair (ImGui overlay or OpenGL screen-space quad)
- [ ] Add hit counter: track shots fired, shots hit
- [ ] Print accuracy to console on each shot

**Day 1-2 Deliverable:** Click to shoot, objects disappear, accuracy tracked.

---

## Days 3-4: FMOD Audio (10 hrs/day)

### Day 3

- [ ] Download FMOD Core API from fmod.com
- [ ] Copy `libfmod.dylib` to `third_party/fmod/lib/`
- [ ] Create `source/audio/fmod_c_api.d` with bindings:
  - `FMOD_System_Create`
  - `FMOD_System_Init`
  - `FMOD_System_Release`
  - `FMOD_System_Update`
  - `FMOD_System_CreateSound`
  - `FMOD_System_PlaySound`
  - `FMOD_Channel_SetVolume`
  - `FMOD_Channel_Set3DAttributes`
  - `FMOD_System_Set3DListenerAttributes`
  - `FMOD_Sound_Set3DMinMaxDistance`
  - Core enums and handle types
- [ ] Create `AudioEngine` struct in `source/audio/audioengine.d`
- [ ] Init FMOD system, load a test `.wav`, play it, confirm sound

### Day 4

- [ ] Add 3D spatial audio setup
  - Set listener position to camera position each frame in `AdvanceFrame()`
- [ ] Play gunshot sound at player position on mouse click
- [ ] Play impact sound at raycast hit point
- [ ] Distance attenuation (set min/max distance on 3D sounds)
- [ ] Add ambient loop (wind/environment)
- [ ] Add footstep sound triggered by player movement

**Day 3-4 Deliverable:** 3D gunshots, impact sounds, footsteps, ambient audio, distance attenuation.

---

## Days 5-6: Assimp + Resource Manager (12 hrs/day)

### Day 5

- [ ] Build Assimp dylib via CMake
  - Enable only OBJ, FBX, glTF importers
  - Output `libassimp_shim.dylib`
  - Confirm dylib loads on macOS
- [ ] Create `source/assimp/assimp_c_api.d` with bindings:
  - `aiImportFile`
  - `aiReleaseImport`
  - `aiGetErrorString`
  - Structs: `aiScene`, `aiMesh`, `aiNode`, `aiFace`, `aiVector3D`, `aiMaterial`
- [ ] Write `AssimpLoader.loadMesh(string path)` → extracts verts/normals/UVs → your `ISurface` VBO format
- [ ] Test: load a `.obj` with Assimp, compare output against current `SurfaceOBJ`

### Day 6

- [ ] Handle multi-mesh scenes (walk full `aiNode` tree)
- [ ] Test with a `.fbx` file (download free FPS weapon/environment from sketchfab or kenney.nl)
- [ ] Material extraction: read diffuse color + texture path from `aiMaterial` → map to `IMaterial`
- [ ] Resource manager: `AssetCache` struct
  - `MeshNode[string]` cache for meshes
  - `GLuint[string]` cache for textures
  - On load, check cache first to avoid duplicate loads
- [ ] Wire mipmapping into texture loading (`glGenerateMipmap` after `glTexImage2D`)
- [ ] Replace `SurfaceOBJ` usage in `SetupScene()` with Assimp loader

**Day 5-6 Deliverable:** Load FBX/glTF models, textures with mipmaps, no duplicate loads.

---

## Days 7-8: Player Controller + Game State (12 hrs/day)

### Day 7

- [ ] Create `source/gameplay/player.d`
- [ ] Create player capsule URDF (mass ~80kg, height ~1.8m)
- [ ] Bind in `bullet_c_api.d`:
  - `b3ApplyExternalForce`
  - `b3ChangeDynamicsInfo` (to lock angular rotation)
- [ ] Add to `PhysicsWorld`:
  - `applyForce(uint entityId, vec3 force)`
  - `applyImpulse(uint entityId, vec3 impulse)`
  - `setAngularFactor(uint entityId, vec3 factor)` (lock rotation with 0,0,0)
- [ ] WASD movement: compute direction from camera forward/right projected onto XZ plane, apply as force
- [ ] Lock camera to player capsule: after sync, set `mCamera.mEyePosition` = capsule pos + (0, 1.6, 0) eye offset
- [ ] Tune speed, friction, damping

### Day 8

- [ ] Jump: spacebar, raycast down for ground check, apply upward impulse if grounded
- [ ] Game state machine: `enum GameState { MENU, PLAYING, PAUSED, RESULTS }`
  - MENU: show ImGui menu, no physics
  - PLAYING: full game loop
  - PAUSED: freeze physics, show pause menu
  - RESULTS: show score, play again button
- [ ] Weapon system struct:
  - `fireRate`, `magazineSize`, `reloadTime`, `currentAmmo`
  - Two weapons: pistol (slow, accurate) + rifle (fast, less accurate)
  - Number keys 1/2 to switch
  - R to reload (with delay timer)
  - Cooldown between shots

**Day 7-8 Deliverable:** Walk, jump, shoot, switch weapons, reload, game states work.

---

## Days 9-10: HUD + Menu + Scoring (10 hrs/day)

### Day 9

- [ ] ImGui HUD overlay (rendered on top of 3D scene):
  - Crosshair at screen center
  - Health bar (bottom left)
  - Ammo display: `currentAmmo / magazineSize` (bottom right)
  - Score counter (top right)
  - Accuracy percentage (top right, below score)
- [ ] Main menu screen (ImGui):
  - "Play" button → transition to PLAYING state
  - "Settings" button → open settings panel
  - "Quit" button → exit
- [ ] Settings panel:
  - Mouse sensitivity slider
  - Weapon selection (pistol/rifle default)
  - Store in `Settings` struct, apply on change

### Day 10

- [ ] Spawn system: objects fall from sky
  - Timer-based spawning (every 2 seconds)
  - Random X/Z positions within arena bounds
  - Different shapes/sizes (cube URDF, sphere URDF — create sphere.urdf)
  - Objects have health (1 hit to destroy)
- [ ] Scoring:
  - +10 per hit
  - Accuracy = hits / total shots (displayed as percentage)
- [ ] Round system:
  - 60-second round timer (displayed on HUD)
  - Objects spawn continuously during round
  - Round ends → transition to RESULTS state
  - RESULTS screen: final score, accuracy, "Play Again" button
- [ ] Player health:
  - Objects that land on ground without being shot reduce player health
  - Player dies → show "Game Over", transition to RESULTS
  - "Play Again" resets everything

**Day 9-10 Deliverable:** Full gameplay loop with menus, HUD, scoring, rounds.

---

## Days 11-12: Frustum Culling + Octree (12 hrs/day)

### Day 11

- [ ] Extract 6 frustum planes from view-projection matrix (`mat4`)
  - Write `extractFrustumPlanes(mat4 viewProj)` → returns 6 plane equations
- [ ] Add bounding sphere to each entity
  - Compute from mesh AABB on load (center + radius)
  - Store in EntityManager: `BoundingSphere[uint] bounds`
- [ ] Sphere-vs-frustum test: `bool isInsideFrustum(BoundingSphere s, Plane[6] planes)`
- [ ] Integrate into render loop: skip `MeshNode.Update()` (draw call) if entity is outside frustum
- [ ] Verify: rotate camera, confirm objects behind you stop being drawn

### Day 12

- [ ] Octree implementation:
  - `OctreeNode` struct with 8 children, AABB bounds, list of entity IDs
  - `insert(uint entityId, AABB bounds)`
  - `query(Plane[6] frustum)` → returns list of potentially visible entity IDs
- [ ] Insert all entities into octree on spawn
- [ ] Replace brute-force frustum check with octree query (reject entire branches)
- [ ] Runtime toggles (keyboard):
  - F1 = frustum culling on/off
  - F2 = mipmaps on/off
  - F3 = octree on/off
  - Log current state to console on toggle
- [ ] Debug visualizations (toggle with F4):
  - Render bounding boxes around entities (wireframe)
  - Render octree nodes as wireframe cubes
  - Render frustum planes as wireframe

**Day 11-12 Deliverable:** Frustum culling with octree, mipmaps, all toggleable for measurement.

---

## Days 13-14: Performance Evaluation + Polish (10 hrs/day)

### Day 13

- [ ] Build stress scenes:
  - Scene A: 100 objects
  - Scene B: 500 objects
  - Scene C: 1000 objects
- [ ] Measurement runs (record FPS for each):
  - All optimizations OFF
  - Frustum culling only
  - Mipmaps only
  - Octree only
  - All optimizations ON
- [ ] Record results in a table (CSV or markdown)
- [ ] Frame-time graph: ImGui plot or log to CSV for external graphing
- [ ] Capture screenshots of debug visualizations for report

### Day 14

- [ ] Full flow test: launch → menu → settings → play → shoot → round end → results → play again
- [ ] Fix crashes, edge cases:
  - Window resize
  - Alt-tab
  - Destroying all objects
  - Empty scene
  - Rapid fire
- [ ] Clean shutdown: all dylibs, Bullet, FMOD, OpenGL, SDL properly released
- [ ] Package:
  - Clean `README.md` with build instructions
  - Record short demo video of gameplay (screen capture)
  - Organize measurement data for report
  - Ensure `dub build` works cleanly from a fresh clone

**Day 13-14 Deliverable:** Stress-tested, measured, demo-ready build.

---

## Scope Cuts (things NOT included to fit 14 days)

- ~~Occlusion culling~~ — frustum + octree is sufficient for evaluation
- ~~Skeletal animation~~ — static meshes only
- ~~Shadow mapping~~ — big visual win but 2+ days of shader work
- ~~Enemy AI / pathfinding~~ — enemies are falling objects, not walking NPCs
- ~~FBO scene viewport in editor~~ — ImGui overlays only
- ~~Full options screen~~ — minimal settings (sensitivity + weapon)

---

## Proposal Deliverables Checklist

### A) Engine Features
- [ ] Rendering subsystem with Modern OpenGL
- [ ] Scene + entity system (SceneTree + EntityManager)
- [ ] Resource manager (AssetCache with model/texture caching)
- [ ] Model loading via Assimp
- [ ] Physics subsystem (Bullet C API)
- [ ] Audio system (FMOD)
- [ ] Frustum culling
- [ ] Mipmapping
- [ ] Octree spatial acceleration
- [ ] Raycast API for gameplay

### B) FPS Demo
- [ ] Player movement + FPS camera
- [ ] Shooting system (hitscan raycasts)
- [ ] Objects to shoot (spawning targets)
- [ ] Scoring + accuracy metric
- [ ] Weapon switching + weapon stats
- [ ] Menu GUI (main menu + settings)
- [ ] HUD (crosshair, ammo, score, accuracy)
- [ ] Game state machine (MENU / PLAYING / PAUSED / RESULTS)

### C) Evaluation
- [ ] Performance measurements (FPS across stress scenes)
- [ ] A/B toggles for each optimization
- [ ] Before/after comparison data
- [ ] Debug visualizations
- [ ] Demo video
- [ ] Final report data ready