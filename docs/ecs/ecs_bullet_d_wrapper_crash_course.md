# ECS + Bullet (Collisions & Raycasting) + Building a D Wrapper (Crash Course)

David — this is a practical “source of truth” doc you can reuse when wiring physics into your Sting3DEngine.

---

## 1) ECS (Entity-Component-System)

### The core idea
ECS is a way to structure game/engine code around **data (components)** and **batch processing (systems)** rather than deep class hierarchies.

- **Entity**: just an **ID** (no behavior).
- **Component**: plain data attached to an entity (e.g., Transform, RigidBody).
- **System**: logic that runs over all entities having a required set of components.

Why engines like ECS:
- Great cache locality when you store components in arrays.
- Clear separation between data (components) and logic (systems).
- Easy to scale to many objects, and easy to add/remove features.

### Minimal example (conceptual D-style snippets)

#### Entities are IDs
```d
alias Entity = uint;
```

#### Components are plain structs
```d
struct Transform {
    float3 pos;
    quat rot;
    float3 scale;
}

struct RigidBody {
    int bodyId;        // physics handle (Bullet/your binding)
    bool dynamic;      // dynamic bodies are moved by physics
}

struct Collider {
    uint layerMask;    // collision filtering
}
```

#### Registry stores components (toy implementation)
```d
struct Registry {
    Transform[Entity] transforms;
    RigidBody[Entity] rigidBodies;
    Collider[Entity] colliders;

    bool hasRigidBody(Entity e) { return e in rigidBodies; }
    bool hasTransform(Entity e) { return e in transforms; }
}
```

#### System: physics sync (ECS <-> physics)
There are two common sync directions:

- **Kinematic / player-controlled objects**: ECS is source of truth → push into physics.
- **Dynamic objects**: physics is source of truth → pull back into ECS after stepping.

```d
void physicsPreStepPushKinematics(ref Registry r, ref PhysicsWorld phys) {
    foreach (e, rb; r.rigidBodies) {
        if (!rb.dynamic) { // kinematic
            auto t = r.transforms[e];
            phys.setBodyTransform(rb.bodyId, t.pos, t.rot);
        }
    }
}

void physicsPostStepPullDynamics(ref Registry r, ref PhysicsWorld phys) {
    foreach (e, rb; r.rigidBodies) {
        if (rb.dynamic) { // dynamic
            auto pose = phys.getBodyPose(rb.bodyId);
            r.transforms[e].pos = pose.pos;
            r.transforms[e].rot = pose.rot;
        }
    }
}
```

### Mental model for ownership (the “source of truth” rule)
Pick ONE per body type:

- **Dynamic**: Physics owns position/rotation after simulation.
- **Kinematic**: ECS/gameplay owns position/rotation; physics follows.
- **Static**: never moves; treat as environment.

This avoids jitter/fighting between systems.

---

## 2) Bullet Physics: collisions + raycasting

### Bullet collision pipeline (what matters for you)
Bullet runs collision detection in phases:

1. **Broadphase**: cheap “which AABBs might overlap?” filtering.
2. **Narrowphase**: precise shape-shape collision to generate contact points.
3. **Solver** (if using dynamics): resolves contacts & constraints to update velocities/positions.

For pure queries (raycasts / sweeps), Bullet typically:
- uses broadphase to find candidate objects,
- then tests geometry precisely on those candidates.

Bullet reference points for your use:
- `btDiscreteDynamicsWorld` is the common rigid-body world. citeturn0search10
- Collision shapes shareable via `btCollisionShape`. citeturn0search1
- Raycasts use `btCollisionWorld::rayTest`. citeturn0search0turn0search15
- Official manual (PDF) is a good grounding doc for integration patterns. citeturn0search5

---

### Code example 1 (C++ Bullet): Closest-hit raycast
This is the “FPS gun ray” / “picking” / “line of sight” pattern.

```cpp
btVector3 from = btVector3(0, 2, 0);
btVector3 to   = btVector3(0, -50, 0);

btCollisionWorld::ClosestRayResultCallback cb(from, to);
world->rayTest(from, to, cb);

if (cb.hasHit()) {
    btVector3 hitPoint  = cb.m_hitPointWorld;
    btVector3 hitNormal = cb.m_hitNormalWorld;
    const btCollisionObject* hitObj = cb.m_collisionObject;
    // Use hitObj->getUserPointer() to map back to your ECS entity (when using direct Bullet).
}
```

Bullet docs for rayTest and ClosestRayResultCallback: citeturn0search0turn0search15

---

### Code example 2 (C++ Bullet): Convex sweep (thick ray)
If you want “raycasting with volume” (typical character controller / capsule movement), use a **convex sweep**.

```cpp
btCapsuleShape capsule(radius, height);
btTransform from; from.setIdentity(); from.setOrigin(startPos);
btTransform to;   to.setIdentity();   to.setOrigin(endPos);

btCollisionWorld::ClosestConvexResultCallback cb(startPos, endPos);
world->convexSweepTest(&capsule, from, to, cb);

if (cb.hasHit()) {
    btVector3 hitPoint  = cb.m_hitPointWorld;
    btVector3 hitNormal = cb.m_hitNormalWorld;
    btScalar  frac      = cb.m_closestHitFraction; // where along sweep it hit
}
```

Bullet docs mention sweep tests alongside rayTest: citeturn0search0turn0search9

---

### Code example 3 (YOUR setup): PyBullet/SharedMemory C-API batch raycasts
Your dylib exports these functions (you already saw them in `nm`), e.g.:
- `b3CreateRaycastBatchCommandInit`
- `b3RaycastBatchAddRay`
- `b3RaycastBatchSetCollisionFilterMask`
- `b3GetRaycastInformation`

The flow is always:
1) create command
2) add rays / set params
3) submit command + wait status
4) fetch raycast info

**Pseudo-code** (names match your exported `_b3...` functions; signatures depend on the header):
```d
// 1) init batch command
auto cmd = b3CreateRaycastBatchCommandInit(client);

// 2) add rays
foreach (ray; rays) {
    b3RaycastBatchAddRay(cmd,
        ray.from.x, ray.from.y, ray.from.z,
        ray.to.x,   ray.to.y,   ray.to.z);
}

// 3) optional: collision filtering
b3RaycastBatchSetCollisionFilterMask(cmd, myMask);

// 4) submit + wait
auto status = b3SubmitClientCommandAndWaitStatus(client, cmd);

// 5) read results
b3RaycastInformation info;
b3GetRaycastInformation(client, &info);
// info should contain hit fractions/ids/positions/normals for each ray
```

Where to find the authoritative function signatures:
- `examples/SharedMemory/PhysicsClientC_API.h` (Bullet3) citeturn0search2

---

### Collisions / contacts (high value for gameplay)
You also exported contact query functions:
- `b3InitRequestContactPointInformation`
- `b3GetContactPointInformation`

Typical use:
- After stepping simulation: request contacts for all or filtered by body A/B.
- Convert to ECS events:
  - **Enter**: new contact this frame not present last frame
  - **Stay**: present last frame and this frame
  - **Exit**: present last frame but not this frame

That event layer is engine-owned (not Bullet-owned).

---

## 3) Building a small D physics library around your Bullet binding

Goal: keep `_b3...` / `b3...` functions out of gameplay and rendering code.

### Design principles
1. **Single entrypoint**: one `PhysicsWorld` object.
2. **Explicit ownership**:
   - dynamic bodies are written back into ECS
   - kinematic bodies are pushed into physics
3. **Central mapping**: `EntityId <-> bodyId` stored inside physics module.
4. **No “Bullet types” leak** across your engine boundary (keep Bullet-specific types inside the physics module).

---

### Minimal module layout
```
source/physics/
  bullet_capi.d        // extern(C) declarations (the raw API)
  world.d              // PhysicsWorld wrapper (safe API)
  types.d              // float3, quat, Hit, Contact, etc.
  convert.d            // matrix/quaternion conversions
```

---

### Minimal types
```d
module physics.types;

struct float3 { float x,y,z; }
struct quat   { float x,y,z,w; }

struct Hit {
    bool hit;
    int bodyId;      // physics handle
    float fraction;  // 0..1 along ray
    float3 point;
    float3 normal;
}

struct Pose {
    float3 pos;
    quat   rot;
}
```

---

### Minimal PhysicsWorld wrapper (skeleton)
This is deliberately small so you can extend it.

```d
module physics.world;

import physics.types;
import physics.bullet_capi; // raw extern(C)

struct PhysicsWorld {
    b3PhysicsClientHandle client;
    double fixedDt = 1.0 / 60.0;

    // Engine mapping (you own this):
    int[uint] entityToBody;   // Entity -> bodyId
    uint[int] bodyToEntity;   // bodyId -> Entity

    void init() {
        client = b3ConnectPhysicsDirect();

        // reset
        auto resetCmd = b3InitResetSimulationCommand(client);
        b3SubmitClientCommandAndWaitStatus(client, resetCmd);

        // gravity + timestep
        auto pCmd = b3InitPhysicsParamCommand(client);
        b3PhysicsParamSetGravity(pCmd, 0.0, -9.81, 0.0);
        b3PhysicsParamSetTimeStep(pCmd, fixedDt);
        b3SubmitClientCommandAndWaitStatus(client, pCmd);
    }

    void shutdown() {
        if (client !is null) {
            b3DisconnectSharedMemory(client);
            client = null;
        }
    }

    void step() {
        auto cmd = b3InitStepSimulationCommand(client);
        auto status = b3SubmitClientCommandAndWaitStatus(client, cmd);
        // optionally check status type == CMD_STEP_FORWARD_SIMULATION_COMPLETED
    }

    // TODO: createBodyBox / createBodyMesh / etc.
    // TODO: getBodyPose(bodyId) / setBodyPose(bodyId)
    // TODO: raycastClosest(...)
}
```

This gives you a clean “place to add features” without rewriting your engine.

---

### The integration point in your engine loop
In your `GraphicsEngine.Loop()` or similar:

```d
PhysicsWorld phys;
phys.init();

while (mGameIsRunning) {
    // 1) push kinematics (player-controlled) into physics (optional)
    // physicsPreStepPushKinematics(registry, phys);

    // 2) step physics
    phys.step();

    // 3) pull dynamic transforms out of physics into ECS
    // physicsPostStepPullDynamics(registry, phys);

    // 4) render from ECS transforms
    AdvanceFrame();
}

phys.shutdown();
```

Key: don’t overwrite your bunny transform every frame if you want physics to move it.

---

## Bullet-focused reference sites (high signal)

- Bullet class docs (`btCollisionWorld::rayTest`, sweep tests). citeturn0search0turn0search15
- Bullet collision shapes overview (`btCollisionShape`). citeturn0search1
- Bullet dynamics world (`btDiscreteDynamicsWorld`). citeturn0search10
- Official Bullet user manual PDF (integration patterns, stepping, syncing graphics). citeturn0search5
- Bullet3 Raytest demo source (real usage patterns). citeturn0search3
- PyBullet / SharedMemory C API header (authoritative C function signatures). citeturn0search2

> Tip: when you’re binding functions, the C API header is the source of truth for signatures and structs. citeturn0search2

---

## Practical “next tasks” for you (incremental)
1) Add “ground plane” creation (static body) in your wrapper.
2) Add “dynamic box body” creation for testing gravity.
3) Add `getBodyPose(bodyId)` and `setBodyPose(bodyId)`.
4) Replace bunny’s hardcoded transform with physics-driven pose.
5) Add raycast wrapper returning `Hit` and map bodyId -> entityId.

Once those 5 exist, you can build:
- FPS gun hit scan
- picking in editor
- ground checks
- simple collisions
