# Sting3D Engine — Optimization & Evaluation Plan

---

## Overview

This document covers all optimizations to implement, how to implement each one, the runtime toggle system for A/B testing, the evaluation methodology, and the data collection procedure.

---

## Part 1: Optimizations Already Implemented

These are features you already have in your engine. Claim them in your poster and evaluation.

### 1.1 Fixed Timestep Physics
**What it does:** Decouples physics simulation rate from render frame rate using an accumulator pattern. Physics always steps at 1/60s regardless of FPS fluctuations.
**Where:** `physicsworld.d` → `updatePhysics(frameDt)` with accumulator, max 8 substeps.
**Impact:** Prevents physics instability at low FPS, ensures deterministic simulation.
**Toggle:** Not toggleable — always on (disabling would break physics).

### 1.2 Hitscan Raycasting
**What it does:** Weapons use instant raycasts instead of simulating projectile entities. Avoids spawning, updating, and collision-testing bullet objects each frame.
**Where:** `gameapplication.d` → `shoot()` calls `mPhysicsWorld.raycast()`.
**Impact:** Zero per-frame cost for weapon logic beyond the raycast query itself.
**Toggle:** Not toggleable — core gameplay mechanic.

### 1.3 Sound Caching
**What it does:** Audio assets are loaded once via FMOD and cached by file path. Repeated playback reuses cached sound handles.
**Where:** `audioengine.d` → `loadSound()` checks `mSoundCache` before loading.
**Impact:** Eliminates redundant disk I/O and memory allocation for frequently played sounds.
**Toggle:** Not toggleable — always on.

### 1.4 One-Directional Transform Sync
**What it does:** Only physics-driven entities have their transforms updated each frame. Static scene objects (map pieces, terrain) are set once and never re-synced.
**Where:** `transformsync.d` → `syncPhysicsToRender()` iterates only `entityToBody` entries.
**Impact:** Reduces per-frame work proportional to number of dynamic vs static objects.
**Toggle:** Not toggleable — architectural design.

### 1.5 Mipmapping
**What it does:** Textures are loaded with automatically generated mipmap chains. The GPU selects lower-resolution mip levels for distant surfaces.
**Where:** `littexturedmaterial.d` → `glGenerateMipmap(GL_TEXTURE_2D)` and `GL_LINEAR_MIPMAP_LINEAR` filter.
**Impact:** Reduces texture memory bandwidth, eliminates aliasing on distant surfaces.
**Toggle:** F2 key (switch between `GL_LINEAR_MIPMAP_LINEAR` and `GL_NEAREST`).

### 1.6 Frame Cap
**What it does:** SDL_Delay pads remaining time when frame completes in under 16ms, preventing busy-waiting and reducing CPU usage.
**Where:** `graphicsengine.d` → `AdvanceFrame()` delay logic.
**Impact:** Reduces CPU power consumption, prevents unnecessary heat/throttling.
**Toggle:** Not toggleable.

---

## Part 2: Optimizations To Implement

### 2.1 Backface Culling
**Time to implement:** 2 minutes
**What it does:** Tells the GPU to skip rendering triangles facing away from the camera. For closed meshes (like soldiers, barrels, buildings), roughly 50% of triangles face away at any time.
**Impact:** ~50% fewer triangles processed by the GPU.

**Implementation:**
Add one line in `graphicsengine.d` → `Render()`, after `glEnable(GL_DEPTH_TEST)`:

```d
glEnable(GL_CULL_FACE);
glCullFace(GL_BACK);
```

**Toggle (F3 key):**
Add a bool `mBackfaceCulling = true;` to GraphicsEngine.
In Render():
```d
if (mBackfaceCulling)
    glEnable(GL_CULL_FACE);
else
    glDisable(GL_CULL_FACE);
```
In Input(), on F3 keydown:
```d
else if (event.key.keysym.sym == SDLK_F3) {
    mBackfaceCulling = !mBackfaceCulling;
    writeln("[toggle] backface culling: ", mBackfaceCulling);
}
```

---

### 2.2 Draw Distance Cutoff
**Time to implement:** 15 minutes
**What it does:** Objects beyond a maximum distance from the camera are not rendered. Simple distance check before each draw call.
**Impact:** Eliminates rendering of far-away objects. Effect scales with scene size.

**Implementation:**
Add to `renderer.d` or the scene graph traversal — before calling `node.Update()`:

```d
// In the render traversal, for each MeshNode:
float dx = node.mModelMatrix[3] - camera.mEyePosition.x;  // translation X from model matrix
float dy = node.mModelMatrix[7] - camera.mEyePosition.y;  // translation Y
float dz = node.mModelMatrix[11] - camera.mEyePosition.z; // translation Z
float distSq = dx*dx + dy*dy + dz*dz;

if (distSq > mDrawDistance * mDrawDistance)
    continue; // skip this node
```

Note: The model matrix stores translation in elements [3], [7], [11] (or [12], [13], [14] depending on row/column major). Check which layout your engine uses. You can also extract position from the TransformComponent if available.

**Simpler approach — in GameApplication.Update():**
Before the scene tree renders, mark nodes as visible/invisible:
```d
float maxDist = 200.0f; // adjustable
foreach (node; allMeshNodes) {
    // extract position from model matrix column 3
    vec3 objPos = vec3(node.mModelMatrix[3], node.mModelMatrix[7], node.mModelMatrix[11]);
    float dist = distance(mCamera.mEyePosition, objPos);
    node.mVisible = (dist <= maxDist);
}
```

Then in the renderer, check `node.mVisible` before drawing.

**Toggle (F4 key):**
```d
bool mDrawDistanceEnabled = true;
float mDrawDistance = 200.0f;
```
On F4: toggle on/off. On F5/F6: increase/decrease distance.

---

### 2.3 Frustum Culling
**Time to implement:** 2-3 hours
**What it does:** Tests each object's bounding volume against the camera's view frustum (6 planes). Objects entirely outside the frustum are skipped before rendering. This is the most impactful optimization for typical gameplay — the player usually sees only 30-60% of the scene.
**Impact:** 40-70% fewer draw calls depending on camera orientation.

**Implementation — Step by Step:**

**Step A: Add bounding sphere to entities**
Each entity needs a bounding sphere (center point + radius). For simplicity, compute the radius once at spawn time from the mesh's bounding box diagonal:

```d
// In SurfaceAssimp or Model, after loading:
float radius = 0;
for each vertex:
    float dist = length(vertex - center);
    if (dist > radius) radius = dist;
```

Store `mBoundingRadius` on the MeshNode or entity.

**Step B: Extract frustum planes from VP matrix**
Each frame, after the camera updates:

```d
struct FrustumPlane {
    float a, b, c, d;
}

FrustumPlane[6] extractFrustum(mat4 vp)
{
    FrustumPlane[6] planes;
    
    // Left: row3 + row0
    planes[0].a = vp[12] + vp[0];
    planes[0].b = vp[13] + vp[1];
    planes[0].c = vp[14] + vp[2];
    planes[0].d = vp[15] + vp[3];
    
    // Right: row3 - row0
    planes[1].a = vp[12] - vp[0];
    planes[1].b = vp[13] - vp[1];
    planes[1].c = vp[14] - vp[2];
    planes[1].d = vp[15] - vp[3];
    
    // Bottom: row3 + row1
    planes[2].a = vp[12] + vp[4];
    planes[2].b = vp[13] + vp[5];
    planes[2].c = vp[14] + vp[6];
    planes[2].d = vp[15] + vp[7];
    
    // Top: row3 - row1
    planes[3].a = vp[12] - vp[4];
    planes[3].b = vp[13] - vp[5];
    planes[3].c = vp[14] - vp[6];
    planes[3].d = vp[15] - vp[7];
    
    // Near: row3 + row2
    planes[4].a = vp[12] + vp[8];
    planes[4].b = vp[13] + vp[9];
    planes[4].c = vp[14] + vp[10];
    planes[4].d = vp[15] + vp[11];
    
    // Far: row3 - row2
    planes[5].a = vp[12] - vp[8];
    planes[5].b = vp[13] - vp[9];
    planes[5].c = vp[14] - vp[10];
    planes[5].d = vp[15] - vp[11];
    
    // Normalize each plane
    foreach (ref p; planes) {
        float len = sqrt(p.a*p.a + p.b*p.b + p.c*p.c);
        p.a /= len; p.b /= len; p.c /= len; p.d /= len;
    }
    
    return planes;
}
```

NOTE: The exact indexing (vp[0], vp[12], etc.) depends on whether your mat4 is row-major or column-major. You will need to verify this matches your engine's mat4 layout. If the culling seems inverted or wrong, swap row and column indices.

**Step C: Test sphere against frustum**

```d
bool isInsideFrustum(FrustumPlane[6] planes, vec3 center, float radius)
{
    foreach (ref p; planes) {
        float dist = p.a * center.x + p.b * center.y + p.c * center.z + p.d;
        if (dist < -radius)
            return false; // entirely outside this plane
    }
    return true; // inside or intersecting all planes
}
```

**Step D: Integrate into render loop**
Before drawing each node, check frustum visibility:

```d
// Each frame:
mat4 vp = camera.mProjectionMatrix * camera.mViewMatrix;
auto frustum = extractFrustum(vp);

// For each MeshNode:
vec3 objPos = ...; // extract from model matrix
float objRadius = ...; // bounding radius

if (mFrustumCullingEnabled && !isInsideFrustum(frustum, objPos, objRadius))
{
    mObjectsCulled++;
    continue; // skip rendering
}
mObjectsDrawn++;
node.Update(); // render
```

**Toggle (F1 key):**
```d
bool mFrustumCullingEnabled = true;
int mObjectsDrawn = 0;
int mObjectsCulled = 0;
```
Display in HUD: "DRAWN: 142/500 | CULLED: 358"

---

### 2.4 Static Body Separation
**Time to implement:** 15 minutes
**What it does:** Map pieces and terrain are marked as static (mass=0). Bullet skips simulation for static bodies — no velocity integration, no collision response computation. Only dynamic bodies (soldiers, bunnies) are simulated.
**Impact:** Reduces physics step time proportional to number of static objects.

**Implementation:**
Your map pieces are already not in the physics world — they're render-only scene nodes added directly to the scene tree without URDF bodies. So this optimization is already partially in place.

To fully claim it: ensure the ground plane URDF has mass=0 (it does — plane.urdf is static). Soldiers and bunnies have mass > 0 (they do — cube.urdf and soldier.urdf are dynamic).

For measurement: count physics bodies vs total scene objects and report the ratio.
"Of 550 scene objects, only 12 are dynamic physics bodies. The remaining 538 static objects incur zero per-frame physics cost."

**Toggle:** Not toggleable — architectural. But you can measure physics step time with and without dynamic bodies to show the cost.

---

## Part 3: Runtime Toggle System

### Key Bindings

| Key | Optimization | Default |
|-----|-------------|---------|
| F1 | Frustum culling | ON |
| F2 | Mipmapping | ON |
| F3 | Backface culling | ON |
| F4 | Draw distance cutoff | ON |
| Tab | Wireframe mode | OFF |

### HUD Display

Add to GameGUI a debug panel showing:
```
OPTIMIZATIONS
Frustum Culling: ON    [F1]
Mipmapping: ON         [F2]
Backface Culling: ON   [F3]
Draw Distance: ON      [F4]

STATS
Objects: 142/500 drawn
Triangles: ~850K
Physics Bodies: 12
FPS: 58
Frame Time: 17.2ms
```

### Implementation in graphicsengine.d

Add member variables:
```d
bool mFrustumCulling = true;
bool mMipmapping = true;
bool mBackfaceCulling = true;
bool mDrawDistanceCutoff = true;
```

In Input(), add key handlers:
```d
else if (event.key.keysym.sym == SDLK_F1) {
    mFrustumCulling = !mFrustumCulling;
    writeln("[toggle] frustum culling: ", mFrustumCulling);
}
else if (event.key.keysym.sym == SDLK_F2) {
    mMipmapping = !mMipmapping;
    writeln("[toggle] mipmapping: ", mMipmapping);
    // Update texture filtering for all textures
}
else if (event.key.keysym.sym == SDLK_F3) {
    mBackfaceCulling = !mBackfaceCulling;
    writeln("[toggle] backface culling: ", mBackfaceCulling);
}
else if (event.key.keysym.sym == SDLK_F4) {
    mDrawDistanceCutoff = !mDrawDistanceCutoff;
    writeln("[toggle] draw distance: ", mDrawDistanceCutoff);
}
```

Pass toggle states to the game/renderer each frame so they can use them.

---

## Part 4: Evaluation Methodology

### Test Setup

**Hardware:** Apple M2, macOS, OpenGL 4.1 Metal backend
**Scene:** Stress test with N identical objects (bunny OBJ, 14904 vertices each) spawned in a grid with cube.urdf physics bodies, plus static map pieces and terrain.
**Measurement:** Average FPS over 60-second run, recorded from engine FPS counter. Per-frame times logged to CSV for variance analysis.
**Camera:** Fixed position and orientation for all tests (looking at the center of the object grid).

### Stress Test Spawner

```d
void spawnStressTest(int count)
{
    int cols = cast(int)sqrt(cast(float)count);
    for (int i = 0; i < count; i++)
    {
        float x = (i % cols) * 3.0f;
        float z = (i / cols) * -3.0f;
        spawnPhysicsObject("cube.urdf",
            "./assets/meshes/bunny_centered.obj",
            vec3(x, 5.0f, z));
    }
    writeln("[stress] spawned ", count, " objects");
}
```

Call with different counts: 50, 100, 200, 500, 1000.

### Phase 1: Cumulative Test (add optimizations one at a time)

Start with everything OFF, add one optimization at a time, measure FPS.

| Config | Active Optimizations | 50 FPS | 100 FPS | 200 FPS | 500 FPS | 1000 FPS |
|--------|---------------------|--------|---------|---------|---------|----------|
| A | Baseline (all OFF) | | | | | |
| B | + Backface culling | | | | | |
| C | + Mipmapping | | | | | |
| D | + Draw distance cutoff | | | | | |
| E | + Frustum culling | | | | | |
| F | All ON | | | | | |

This shows: "Each optimization added X FPS. Together they achieve Y FPS."

### Phase 2: Isolation Test (all ON, disable one at a time)

Start with everything ON, disable one optimization at a time, measure FPS drop.
Use 1000 objects for maximum differentiation.

| Config | What's DISABLED | 1000 obj FPS | Drop from F | % Impact |
|--------|----------------|-------------|-------------|----------|
| F | Nothing (all ON) | | — | — |
| F-1 | Frustum culling OFF | | | |
| F-2 | Backface culling OFF | | | |
| F-3 | Mipmapping OFF | | | |
| F-4 | Draw distance OFF | | | |

This shows: "Disabling frustum culling caused the largest FPS drop (X%), confirming it as the most impactful optimization."

### Phase 3: Scaling Test

All optimizations ON. Measure how FPS scales with object count.

| Objects | Avg FPS | Min FPS | Avg Frame Time | Objects Drawn | Objects Culled |
|---------|---------|---------|----------------|---------------|----------------|
| 50 | | | | | |
| 100 | | | | | |
| 200 | | | | | |
| 500 | | | | | |
| 1000 | | | | | |

### Frame Time Logger

Add to AdvanceFrame() for detailed analysis:

```d
// At the top of graphicsengine.d, add:
import std.stdio : File;

// Add member:
File mFrameLog;
bool mLogging = false;
int mFrameNum = 0;

// To start logging (call once):
void startFrameLog(string filename) {
    mFrameLog = File(filename, "w");
    mFrameLog.writeln("frame,elapsed_ms,fps");
    mLogging = true;
    mFrameNum = 0;
}

// In AdvanceFrame(), after computing frame_elapsed:
if (mLogging) {
    mFrameLog.writeln(mFrameNum, ",", frame_elapsed, ",", fps);
    mFrameNum++;
    if (mFrameNum >= 3600) { // 60 seconds at 60fps
        mFrameLog.close();
        mLogging = false;
        writeln("[log] frame log complete");
    }
}
```

This produces a CSV you can plot in Excel or Python to show frame time consistency.

---

## Part 5: Poster Figures From This Data

### Figure A: Cumulative Optimization Impact (Line Chart)
- X-axis: Optimization configuration (A through F)
- Y-axis: FPS
- Separate lines for each object count (100, 500, 1000)
- Shows FPS climbing as optimizations are added

### Figure B: Individual Optimization Contribution (Bar Chart)
- X-axis: Optimization technique name
- Y-axis: FPS drop when disabled (from Phase 2)
- Single bar per technique at 1000 objects
- Tallest bar = most impactful optimization

### Figure C: Scaling Behavior (Line Chart)
- X-axis: Object count (50 to 1000)
- Y-axis: FPS
- Two lines: all optimizations ON vs all OFF
- Shows the gap widening as objects increase

---

## Part 6: Implementation Order

| Priority | Task | Time | What You Get |
|----------|------|------|-------------|
| 1 | Backface culling | 2 min | One-line optimization, measurable |
| 2 | Toggle system (F1-F4 keys) | 15 min | A/B testing capability |
| 3 | Stress test spawner | 15 min | Ability to generate test scenes |
| 4 | Draw distance cutoff | 15 min | Second quick optimization |
| 5 | Frustum culling | 2-3 hours | Most impactful optimization |
| 6 | HUD debug stats | 15 min | Visual proof of culling working |
| 7 | Frame time logger | 15 min | CSV data for detailed analysis |
| 8 | Run all tests | 1 hour | Fill in evaluation tables |
| 9 | Create charts | 30 min | Poster figures |

**Total: ~5-6 hours for everything including data collection.**

Start with items 1-4 (45 minutes), then tackle frustum culling (item 5), then collect data (items 7-9).
