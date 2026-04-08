/// Transform sync — the bridge between Bullet physics and the OpenGL scene.
///
/// After PhysicsWorld.updatePhysics() steps the simulation, call
/// syncPhysicsToRender() to pull every physics-driven entity's
/// position+orientation from Bullet and push it into the MeshNode's
/// mModelMatrix so the next Render() draws it in the right place.
///
/// This module exists to keep the coupling one-directional:
///   Bullet  →  TransformComponent  →  MeshNode.mModelMatrix
///
/// Neither PhysicsWorld nor MeshNode need to know about each other.
///
module transformsync;

import std.stdio;
import std.conv : to;

import linear;
import mesh;
import scene;
import transform;
import entitymanager;
import physicsworld;

/// Pull transforms from Bullet for every physics-driven entity
/// and write them into the corresponding MeshNode model matrices.
///
/// Call this once per frame, AFTER updatePhysics() and BEFORE Render().
///
/// Params:
///   world  = the PhysicsWorld that owns the Bullet client
///   em     = the EntityManager that owns transforms[] and renderables[]
///   debugLog = if true, print position each frame (disable in production)
void syncPhysicsToRender(ref PhysicsWorld world, EntityManager em, bool debugLog = false)
{
    // Iterate every entity that has a physics body
    foreach (entityId, bodyId; world.entityToBody)
    {
        // 1. Query Bullet for the body's current transform
        auto bt = world.getBodyTransform(entityId);

        // 2. Update the canonical TransformComponent
        if (auto tc = entityId in em.transforms)
        {
            tc.position = vec3(
                cast(float) bt.position[0],
                cast(float) bt.position[1],
                cast(float) bt.position[2]
            );
            double[4] q = [bt.orientation[0], bt.orientation[1],
                           bt.orientation[2], bt.orientation[3]];
            tc.rotation = Quat.fromBulletDoubles(q);

            // 3. Push into MeshNode
            // for each node in the renderables, then sync it with the transform
            // foreach(node; em.renderables[entityId]){
            //     node.mModelMatrix = tc.toModelMatrix();
            // }

            // do the checking before unwrapping make it safe
            if (auto nodes = entityId in em.renderables)
            {
                foreach (node; *nodes)
                {
                    node.mModelMatrix = tc.toModelMatrix();
                }
            }




            // if (auto node = entityId in em.renderables)
            // {
            //     node.mModelMatrix = tc.toModelMatrix();
            // }

            // 4. Optional debug output
            if (debugLog)
            {
                writefln("[sync] entity=%d  pos=[%.3f, %.3f, %.3f]  quat=[%.3f, %.3f, %.3f, %.3f]",
                    entityId,
                    bt.position[0], bt.position[1], bt.position[2],
                    bt.orientation[0], bt.orientation[1],
                    bt.orientation[2], bt.orientation[3]);
            }
        }
    }
}