// /// Spawn game entities conviniently

/// Factory for spawning game entities using EntityType definitions
module factory;

import std.stdio;
import std.conv;
import std.string : toStringz, fromStringz;
import std.random : uniform;
import std.math : PI, cos, sin;

import enginecore;
import linear;
import physics;
import geometry;
import materials;
import assimp;
import bindbc.opengl;

import resourcemanager;

import entitytypes;
import materialregistry;

class SpawnFactory
{
    
    EntityManager mEntityManager;
    SceneTree mSceneTree;
    Camera mCamera;
    PhysicsWorld mPhysicsWorld;
    MaterialRegistry mMaterials;
    ResourceManager mResources;

    this(Camera cam, EntityManager em, SceneTree tree, PhysicsWorld physics,
         MaterialRegistry materials, ResourceManager resources)
    {
        mCamera = cam;
        mEntityManager = em;
        mSceneTree = tree;
        mPhysicsWorld = physics;
        mMaterials = materials;
        mResources = resources;
    }

    uint spawn(EntityType type, vec3 pos, Quat orient = Quat.init)
    {
        uint eid = mEntityManager.create();

        vec3 adjustedPos = vec3(pos.x, pos.y + type.yOffset, pos.z);

        if (type.hasPhysics && type.urdfPath !is null)
        {
            mPhysicsWorld.addURDF(eid, type.urdfPath,
                adjustedPos.x, adjustedPos.y, adjustedPos.z,
                orient.x, orient.y, orient.z, orient.w);
            mEntityManager.markPhysics(eid);
        }

        IMaterial mat;
        if (type.texturePath !is null)
            mat = mMaterials.get(type.texturePath);
        else
            mat = mMaterials.get("basic");

        auto model = mResources.getModel(type.modelPath);
        auto nodes = model.createNodes(mSceneTree, mat, type.name ~ "_" ~ eid.to!string, type.maxSubmeshes);

        // Limit submeshes if specified
        if (type.maxSubmeshes > 0 && nodes.length > type.maxSubmeshes)
            nodes = nodes[0 .. type.maxSubmeshes];

        TransformComponent tc;
        tc.position = adjustedPos;
        tc.rotation = orient;
        mEntityManager.addTransform(eid, tc);

        foreach (node; nodes)
        {
            node.mModelMatrix = tc.toModelMatrix()
                * MatrixMakeScale(vec3(type.scale, type.scale, type.scale));
            mEntityManager.addRenderable(eid, node);
        }

        writeln("[spawn] ", type.name, " entity=", eid, " at ", adjustedPos);
        return eid;
    }

    /// Convenience: spawn multiple soldiers at fixed positions
    void spawnSoldiers()
    {
        auto soldierType = EntityType.soldier();
        spawn(soldierType, vec3(33.0f, 0.0f, -10.0f));
        spawn(soldierType, vec3(0.0f, 0.0f, -30.0f));
        spawn(soldierType, vec3(0.0f, 0.0f, -40.0f));
        spawn(soldierType, vec3(13.0f, 0.0f, -17.0f));
        spawn(soldierType, vec3(23.0f, 0.0f, -17.0f));
        spawn(soldierType, vec3(13.0f, 0.0f, -37.0f));
        spawn(soldierType, vec3(43.0f, 0.0f, 17.0f));
    }

    /// Convenience: spawn trees in a ring pattern
    void spawnTrees(int count = 160, float minRadius = 100.0f, float maxRadius = 120.0f)
    {
        auto treeType = EntityType.lindenTree();
        foreach (i; 0 .. count)
        {
            float x, z;
            do
            {
                x = uniform(-maxRadius, maxRadius);
                z = uniform(-maxRadius, maxRadius);
            }
            while ((x * x + z * z) < (minRadius * minRadius));

            spawn(treeType, vec3(x, 0.0f, z));
        }
        writeln("[spawn] ", count, " trees placed");
    }

    /// Stress test: spawn N trees in a ring
    void spawnStressTest(int count)
    {
        auto treeType = EntityType.lindenTree();
        foreach (i; 0 .. count)
        {
            float angle = uniform(0.0f, 2.0f * PI);
            float dist = uniform(150.0f, 400.0f);
            float x = dist * cos(angle);
            float z = dist * sin(angle);
            spawn(treeType, vec3(x, 0.0f, z));
        }
        writeln("[stress] spawned ", count, " trees");
    }
}
