
# Graphics Engine State and FPS Roadmap

## 1. Current State of the Graphics Application

You currently have a functioning **graphics framework and engine skeleton** implemented in D using SDL and modern OpenGL.

### What is already working

#### Platform and context
- SDL successfully creates a window and OpenGL core context.
- Double buffering and depth buffering are enabled.
- OpenGL functions are dynamically loaded and version-checked.

#### Engine loop
The application follows the canonical real-time rendering loop:

```
Input → Update → Render
```

This loop runs continuously while `mGameIsRunning` is true.

Frame pacing is currently handled via:

```
SDL_Delay(16)
```

which approximates 60 FPS but does not provide deterministic simulation timing.

#### Scene architecture
You already have a strong structural separation:

- SceneTree (scene graph)
- MeshNode (renderable entities)
- Renderer (draw traversal)
- Camera (view + projection matrices)
- Materials and Pipelines (shader abstraction)

This is effectively the backbone of a small custom engine.

#### Objects in the scene

You render two main objects:

1. Rotating triangle
   - Uses vertex colors
   - Demonstrates per-object model transforms
   - Confirms shader uniform binding is correct

2. Procedural terrain
   - Generated from a heightmap / noise texture
   - Uses multi-texture blending
   - Demonstrates texture sampling and large geometry rendering

This is a significant milestone — you are already beyond “triangle stage” and into world-scale rendering.

#### Camera and input
- Keyboard input moves the camera position.
- Mouse input feeds into camera look.
- Wireframe toggle works correctly.
- Camera matrices are bound live to shader uniforms.

At this stage, you have:

✔ working camera  
✔ working transforms  
✔ working terrain  
✔ working materials  
✔ working render traversal  

This is a legitimate engine prototype.

---

## 2. What Is Missing for a 3D First-Person Shooter

An FPS is not just rendering — it is a stack of interacting systems.

Below is the complete breakdown.

### Core runtime systems

- Delta time (dt)
- Fixed timestep support (especially for physics)
- Proper frame timing (remove SDL_Delay dependency)
- Input state tracking (pressed / held / released)
- Relative mouse movement

Without these, movement and simulation will always feel incorrect.

### Camera system

You need a true FPS camera:

- Yaw and pitch angles
- Pitch clamping (no flipping)
- Direction vectors derived from angles
- Movement in camera space
- Configurable sensitivity and FOV

### Gameplay architecture

Rendering and gameplay must be separated.

Recommended minimal structure:

- Entity
- Transform
- Renderable
- Collider
- PlayerController
- Weapon

SceneTree should become rendering-only.

Gameplay logic should live in a separate world update system.

### World and level system

- Level loading from data files
- Spawn points
- Static props
- Environment configuration
- Debug visualizers

Hardcoding objects in `SetupScene()` must eventually be eliminated.

### Physics and interaction

Minimum viable FPS physics:

- Capsule-based character controller
- Ground detection
- Sliding on slopes
- Jumping
- Gravity

Collision systems:

- Broadphase (grid or BVH)
- Narrowphase (AABB, capsule, ray tests)

### Weapons and combat

Start simple:

- Hitscan weapons (raycast)
- Fire rate
- Reload timing
- Recoil
- Spread

Projectiles can come later.

### Rendering extensions

- Mesh loading (OBJ or glTF)
- Lighting (directional + point lights)
- Normal mapping
- Shadow mapping (optional early)
- Post-processing (gamma correction, tone mapping)

### HUD and UI

- Crosshair
- Ammo counter
- Health bar
- Debug overlays

### Audio

- Gunfire
- Footsteps
- Environmental cues
- Spatial audio

### AI (later stage)

- Simple enemy logic
- Patrol → chase → attack
- Navmesh or grid-based navigation

---

## 3. What You Need to Learn (Ordered)

### Phase 1 — Engine correctness

- Delta time computation
- Input state systems
- Relative mouse handling
- Deterministic update loops

This phase fixes fundamental feel issues.

### Phase 2 — FPS camera mathematics

- Yaw/pitch integration
- Direction vectors
- View matrix construction
- Camera-local movement

This is the heart of first-person control.

### Phase 3 — Gameplay vs rendering separation

- Entity-component thinking
- Data flow from gameplay → renderer
- Clean system boundaries

### Phase 4 — Collision and raycasting

- Ray–triangle intersection
- AABB tests
- Heightmap sampling
- Simple physics integration

### Phase 5 — Asset pipeline

- Model loading
- Texture formats
- Material definitions
- Resource lifetime management

### Phase 6 — Performance engineering

- CPU frame profiling
- GPU timing queries
- Culling strategies
- Cache-aware data layouts
- Draw-call minimization

This is where “high FPS” becomes a research problem rather than a feature.

---

## 4. Recommended Next Milestone

### Milestone: Walkable FPS Prototype

Deliverables:

1. Proper delta-time-based movement
2. Relative mouse FPS camera
3. WASD movement with sprint
4. Terrain collision via height sampling
5. Hitscan ray weapon
6. Debug overlay showing:
   - FPS
   - Frame time
   - Draw calls

This milestone validates:

- Input
- Camera
- Time
- Math
- Collision
- Engine structure

Once this works, you officially have the foundation of a real FPS engine.

---

## Final Perspective

You are no longer “learning OpenGL.”  
You are now doing **engine development**.

From here onward, progress is not about more APIs — it is about:

- architecture
- data flow
- performance tradeoffs
- systems design

This is exactly the correct stage to be in for building a serious first-person shooter from scratch.
