module entitymanager;

/// Lightweight entity registry that acts as the central bridge between
/// the physics world and the rendering scene tree.
///
/// Design rationale:
///   - We do NOT need a full ECS framework. What we need is a shared
///     "phone book" so that when Bullet says "body 3 moved to (x,y,z)",
///     we can instantly look up the corresponding MeshNode and update
///     its model matrix.
///   - This replaces the pattern of scattering entity knowledge across
///     GraphicsEngine.Update(), PhysicsWorld.entityToBody, and ad-hoc
///     FindNode() calls by name.
///
/// Usage:
///   auto em = new EntityManager();
///   uint id = em.create();
///   em.transforms[id] = TransformComponent(...);
///   em.renderables[id] = someMeshNode;
///   // PhysicsWorld.addURDF already stores entityToBody[id]
///

import linear;
import scene;
import mesh;
import transform;

/// Central entity registry.
/// Owns the canonical transform for every entity.
/// Physics writes INTO transforms[], rendering reads FROM it.
class EntityManager
{
    //------------------------------------------------------------------
    // ID allocation
    //------------------------------------------------------------------
    private uint mNextId = 1; // 0 is reserved as "null entity"

    /// Allocate a fresh entity ID.
    uint create()
    {
        return mNextId++;
    }

    //------------------------------------------------------------------
    // Component tables  (parallel associative arrays keyed by entityId)
    //------------------------------------------------------------------

    /// The authoritative transform for each entity.
    /// Physics sync writes here; rendering reads here.
    TransformComponent[uint] transforms;

    /// The MeshNode in the SceneTree that visualises this entity.
    /// null / absent  →  entity has no visual representation.
    MeshNode[uint] renderables;

    /// Convenience: does this entity have a physics body?
    /// (The actual bodyId lives in PhysicsWorld.entityToBody.)
    bool[uint] hasPhysics;

    //------------------------------------------------------------------
    // Lifecycle helpers
    //------------------------------------------------------------------

    /// Register a transform for an entity (call right after create()).
    void addTransform(uint id, TransformComponent t)
    {
        transforms[id] = t;
    }

    /// Link a MeshNode to an entity so the sync system can push
    /// model matrices into it.
    void addRenderable(uint id, MeshNode node)
    {
        renderables[id] = node;
    }

    /// Mark this entity as physics-driven.
    void markPhysics(uint id)
    {
        hasPhysics[id] = true;
    }

    /// Full cleanup when an entity is destroyed.
    void destroy(uint id)
    {
        transforms.remove(id);
        renderables.remove(id);
        hasPhysics.remove(id);
        // NOTE: caller is also responsible for:
        //   - PhysicsWorld.unbindEntity(id)
        //   - removing the MeshNode from the SceneTree
    }
}