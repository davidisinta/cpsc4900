# Physics vs Rendering Architecture --- Reference Notes

## User Question

> okay now let us discuss architecture, let us say we have a mesh, which
> could be say a .obj file, that we have described in the engine, once
> we create it in the engine, do we need to create it in physcis world
> too, and suppose this object moves in rendered world, do we tell
> physics engine, what coordinates do both systems use, also do I need a
> corresponding urdf for this .obj, talk me through that...

------------------------------------------------------------------------

## Architecture Discussion

In a typical engine you have **two separate representations** of the
same game object:

1.  **Render representation** (mesh/material)\
2.  **Physics representation** (collision shape + rigid body)

They are related but not identical. You usually **do not create the
`.obj` directly in physics**. Instead, physics uses a **collision
approximation**.

------------------------------------------------------------------------

## 1. Do you need to create it in physics too?

Only if the object should participate in physics:

-   Render-only decoration → Render only
-   Static collidable (floor, wall) → Static physics body + render mesh
-   Dynamic object (crate, player) → Dynamic physics body + render mesh

Physics requires a separate object, but not the `.obj` itself.

------------------------------------------------------------------------

## 2. What physics actually needs

Physics needs a **collision shape**, not rendering geometry.

### Primitive Collider (Recommended)

-   Box
-   Sphere
-   Capsule
-   Cylinder

Fast and stable.

### Convex Hull

-   Built from mesh vertices
-   Good for irregular rigid objects

### Triangle Mesh

-   Exact geometry
-   Expensive
-   Should be static only

------------------------------------------------------------------------

## 3. If the rendered object moves --- who informs physics?

### Physics-driven (Dynamic)

Physics is authoritative.

Flow: 1. Apply forces to physics body 2. Step simulation 3. Read
transforms from physics 4. Renderer follows physics

Render follows physics.

------------------------------------------------------------------------

### Engine-driven (Kinematic)

Engine is authoritative.

Flow: 1. Engine updates transform 2. Update physics body transform 3.
Physics resolves collisions 4. Renderer uses same transform

Physics follows engine.

------------------------------------------------------------------------

### Static

Never moves.

------------------------------------------------------------------------

## 4. Coordinate Systems

Both systems should share:

-   Right-handed coordinates
-   Z-up (consistent with gravity `(0,0,-9.81)`)
-   Units in meters
-   Quaternion orientation `(x,y,z,w)`

Avoid mixing: - Y-up vs Z-up - centimeters vs meters

Consistency removes conversion overhead.

------------------------------------------------------------------------

## 5. Do you need a URDF for each `.obj`?

Not inherently.

### Pattern A --- Engine-native Physics (Ideal)

    Entity:
      Mesh: crate.obj
      Collider: Box
      RigidBody: dynamic

No URDF required.

------------------------------------------------------------------------

### Pattern B --- URDF Physics Prefab (Current Approach)

URDF defines: - collision - mass - inertial properties

Renderer loads `.obj` independently.

------------------------------------------------------------------------

### Pattern C --- URDF for Prototyping

Useful for early bring-up and testing.

------------------------------------------------------------------------

## Recommended Current Workflow

For each object:

1.  Engine loads render mesh (`crate.obj`)
2.  Physics loads URDF (`crate.urdf`)
3.  Map both to same entity

```{=html}
<!-- -->
```
    entityId → bodyId
    entityId → renderMeshHandle

------------------------------------------------------------------------

## Source of Truth Rule

Choose ONE authority per entity:

-   Dynamic → Physics authoritative
-   Kinematic → Engine authoritative
-   Static → No updates

All synchronization flows from this decision.

------------------------------------------------------------------------

## Next Logical Step

Implement transform synchronization:

-   `PhysicsWorld.syncToRender()`
-   `PhysicsWorld.syncFromRender()`

This bridges simulation and rendering.
