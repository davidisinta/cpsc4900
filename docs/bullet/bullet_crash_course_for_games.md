# Bullet for Games — Crash Course (focused on your Bullet3 SharedMemory/Direct C-API shim)

This is a **game-engine-oriented** crash course for Bullet, written to match your current setup:
- You’re using a custom dylib built from Bullet3 `examples/SharedMemory/*` (PyBullet “Direct” backend).
- You call Bullet through the **C API** (`b3*` functions), not the C++ API directly.

This doc is meant to be a reusable “source of truth” when you:
- set up a physics world
- create bodies/colliders
- step simulation
- do raycasts
- query contacts
- sync transforms to your renderer/ECS

---

## 0) Key idea: physics doesn’t move render objects automatically

Bullet (or your C API shim) only simulates **physics bodies**. Your renderer draws meshes based on your **scene transforms**.

To see gravity move your bunny:
1) create a physics body for the bunny (or a proxy collider)  
2) step physics every frame  
3) **read the pose back** from physics and apply it to the bunny’s model matrix  
4) stop overwriting bunny transforms in `Update()` with fixed values

---

## 1) Bullet concepts for games (what you actually need)

### Worlds
For typical rigid bodies you’ll have:
- a **world** (collision + simulation)
- gravity + timestep
- broadphase/narrowphase contact generation

In the **SharedMemory/Direct C API**, you don’t see `btDiscreteDynamicsWorld*`.
Instead you talk to a physics “server” via a `b3PhysicsClientHandle`.

### Bodies and shapes
Bullet simulates bodies with **collision shapes**:
- Primitive shapes: box/sphere/capsule/cylinder
- Triangle mesh shapes: static level geometry (usually **static only**)
- Convex hulls: better for dynamic objects than raw triangle meshes

### Collisions vs. dynamics
- **Collisions**: overlap/contact generation (who hit whom, contact points).
- **Dynamics**: forces/velocities/integration (gravity makes dynamic bodies fall).

In games:
- Most props/enemies are **dynamic** (mass > 0)
- Level/ground is **static** (mass = 0)

### Raycasting
Raycasts are core for games:
- hitscan weapons
- line of sight
- mouse picking (editor)
- ground checks

Your shim exports raycast commands (`b3CreateRaycastCommandInit`, `b3CreateRaycastBatchCommandInit`, etc.).

---

## 2) Your API surface (what your dylib already exports)

You confirmed these exist:
- **Raycasts**:  
  `b3CreateRaycastCommandInit`, `b3CreateRaycastBatchCommandInit`,  
  `b3RaycastBatchAddRay`, `b3RaycastBatchAddRays`,  
  `b3RaycastBatchSetCollisionFilterMask`, `b3GetRaycastInformation`, etc.

- **Contacts**:  
  `b3InitRequestContactPointInformation`, `b3GetContactPointInformation`,  
  plus filter helpers.

The **authoritative signatures & structs** live in Bullet3:
- `examples/SharedMemory/PhysicsClientC_API.h`
- plus related headers in the same folder (`SharedMemoryPublic.h`, etc.)

Reference source:
- https://github.com/bulletphysics/bullet3/tree/master/examples/SharedMemory  
- https://github.com/bulletphysics/bullet3/blob/master/examples/SharedMemory/PhysicsClientC_API.h

---

# 3) 10 code snippets you’ll actually use

> **Important:** The exact parameter lists/struct layouts should be copied from `PhysicsClientC_API.h`.  
> The snippets below show the **canonical flow** and the “shape” of the code you’ll write.

---

## Snippet 1 — Connect + reset + set gravity + timestep (Direct mode)

```d
extern(C) {
    alias b3PhysicsClientHandle = void*;
    alias b3SharedMemoryCommandHandle = void*;

    b3PhysicsClientHandle b3ConnectPhysicsDirect();
    void b3DisconnectSharedMemory(b3PhysicsClientHandle);

    void* b3SubmitClientCommandAndWaitStatus(b3PhysicsClientHandle, b3SharedMemoryCommandHandle);

    b3SharedMemoryCommandHandle b3InitResetSimulationCommand(b3PhysicsClientHandle);

    b3SharedMemoryCommandHandle b3InitPhysicsParamCommand(b3PhysicsClientHandle);
    int b3PhysicsParamSetGravity(b3SharedMemoryCommandHandle, double gx, double gy, double gz);
    int b3PhysicsParamSetTimeStep(b3SharedMemoryCommandHandle, double dt);
}

b3PhysicsClientHandle client = b3ConnectPhysicsDirect();

// Reset simulation state
auto resetCmd = b3InitResetSimulationCommand(client);
b3SubmitClientCommandAndWaitStatus(client, resetCmd);

// Set gravity + fixed timestep
auto pCmd = b3InitPhysicsParamCommand(client);
b3PhysicsParamSetGravity(pCmd, 0.0, -9.81, 0.0);
b3PhysicsParamSetTimeStep(pCmd, 1.0/60.0);
b3SubmitClientCommandAndWaitStatus(client, pCmd);
```

Game takeaway:
- **use fixed dt** for stable physics
- drive your game loop to call “step” at fixed dt (see snippet 4)

---

## Snippet 2 — Set additional search path (so you can load URDF assets)

Bullet3 ships URDFs in its data folder; you can also keep your own.

```d
extern(C) {
    b3SharedMemoryCommandHandle b3SetAdditionalSearchPath(b3PhysicsClientHandle, const(char)* path);
}

b3SetAdditionalSearchPath(client, "/path/to/bullet3/data".toStringz);
// Or your repo path: "assets/physics".toStringz
```

Why this matters:
- URDF loading often references meshes via relative paths.
- Search path lets the loader find those files.

---

## Snippet 3 — Load a URDF body (static ground or dynamic object)

You already declared URDF load commands. Typical flow:
1) init load command
2) set start pose
3) submit, read status, get `bodyId`

```d
extern(C) {
    b3SharedMemoryCommandHandle b3LoadUrdfCommandInit(b3PhysicsClientHandle, const(char)* urdfFileName);
    int b3LoadUrdfCommandSetStartPosition(b3SharedMemoryCommandHandle, double x, double y, double z);
    int b3LoadUrdfCommandSetStartOrientation(b3SharedMemoryCommandHandle, double x, double y, double z, double w);

    int b3GetStatusBodyIndex(void* statusHandle);
    int b3GetStatusType(void* statusHandle);
}

enum int CMD_URDF_LOADING_COMPLETED = 6;

auto cmd = b3LoadUrdfCommandInit(client, "plane.urdf".toStringz);
b3LoadUrdfCommandSetStartPosition(cmd, 0, 0, 0);
b3LoadUrdfCommandSetStartOrientation(cmd, 0, 0, 0, 1);

auto status = b3SubmitClientCommandAndWaitStatus(client, cmd);

if (b3GetStatusType(status) == CMD_URDF_LOADING_COMPLETED) {
    int groundBodyId = b3GetStatusBodyIndex(status);
}
```

Game takeaway:
- You need a **static ground** or everything falls forever.

---

## Snippet 4 — Step simulation each frame (fixed dt accumulator)

Don’t tie physics step to your variable render frame time.
Use an accumulator so physics advances at 60Hz (or 120Hz) reliably.

```d
extern(C) {
    b3SharedMemoryCommandHandle b3InitStepSimulationCommand(b3PhysicsClientHandle);
}

enum int CMD_STEP_FORWARD_SIMULATION_COMPLETED = 26;

double fixedDt = 1.0 / 60.0;
double accumulator = 0.0;
double lastTime = nowSeconds(); // implement using SDL_GetTicks()/StopWatch

while (running) {
    double t = nowSeconds();
    double frameDt = t - lastTime;
    lastTime = t;

    // Clamp to avoid spiral-of-death on pauses
    if (frameDt > 0.25) frameDt = 0.25;

    accumulator += frameDt;

    while (accumulator >= fixedDt) {
        auto stepCmd = b3InitStepSimulationCommand(client);
        auto status = b3SubmitClientCommandAndWaitStatus(client, stepCmd);
        // optionally assert status type
        accumulator -= fixedDt;
    }

    renderFrame();
}
```

Game takeaway:
- fixed-step physics = predictable collisions and stable stacking.

---

## Snippet 5 — Read a body pose (base position + orientation)

To render a physics-driven object, you must read the pose each frame.

**You need to bind the pose getter functions** from `PhysicsClientC_API.h`:
Common ones include something like:
- `b3GetBasePositionAndOrientation(...)`
- or a “request state + get state” workflow

**Pattern** (pseudo; bind exact calls from header):

```d
extern(C) {
    // Look up the exact function name/signature in PhysicsClientC_API.h
    void b3GetBasePositionAndOrientation(b3PhysicsClientHandle, int bodyId, double* posOut, double* ornOut);
}

double[3] pos;
double[4] orn; // quaternion x,y,z,w
b3GetBasePositionAndOrientation(client, bunnyBodyId, pos.ptr, orn.ptr);

// Convert to your math types and set model matrix
auto T = translation(pos[0], pos[1], pos[2]) * quatToMat4(orn);
bunnyNode.mModelMatrix = T;
```

Game takeaway:
- This is the key “physics -> render” sync point.

---

## Snippet 6 — Contact points query (collisions)

You exported contact query functions. Flow:
1) init request contact info
2) optionally set filters (body A/B)
3) submit + wait
4) read contact information struct

```d
extern(C) {
    alias b3SharedMemoryStatusHandle = void*;

    b3SharedMemoryCommandHandle b3InitRequestContactPointInformation(b3PhysicsClientHandle);
    int b3SetContactFilterBodyA(b3SharedMemoryCommandHandle, int bodyIdA);
    int b3SetContactFilterBodyB(b3SharedMemoryCommandHandle, int bodyIdB);

    // struct b3ContactInformation is defined in SharedMemoryPublic.h
    int b3GetContactPointInformation(b3PhysicsClientHandle, b3ContactInformation* info);
}

// 1) request contacts
auto ccmd = b3InitRequestContactPointInformation(client);

// (optional) filter: only contacts involving bunny
b3SetContactFilterBodyA(ccmd, bunnyBodyId);

auto cstatus = b3SubmitClientCommandAndWaitStatus(client, ccmd);

// 2) read results
b3ContactInformation info;
b3GetContactPointInformation(client, &info);

// 3) iterate contacts (exact fields come from header)
foreach (i; 0 .. info.m_numContactPoints) {
    auto cp = info.m_contactPointData[i];
    // cp may contain bodyUniqueIdA/B, positions, normal, distance, etc.
}
```

Game takeaway:
- You convert this into gameplay events: enter/stay/exit.

---

## Snippet 7 — Single raycast command (closest hit)

Your shim exports `b3CreateRaycastCommandInit` + `b3GetRaycastInformation`.

```d
extern(C) {
    b3SharedMemoryCommandHandle b3CreateRaycastCommandInit(b3PhysicsClientHandle,
        double fromX, double fromY, double fromZ,
        double toX, double toY, double toZ);

    int b3GetRaycastInformation(b3PhysicsClientHandle, b3RaycastInformation* info);
}

// Fire a ray from camera to far plane
auto rcmd = b3CreateRaycastCommandInit(client,
    camFrom.x, camFrom.y, camFrom.z,
    camTo.x,   camTo.y,   camTo.z);

auto rstatus = b3SubmitClientCommandAndWaitStatus(client, rcmd);

b3RaycastInformation rinfo;
b3GetRaycastInformation(client, &rinfo);

// rinfo typically includes hitObjectUniqueId, hitPositionWorld, hitNormalWorld, hitFraction
```

Game takeaway:
- Use this for editor picking / single-shot tests.

---

## Snippet 8 — Batch raycasts (best practice for games)

Batch rays reduce overhead and let Bullet parallelize.

```d
extern(C) {
    b3SharedMemoryCommandHandle b3CreateRaycastBatchCommandInit(b3PhysicsClientHandle);
    int b3RaycastBatchAddRay(b3SharedMemoryCommandHandle,
        double fromX, double fromY, double fromZ,
        double toX, double toY, double toZ);

    int b3RaycastBatchSetNumThreads(b3SharedMemoryCommandHandle, int numThreads);
    int b3RaycastBatchSetCollisionFilterMask(b3SharedMemoryCommandHandle, int mask);
    int b3RaycastBatchSetFractionEpsilon(b3SharedMemoryCommandHandle, double eps);
}

auto bcmd = b3CreateRaycastBatchCommandInit(client);
b3RaycastBatchSetNumThreads(bcmd, 4);
b3RaycastBatchSetCollisionFilterMask(bcmd, 0xFFFF);
b3RaycastBatchSetFractionEpsilon(bcmd, 0.0);

// Add N rays
foreach (ray; rays) {
    b3RaycastBatchAddRay(bcmd,
        ray.from.x, ray.from.y, ray.from.z,
        ray.to.x,   ray.to.y,   ray.to.z);
}

auto bstatus = b3SubmitClientCommandAndWaitStatus(client, bcmd);

b3RaycastInformation info;
b3GetRaycastInformation(client, &info);
// Parse results for each ray index
```

Game takeaway:
- Use batch rays for AI, gunfire, ground checks, visibility.

---

## Snippet 9 — Collision filtering layers (raycasts + contacts)

Games usually use layers:
- PLAYER
- ENEMY
- WORLD
- TRIGGER
- PROJECTILE

Raycasts can ignore triggers, for example.

```d
enum int LAYER_WORLD      = 1 << 0;
enum int LAYER_PLAYER     = 1 << 1;
enum int LAYER_ENEMY      = 1 << 2;
enum int LAYER_TRIGGER    = 1 << 3;
enum int LAYER_PROJECTILE = 1 << 4;

// Raycast that hits world + enemies but ignores triggers and player
int mask = LAYER_WORLD | LAYER_ENEMY;
b3RaycastBatchSetCollisionFilterMask(bcmd, mask);
```

Contacts filtering:
- Use `b3SetContactFilterBodyA/B` for “contacts involving X”
- For full layer masks, you typically configure collision filters when creating bodies (depends on API functions you bind).

---

## Snippet 10 — A tiny D wrapper around your binding (engine-friendly API)

This is the pattern you want: keep `_b3*` calls inside the physics module.

```d
module physics.world;

import physics.types;
import physics.bullet_capi;

struct PhysicsWorld {
    b3PhysicsClientHandle client;
    double fixedDt = 1.0/60.0;

    void init() {
        client = b3ConnectPhysicsDirect();
        auto r = b3InitResetSimulationCommand(client);
        b3SubmitClientCommandAndWaitStatus(client, r);

        auto p = b3InitPhysicsParamCommand(client);
        b3PhysicsParamSetGravity(p, 0, -9.81, 0);
        b3PhysicsParamSetTimeStep(p, fixedDt);
        b3SubmitClientCommandAndWaitStatus(client, p);
    }

    void shutdown() {
        if (client !is null) {
            b3DisconnectSharedMemory(client);
            client = null;
        }
    }

    void stepOneTick() {
        auto s = b3InitStepSimulationCommand(client);
        b3SubmitClientCommandAndWaitStatus(client, s);
    }

    // Minimal raycast wrapper (batch or single)
    Hit raycastClosest(float3 from, float3 to, int mask) {
        auto cmd = b3CreateRaycastBatchCommandInit(client);
        b3RaycastBatchSetCollisionFilterMask(cmd, mask);
        b3RaycastBatchAddRay(cmd, from.x, from.y, from.z, to.x, to.y, to.z);
        b3SubmitClientCommandAndWaitStatus(client, cmd);

        b3RaycastInformation info;
        b3GetRaycastInformation(client, &info);

        // TODO: parse info (fields are in SharedMemoryPublic.h)
        Hit h;
        // h.hit = ...
        return h;
    }
}
```

Your task after this:
- add create body helpers (box/capsule/mesh or URDF wrappers)
- add `getBodyPose()` for transform sync
- add contact queries and collision event generation
- add sweep tests if/when needed for character controller

---

# 4) “Games essentials” checklist (what you must implement next)

### A) Basic world + bodies
- world init / shutdown
- gravity + fixed dt
- ground plane
- dynamic test body (box)

### B) Render sync
- `getBodyPose(bodyId)` → apply to model matrix
- stop overwriting transforms for physics-driven objects

### C) Queries
- batch raycasts (primary)
- contact queries (for gameplay collisions)
- optional: sweep test (capsule) for character controller

### D) Filtering
- layer masks for raycasts
- body-based filtering for contacts
- (later) collision group/mask at body creation time

---

# 5) High-signal references (Bullet + your C API)

### Bullet3 / PyBullet C API
- SharedMemory C API header (source of truth for `b3*` signatures):  
  https://github.com/bulletphysics/bullet3/blob/master/examples/SharedMemory/PhysicsClientC_API.h

- C API implementation (helps you understand expected usage patterns):  
  https://github.com/bulletphysics/bullet3/blob/master/examples/SharedMemory/PhysicsClientC_API.cpp

- “No GUI” client examples (often easiest to read):  
  https://github.com/bulletphysics/bullet3/blob/master/examples/SharedMemory/b3RobotSimulatorClientAPI_NoGUI.cpp

### Bullet docs (C++ reference, still valuable conceptually)
- Bullet API docs index:  
  https://pybullet.org/Bullet/BulletFull/index.html

- `btCollisionWorld` docs (rayTest, convexSweepTest):  
  https://pybullet.org/Bullet/BulletFull/classbtCollisionWorld.html

- Bullet User Manual (PDF):  
  https://raw.githubusercontent.com/bulletphysics/bullet3/master/docs/Bullet_User_Manual.pdf

### Forums / gotchas
- Bullet forum (practical troubleshooting):  
  https://pybullet.org/wordpress/index.php/forum-2/

---

# 6) Practical mapping to your engine (what changes in your current OpenGL code)

In your current `Update()` you hardcode:
- translation
- rotation

If bunny should be physics-driven:
- remove/disable that hardcoded translation/rotation
- replace with transform pulled from Bullet each frame (snippet 5)

Also:
- step physics each frame (snippet 4)
- create a ground and bunny body (snippet 3 + body pose retrieval)

---

## Appendix: common game-engine choices
- Use triangle mesh collision for **static** level geometry.
- Use convex shapes (capsule/box/hull) for **dynamic** objects.
- Prefer batch raycasts over per-ray calls.
- Fixed dt physics; interpolate for rendering if needed.
