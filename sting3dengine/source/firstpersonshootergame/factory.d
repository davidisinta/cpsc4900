// // /// Spawn game entities conviniently

// /// Factory for spawning game entities using EntityType definitions
// module factory;

// import std.stdio;
// import std.conv;
// import std.string : toStringz, fromStringz;
// import std.random : uniform;
// import std.math : PI, cos, sin;

// import enginecore;
// import linear;
// import physics;
// import geometry;
// import materials;
// import assimp;
// import bindbc.opengl;

// import resourcemanager;

// import entitytypes;
// import materialregistry;

// class SpawnFactory
// {
    
//     EntityManager mEntityManager;
//     SceneTree mSceneTree;
//     Camera mCamera;
//     PhysicsWorld mPhysicsWorld;
//     MaterialRegistry mMaterials;
//     ResourceManager mResources;

//     this(Camera cam, EntityManager em, SceneTree tree, PhysicsWorld physics,
//          MaterialRegistry materials, ResourceManager resources)
//     {
//         mCamera = cam;
//         mEntityManager = em;
//         mSceneTree = tree;
//         mPhysicsWorld = physics;
//         mMaterials = materials;
//         mResources = resources;
//     }

//     uint spawn(EntityType type, vec3 pos, Quat orient = Quat.init)
//     {
//         uint eid = mEntityManager.create();

//         vec3 adjustedPos = vec3(pos.x, pos.y + type.yOffset, pos.z);

//         if (type.hasPhysics && type.urdfPath !is null)
//         {
//             mPhysicsWorld.addURDF(eid, type.urdfPath,
//                 adjustedPos.x, adjustedPos.y, adjustedPos.z,
//                 orient.x, orient.y, orient.z, orient.w);
//             mEntityManager.markPhysics(eid);
//         }

//         IMaterial mat;
//         if (type.texturePath !is null)
//             mat = mMaterials.get(type.texturePath);
//         else
//             mat = mMaterials.get("basic");

//         auto model = mResources.getModel(type.modelPath);
//         auto nodes = model.createNodes(mSceneTree, mat, type.name ~ "_" ~ eid.to!string, type.maxSubmeshes);

//         // Limit submeshes if specified
//         if (type.maxSubmeshes > 0 && nodes.length > type.maxSubmeshes)
//             nodes = nodes[0 .. type.maxSubmeshes];

//         TransformComponent tc;
//         tc.position = adjustedPos;
//         tc.rotation = orient;
//         mEntityManager.addTransform(eid, tc);

//         foreach (node; nodes)
//         {
//             node.mModelMatrix = tc.toModelMatrix()
//                 * MatrixMakeScale(vec3(type.scale, type.scale, type.scale));
//             mEntityManager.addRenderable(eid, node);
//         }

//         // writeln("[spawn] ", type.name, " entity=", eid, " at ", adjustedPos);
//         return eid;
//     }

//     // // / Convenience: spawn multiple soldiers at fixed positions
//     // void spawnSoldiers()
//     // {
//     //     // auto soldierType = EntityType.soldier();
//     //     // spawn(soldierType, vec3(33.0f, 0.0f, -10.0f));
//     //     // spawn(soldierType, vec3(0.0f, 0.0f, -30.0f));
//     //     // spawn(soldierType, vec3(0.0f, 0.0f, -40.0f));
//     //     // spawn(soldierType, vec3(13.0f, 0.0f, -17.0f));
//     //     // spawn(soldierType, vec3(23.0f, 0.0f, -17.0f));
//     //     // spawn(soldierType, vec3(13.0f, 0.0f, -37.0f));
//     //     // spawn(soldierType, vec3(43.0f, 0.0f, 17.0f));


//     //     auto soldierType = EntityType.soldier();
//     //     // Arena area
//     //     spawn(soldierType, vec3(21.7f, 0.0f, -7.8f));
//     //     spawn(soldierType, vec3(35.3f, 0.0f, -13.9f));
//     //     spawn(soldierType, vec3(41.1f, 0.0f, -26.9f));
//     //     spawn(soldierType, vec3(20.1f, 0.0f, -32.7f));
//     //     spawn(soldierType, vec3(12.3f, 0.0f, -30.7f));
//     //     // Far side
//     //     spawn(soldierType, vec3(3.3f, 0.0f, 70.9f));
//     //     spawn(soldierType, vec3(-6.1f, 0.0f, 62.3f));
//     //     spawn(soldierType, vec3(-31.3f, 0.0f, 10.3f));
//     //     spawn(soldierType, vec3(-23.0f, 0.0f, -3.5f));
//     //     spawn(soldierType, vec3(-18.2f, 0.0f, -11.9f));
//     //     spawn(soldierType, vec3(-17.3f, 0.0f, -25.9f));
//     //     spawn(soldierType, vec3(-15.2f, 0.0f, -41.1f));
//     // }

//     vec3[] spawnSoldiers(int extraCount = 30, float mapRadius = 80.0f)
//     {
//         auto soldierType = EntityType.soldier();
//         vec3[] positions;
//         float minSpacing = 5.0f;

//         // Hand-placed soldiers
//         vec3[] handPlaced = [
//             vec3(21.7f, 0, -7.8f), vec3(35.3f, 0, -13.9f),
//             vec3(41.1f, 0, -26.9f), vec3(20.1f, 0, -32.7f),
//             vec3(12.3f, 0, -30.7f), vec3(3.3f, 0, 70.9f),
//             vec3(-6.1f, 0, 62.3f), vec3(-31.3f, 0, 10.3f),
//             vec3(-23.0f, 0, -3.5f), vec3(-18.2f, 0, -11.9f),
//             vec3(-17.3f, 0, -25.9f), vec3(-15.2f, 0, -41.1f),
//         ];
//         foreach (p; handPlaced)
//         {
//             spawn(soldierType, p);
//             positions ~= p;
//         }
//         writeln("[spawn] ", handPlaced.length, " hand-placed soldiers");

//         // Random soldiers
//         int placed = 0;
//         foreach (i; 0 .. extraCount * 3)  // extra attempts
//         {
//             if (placed >= extraCount) break;

//             float x = uniform(-mapRadius, mapRadius);
//             float z = uniform(-mapRadius, mapRadius);

//             // Don't spawn too close to origin (player start)
//             if (x * x + z * z < 15.0f * 15.0f) continue;

//             // Don't spawn too close to other soldiers
//             bool tooClose = false;
//             foreach (p; positions)
//             {
//                 float dx = x - p.x;
//                 float dz = z - p.z;
//                 if (dx * dx + dz * dz < minSpacing * minSpacing)
//                 {
//                     tooClose = true;
//                     break;
//                 }
//             }
//             if (tooClose) continue;

//             spawn(soldierType, vec3(x, 0.0f, z));
//             positions ~= vec3(x, 0.0f, z);
//             placed++;
//         }
//         writeln("[spawn] ", placed, " random soldiers placed");

//         return positions;
//     }

    

//     vec3[] spawnTrees(int count = 160, float minRadius = 100.0f, float maxRadius = 120.0f)
//     {
//         auto treeType = EntityType.lindenTree();
//         vec3[] positions;
//         float minSpacing = 8.0f;  // minimum distance between trees

//         foreach (i; 0 .. count)
//         {
//             float x, z;
//             bool tooClose;
//             int attempts = 0;
//             do
//             {
//                 x = uniform(-maxRadius, maxRadius);
//                 z = uniform(-maxRadius, maxRadius);
//                 tooClose = false;

//                 // Must be outside inner radius
//                 if ((x * x + z * z) < (minRadius * minRadius))
//                 {
//                     tooClose = true;
//                     continue;
//                 }

//                 // Must be far enough from other trees
//                 foreach (p; positions)
//                 {
//                     float dx = x - p.x;
//                     float dz = z - p.z;
//                     if (dx * dx + dz * dz < minSpacing * minSpacing)
//                     {
//                         tooClose = true;
//                         break;
//                     }
//                 }
//                 attempts++;
//             }
//             while (tooClose && attempts < 50);

//             if (attempts < 50)
//             {
//                 spawn(treeType, vec3(x, 0.0f, z));
//                 positions ~= vec3(x, 0.0f, z);
//             }
//         }
//         writeln("[spawn] ", positions.length, " random trees placed");

//         // Hand-placed trees
//         vec3[] handPlaced = [
//             vec3(37.8f, 0, -33.0f), vec3(29.9f, 0, -36.5f),
//             vec3(1.3f, 0, -3.4f), vec3(-1.3f, 0, 14.9f),
//             vec3(2.2f, 0, 22.7f), vec3(13.0f, 0, 32.4f),
//             vec3(33.4f, 0, 58.3f), vec3(34.4f, 0, 68.0f),
//             vec3(26.4f, 0, 75.0f), vec3(15.5f, 0, 77.8f),
//             vec3(-12.9f, 0, 56.9f), vec3(-21.8f, 0, 48.6f),
//             vec3(-31.0f, 0, 42.5f), vec3(-33.4f, 0, 29.9f),
//             vec3(-32.9f, 0, 19.6f),
//         ];
//         foreach (p; handPlaced)
//         {
//             spawn(treeType, p);
//             positions ~= p;
//         }
//         writeln("[spawn] ", handPlaced.length, " hand-placed trees");

//         return positions;
//     }

//     uint spawnChallengeBox(vec3 pos, vec3 scale, vec3 color, string urdfPath = "cube.urdf")
// {
//     uint eid = mEntityManager.create();

//     if (urdfPath.length > 0)
//     {
//         mPhysicsWorld.addURDF(eid, urdfPath,
//             pos.x, pos.y, pos.z,
//             0, 0, 0, 1);
//         mEntityManager.markPhysics(eid);
//     }

//     GLfloat[] vbo;

//     void addVertex(vec3 p)
//     {
//         vbo ~= cast(GLfloat)p.x;
//         vbo ~= cast(GLfloat)p.y;
//         vbo ~= cast(GLfloat)p.z;
//         vbo ~= cast(GLfloat)color.x;
//         vbo ~= cast(GLfloat)color.y;
//         vbo ~= cast(GLfloat)color.z;
//     }

//     void addQuad(vec3 a, vec3 b, vec3 c, vec3 d)
//     {
//         addVertex(a); addVertex(b); addVertex(c);
//         addVertex(c); addVertex(d); addVertex(a);
//     }

//     // Unit cube centered at origin. The model matrix handles scale and position.
//     addQuad(vec3(-0.5f,-0.5f, 0.5f), vec3( 0.5f,-0.5f, 0.5f), vec3( 0.5f, 0.5f, 0.5f), vec3(-0.5f, 0.5f, 0.5f));
//     addQuad(vec3( 0.5f,-0.5f,-0.5f), vec3(-0.5f,-0.5f,-0.5f), vec3(-0.5f, 0.5f,-0.5f), vec3( 0.5f, 0.5f,-0.5f));
//     addQuad(vec3(-0.5f,-0.5f,-0.5f), vec3(-0.5f,-0.5f, 0.5f), vec3(-0.5f, 0.5f, 0.5f), vec3(-0.5f, 0.5f,-0.5f));
//     addQuad(vec3( 0.5f,-0.5f, 0.5f), vec3( 0.5f,-0.5f,-0.5f), vec3( 0.5f, 0.5f,-0.5f), vec3( 0.5f, 0.5f, 0.5f));
//     addQuad(vec3(-0.5f, 0.5f, 0.5f), vec3( 0.5f, 0.5f, 0.5f), vec3( 0.5f, 0.5f,-0.5f), vec3(-0.5f, 0.5f,-0.5f));
//     addQuad(vec3(-0.5f,-0.5f,-0.5f), vec3( 0.5f,-0.5f,-0.5f), vec3( 0.5f,-0.5f, 0.5f), vec3(-0.5f,-0.5f, 0.5f));

//     IMaterial mat = mMaterials.get("basic");
//     ISurface surface = new SurfaceTriangle(vbo);
//     MeshNode node = new MeshNode("challenge_target_" ~ eid.to!string, surface, mat);
//     node.mModelMatrix = MatrixMakeTranslation(pos) * MatrixMakeScale(scale);
//     mSceneTree.GetRootNode().AddChildSceneNode(node);

//     TransformComponent tc;
//     tc.position = pos;
//     mEntityManager.addTransform(eid, tc);
//     mEntityManager.addRenderable(eid, node);

//     return eid;
// }

//     /// Stress test: spawn N trees in a ring
//     void spawnStressTest(int count)
//     {
//         auto treeType = EntityType.lindenTree();
//         foreach (i; 0 .. count)
//         {
//             float angle = uniform(0.0f, 2.0f * PI);
//             float dist = uniform(150.0f, 400.0f);
//             float x = dist * cos(angle);
//             float z = dist * sin(angle);
//             spawn(treeType, vec3(x, 0.0f, z));
//         }
//         writeln("[stress] spawned ", count, " trees");
//     }
// }

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
        // Prefer looking up by entity type name (e.g. "soldier", "linden").
        // Fall back to texture path, then to "basic".
        if (mMaterials.has(type.name))
            mat = mMaterials.get(type.name);
        else if (type.texturePath !is null && mMaterials.has(type.texturePath))
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

        // writeln("[spawn] ", type.name, " entity=", eid, " at ", adjustedPos);
        return eid;
    }

    // // / Convenience: spawn multiple soldiers at fixed positions
    // void spawnSoldiers()
    // {
    //     // auto soldierType = EntityType.soldier();
    //     // spawn(soldierType, vec3(33.0f, 0.0f, -10.0f));
    //     // spawn(soldierType, vec3(0.0f, 0.0f, -30.0f));
    //     // spawn(soldierType, vec3(0.0f, 0.0f, -40.0f));
    //     // spawn(soldierType, vec3(13.0f, 0.0f, -17.0f));
    //     // spawn(soldierType, vec3(23.0f, 0.0f, -17.0f));
    //     // spawn(soldierType, vec3(13.0f, 0.0f, -37.0f));
    //     // spawn(soldierType, vec3(43.0f, 0.0f, 17.0f));


    //     auto soldierType = EntityType.soldier();
    //     // Arena area
    //     spawn(soldierType, vec3(21.7f, 0.0f, -7.8f));
    //     spawn(soldierType, vec3(35.3f, 0.0f, -13.9f));
    //     spawn(soldierType, vec3(41.1f, 0.0f, -26.9f));
    //     spawn(soldierType, vec3(20.1f, 0.0f, -32.7f));
    //     spawn(soldierType, vec3(12.3f, 0.0f, -30.7f));
    //     // Far side
    //     spawn(soldierType, vec3(3.3f, 0.0f, 70.9f));
    //     spawn(soldierType, vec3(-6.1f, 0.0f, 62.3f));
    //     spawn(soldierType, vec3(-31.3f, 0.0f, 10.3f));
    //     spawn(soldierType, vec3(-23.0f, 0.0f, -3.5f));
    //     spawn(soldierType, vec3(-18.2f, 0.0f, -11.9f));
    //     spawn(soldierType, vec3(-17.3f, 0.0f, -25.9f));
    //     spawn(soldierType, vec3(-15.2f, 0.0f, -41.1f));
    // }

    vec3[] spawnSoldiers(int extraCount = 30, float mapRadius = 80.0f)
    {
        uint[] discard;
        return spawnSoldiers(discard, extraCount, mapRadius);
    }

    /// Overload that also populates `outEntityIds` with the entity id of each
    /// spawned soldier (indices match the returned positions array).
    vec3[] spawnSoldiers(ref uint[] outEntityIds, int extraCount = 30, float mapRadius = 80.0f)
    {
        auto soldierType = EntityType.soldier();
        vec3[] positions;
        outEntityIds.length = 0;
        float minSpacing = 5.0f;

        // Hand-placed soldiers
        vec3[] handPlaced = [
            vec3(21.7f, 0, -7.8f), vec3(35.3f, 0, -13.9f),
            vec3(41.1f, 0, -26.9f), vec3(20.1f, 0, -32.7f),
            vec3(12.3f, 0, -30.7f), vec3(3.3f, 0, 70.9f),
            vec3(-6.1f, 0, 62.3f), vec3(-31.3f, 0, 10.3f),
            vec3(-23.0f, 0, -3.5f), vec3(-18.2f, 0, -11.9f),
            vec3(-17.3f, 0, -25.9f), vec3(-15.2f, 0, -41.1f),
        ];
        foreach (p; handPlaced)
        {
            uint eid = spawn(soldierType, p);
            positions ~= p;
            outEntityIds ~= eid;
        }
        writeln("[spawn] ", handPlaced.length, " hand-placed soldiers");

        // Random soldiers
        int placed = 0;
        foreach (i; 0 .. extraCount * 3)  // extra attempts
        {
            if (placed >= extraCount) break;

            float x = uniform(-mapRadius, mapRadius);
            float z = uniform(-mapRadius, mapRadius);

            // Don't spawn too close to origin (player start)
            if (x * x + z * z < 15.0f * 15.0f) continue;

            // Don't spawn too close to other soldiers
            bool tooClose = false;
            foreach (p; positions)
            {
                float dx = x - p.x;
                float dz = z - p.z;
                if (dx * dx + dz * dz < minSpacing * minSpacing)
                {
                    tooClose = true;
                    break;
                }
            }
            if (tooClose) continue;

            uint eid = spawn(soldierType, vec3(x, 0.0f, z));
            positions ~= vec3(x, 0.0f, z);
            outEntityIds ~= eid;
            placed++;
        }
        writeln("[spawn] ", placed, " random soldiers placed");

        return positions;
    }

    

    vec3[] spawnTrees(int count = 160, float minRadius = 100.0f, float maxRadius = 120.0f)
    {
        auto treeType = EntityType.lindenTree();
        vec3[] positions;
        float minSpacing = 8.0f;  // minimum distance between trees

        foreach (i; 0 .. count)
        {
            float x, z;
            bool tooClose;
            int attempts = 0;
            do
            {
                x = uniform(-maxRadius, maxRadius);
                z = uniform(-maxRadius, maxRadius);
                tooClose = false;

                // Must be outside inner radius
                if ((x * x + z * z) < (minRadius * minRadius))
                {
                    tooClose = true;
                    continue;
                }

                // Must be far enough from other trees
                foreach (p; positions)
                {
                    float dx = x - p.x;
                    float dz = z - p.z;
                    if (dx * dx + dz * dz < minSpacing * minSpacing)
                    {
                        tooClose = true;
                        break;
                    }
                }
                attempts++;
            }
            while (tooClose && attempts < 50);

            if (attempts < 50)
            {
                spawn(treeType, vec3(x, 0.0f, z));
                positions ~= vec3(x, 0.0f, z);
            }
        }
        writeln("[spawn] ", positions.length, " random trees placed");

        // Hand-placed trees
        vec3[] handPlaced = [
            vec3(37.8f, 0, -33.0f), vec3(29.9f, 0, -36.5f),
            vec3(1.3f, 0, -3.4f), vec3(-1.3f, 0, 14.9f),
            vec3(2.2f, 0, 22.7f), vec3(13.0f, 0, 32.4f),
            vec3(33.4f, 0, 58.3f), vec3(34.4f, 0, 68.0f),
            vec3(26.4f, 0, 75.0f), vec3(15.5f, 0, 77.8f),
            vec3(-12.9f, 0, 56.9f), vec3(-21.8f, 0, 48.6f),
            vec3(-31.0f, 0, 42.5f), vec3(-33.4f, 0, 29.9f),
            vec3(-32.9f, 0, 19.6f),
        ];
        foreach (p; handPlaced)
        {
            spawn(treeType, p);
            positions ~= p;
        }
        writeln("[spawn] ", handPlaced.length, " hand-placed trees");

        return positions;
    }

    uint spawnChallengeBox(vec3 pos, vec3 scale, vec3 color, string urdfPath = "cube.urdf")
{
    uint eid = mEntityManager.create();

    if (urdfPath.length > 0)
    {
        mPhysicsWorld.addURDF(eid, urdfPath,
            pos.x, pos.y, pos.z,
            0, 0, 0, 1);
        mEntityManager.markPhysics(eid);
    }

    GLfloat[] vbo;

    void addVertex(vec3 p)
    {
        vbo ~= cast(GLfloat)p.x;
        vbo ~= cast(GLfloat)p.y;
        vbo ~= cast(GLfloat)p.z;
        vbo ~= cast(GLfloat)color.x;
        vbo ~= cast(GLfloat)color.y;
        vbo ~= cast(GLfloat)color.z;
    }

    void addQuad(vec3 a, vec3 b, vec3 c, vec3 d)
    {
        addVertex(a); addVertex(b); addVertex(c);
        addVertex(c); addVertex(d); addVertex(a);
    }

    // Unit cube centered at origin. The model matrix handles scale and position.
    addQuad(vec3(-0.5f,-0.5f, 0.5f), vec3( 0.5f,-0.5f, 0.5f), vec3( 0.5f, 0.5f, 0.5f), vec3(-0.5f, 0.5f, 0.5f));
    addQuad(vec3( 0.5f,-0.5f,-0.5f), vec3(-0.5f,-0.5f,-0.5f), vec3(-0.5f, 0.5f,-0.5f), vec3( 0.5f, 0.5f,-0.5f));
    addQuad(vec3(-0.5f,-0.5f,-0.5f), vec3(-0.5f,-0.5f, 0.5f), vec3(-0.5f, 0.5f, 0.5f), vec3(-0.5f, 0.5f,-0.5f));
    addQuad(vec3( 0.5f,-0.5f, 0.5f), vec3( 0.5f,-0.5f,-0.5f), vec3( 0.5f, 0.5f,-0.5f), vec3( 0.5f, 0.5f, 0.5f));
    addQuad(vec3(-0.5f, 0.5f, 0.5f), vec3( 0.5f, 0.5f, 0.5f), vec3( 0.5f, 0.5f,-0.5f), vec3(-0.5f, 0.5f,-0.5f));
    addQuad(vec3(-0.5f,-0.5f,-0.5f), vec3( 0.5f,-0.5f,-0.5f), vec3( 0.5f,-0.5f, 0.5f), vec3(-0.5f,-0.5f, 0.5f));

    IMaterial mat = mMaterials.get("basic");
    ISurface surface = new SurfaceTriangle(vbo);
    MeshNode node = new MeshNode("challenge_target_" ~ eid.to!string, surface, mat);
    node.mModelMatrix = MatrixMakeTranslation(pos) * MatrixMakeScale(scale);
    mSceneTree.GetRootNode().AddChildSceneNode(node);

    TransformComponent tc;
    tc.position = pos;
    mEntityManager.addTransform(eid, tc);
    mEntityManager.addRenderable(eid, node);

    return eid;
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
