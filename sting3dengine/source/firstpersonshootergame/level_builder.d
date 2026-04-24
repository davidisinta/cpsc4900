// module level_builder;

// import std.stdio;
// import std.conv;
// import std.string : toStringz, fromStringz;

// import enginecore;
// import linear;
// import physics;
// import materials;
// import assimp;
// import geometry;
// import factory;
// import materialregistry;
// import resourcemanager;

// class LevelBuilder
// {
//     Camera mCamera;
//     SceneTree mSceneTree;
//     SpawnFactory mSpawnFactory;
//     MaterialRegistry mMaterials;
//     float mMapKitScaleFactor = 0.015f;
//     vec3[] mTreePositions;
//     vec3[] mSoldierPositions;

//     this(Camera cam, SceneTree tree, EntityManager em, PhysicsWorld physics,
//          MaterialRegistry materials, ResourceManager resources)
//     {
//         mCamera = cam;
//         mSceneTree = tree;
//         mMaterials = materials;
//         mSpawnFactory = new SpawnFactory(cam, em, tree, physics, materials, resources);
//     }

//     SpawnFactory getSpawner()
// {
//     return mSpawnFactory;
// }

//     // void SetupMap()
//     // {
//     //     SetupLightbox();
//     //     SetupTerrain();
//     //     SetupArena();
//     //     mSoldierPositions = mSpawnFactory.spawnSoldiers();
//     //     // mSpawnFactory.spawnTrees();
//     //     mTreePositions = mSpawnFactory.spawnTrees();
//     //     // mSpawnFactory.spawnSoldiers();
//     // }

//     void SetupMap(bool spawnSoldiers = true, bool spawnTrees = true)
// {
//     SetupLightbox();
//     SetupTerrain();
//     SetupArena();

//     mSoldierPositions.length = 0;
//     mTreePositions.length = 0;

//     if (spawnSoldiers)
//         mSoldierPositions = mSpawnFactory.spawnSoldiers();

//     if (spawnTrees)
//         mTreePositions = mSpawnFactory.spawnTrees();
// }

//     void SetupLightbox()
//     {
//         import bindbc.opengl;

//         Pipeline lightPipeline = new Pipeline("light",
//             "./pipelines/light/basic.vert",
//             "./pipelines/light/basic.frag");
//         IMaterial lightMaterial = new BasicMaterial("light");
//         lightMaterial.AddUniform(new Uniform("uModel", "mat4", null));
//         lightMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
//         lightMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));

//         GLfloat[] lightboxVBO = [
//             -0.5f,-0.5f,-0.5f, 1,1,1,  0.5f,-0.5f,-0.5f, 1,1,1,
//              0.5f, 0.5f,-0.5f, 1,1,1,  0.5f, 0.5f,-0.5f, 1,1,1,
//             -0.5f, 0.5f,-0.5f, 1,1,1, -0.5f,-0.5f,-0.5f, 1,1,1,
//             -0.5f,-0.5f, 0.5f, 1,1,1,  0.5f,-0.5f, 0.5f, 1,1,1,
//              0.5f, 0.5f, 0.5f, 1,1,1,  0.5f, 0.5f, 0.5f, 1,1,1,
//             -0.5f, 0.5f, 0.5f, 1,1,1, -0.5f,-0.5f, 0.5f, 1,1,1,
//             -0.5f, 0.5f, 0.5f, 1,1,1, -0.5f, 0.5f,-0.5f, 1,1,1,
//             -0.5f,-0.5f,-0.5f, 1,1,1, -0.5f,-0.5f,-0.5f, 1,1,1,
//             -0.5f,-0.5f, 0.5f, 1,1,1, -0.5f, 0.5f, 0.5f, 1,1,1,
//              0.5f, 0.5f, 0.5f, 1,1,1,  0.5f, 0.5f,-0.5f, 1,1,1,
//              0.5f,-0.5f,-0.5f, 1,1,1,  0.5f,-0.5f,-0.5f, 1,1,1,
//              0.5f,-0.5f, 0.5f, 1,1,1,  0.5f, 0.5f, 0.5f, 1,1,1,
//             -0.5f,-0.5f,-0.5f, 1,1,1,  0.5f,-0.5f,-0.5f, 1,1,1,
//              0.5f,-0.5f, 0.5f, 1,1,1,  0.5f,-0.5f, 0.5f, 1,1,1,
//             -0.5f,-0.5f, 0.5f, 1,1,1, -0.5f,-0.5f,-0.5f, 1,1,1,
//             -0.5f, 0.5f,-0.5f, 1,1,1,  0.5f, 0.5f,-0.5f, 1,1,1,
//              0.5f, 0.5f, 0.5f, 1,1,1,  0.5f, 0.5f, 0.5f, 1,1,1,
//             -0.5f, 0.5f, 0.5f, 1,1,1, -0.5f, 0.5f,-0.5f, 1,1,1
//         ];

//         ISurface lightBox = new SurfaceTriangle(lightboxVBO);
//         MeshNode light = new MeshNode("light", lightBox, lightMaterial);
//         mSceneTree.GetRootNode().AddChildSceneNode(light);
//     }

//     void SetupTerrain()
//     {
//         IMaterial grassMat = mMaterials.get("terrain");
//         ISurface terrain = new SurfaceTerrain(512, 512,
//             "./assets/heightmaps/flat_slight_variation_heightmap.ppm");
//         MeshNode m2 = new MeshNode("terrain", terrain, grassMat);
//         mSceneTree.GetRootNode().AddChildSceneNode(m2);
//     }

//     void SetupArena(){

//     auto presetScene = aiImportFile(
//         "./assets/fps_map_kit/uploads_files_3151797_FPS_Modular_Map_Kit_FBX/Fps_Modular_Map_Presets.fbx".toStringz,
//         aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs);

//     if (presetScene is null) return;

//     IMaterial mapMat = mMaterials.get("map");
//     float sc = mMapKitScaleFactor;

    


//     void addNodeMeshes(const(aiNode)* node, const(aiScene)* scene, mat4 parentTransform)
// {
//     if (node is null) return;

//     // Skip door nodes.
//     // This removes door meshes from the imported FBX hierarchy.
//     auto nodeName = node.mName.data[0 .. node.mName.length];
//     if (nodeName.length > 4)
//     {
//         import std.algorithm : canFind;
//         string nameStr = cast(string)nodeName;

//         if (nameStr.canFind("Door"))
//             return;
//     }

//     for (uint i = 0; i < node.mNumMeshes; i++)
//     {
//         uint meshIdx = node.mMeshes[i];
//         auto mesh = scene.mMeshes[meshIdx];
//         auto surf = new SurfaceAssimp(cast(aiMesh*)mesh);

//         auto mn = new MeshNode("preset_" ~ meshIdx.to!string, surf, mapMat);
//         mn.mModelMatrix = parentTransform;
//         mn.mBoundingRadius = surf.mBoundingRadius * sc;

//         mSceneTree.GetRootNode().AddChildSceneNode(mn);
//     }

//     for (uint i = 0; i < node.mNumChildren; i++)
//     {
//         addNodeMeshes(node.mChildren[i], scene, parentTransform);
//     }
// }

//     mat4 place(float x, float z, float rotY = 0.0f)
//     {
//         if (rotY == 0.0f)
//         {
//             return MatrixMakeTranslation(vec3(x, 0.0f, z))
//                  * MatrixMakeScale(vec3(sc, sc, sc));
//         }

//         return MatrixMakeTranslation(vec3(x, 0.0f, z))
//              * MatrixMakeYRotation(rotY)
//              * MatrixMakeScale(vec3(sc, sc, sc));
//     }

//     // ---------------------------------------------------------------------
//     // SAME OLD LAYOUT — unchanged.
//     // ---------------------------------------------------------------------
//     // This section places the exact same preset pieces as the older working
//     // version. The only thing added here is descriptive comments so it is easier
//     // to remember what each mChildren[index] represents.
//     //
//     // Important preset family reminder:
//     //   mChildren[13] = Metal cabin / blue-gray structure family
//     //   mChildren[16] = Metal cabin with stairs / blue-gray structure family
//     //   mChildren[1]  = Gray concrete building family
//     //   mChildren[18] = Gray exterior wall piece
//     //   mChildren[19] = Gray exterior wall corner
//     //   mChildren[20] = Sandbag preset A
//     //   mChildren[21] = Sandbag preset B
//     //   mChildren[22] = Sandbag preset C
//     //
//     // This layout intentionally keeps the original mixed look:
//     //   - two cabin-style structures in the front/middle,
//     //   - one concrete building deeper in the scene,
//     //   - two wall pieces,
//     //   - three sandbag cover pieces,
//     //   - one corner wall.

//     // ---------------------------------------------------------------------
//     // Cabin 1 / left-center structure.
//     // Preset child 13 is a metal-cabin preset. This is one of the pieces that
//     // can introduce the blue-gray industrial color into the scene.
//     // Position: centered on X, slightly forward/back at Z = -20.
//     // ---------------------------------------------------------------------
//     addNodeMeshes(presetScene.mRootNode.mChildren[13], presetScene,
//         MatrixMakeTranslation(vec3(0.0f, 0.0f, -20.0f)) *
//         MatrixMakeScale(vec3(sc, sc, sc)));


    
//     // Cabin 1 / left-center structure.
//     // Preset child 13 is a metal-cabin preset. This is one of the pieces that
//     // can introduce the blue-gray industrial color into the scene.
//     // Position: centered on X, slightly forward/back at Z = -20.
//     // ---------------------------------------------------------------------
//     addNodeMeshes(presetScene.mRootNode.mChildren[13], presetScene,
//         MatrixMakeTranslation(vec3(30.0f, 0.0f, -20.0f)) *
//         MatrixMakeScale(vec3(sc, sc, sc)));

//     // ---------------------------------------------------------------------
//     // Cabin 2 / right-center structure.
//     // Preset child 16 is another metal-cabin preset, likely the cabin variant
//     // with stairs or extra structural details. It also belongs to the blue-gray
//     // metal family.
//     // Position: shifted right to X = 30, same depth as cabin 1.
//     // ---------------------------------------------------------------------
//     // addNodeMeshes(presetScene.mRootNode.mChildren[16], presetScene,
//     //     MatrixMakeTranslation(vec3(30.0f, 0.0f, -20.0f)) *
//     //     MatrixMakeScale(vec3(sc, sc, sc)));

//     // ---------------------------------------------------------------------
//     // Main concrete building.
//     // Preset child 1 is Building_01 from the gray concrete building family.
//     // This is closer to the stock gray building look than the metal cabins.
//     // Position: centered between the cabins, deeper at Z = -40.
//     // ---------------------------------------------------------------------
//     addNodeMeshes(presetScene.mRootNode.mChildren[1], presetScene,
//         MatrixMakeTranslation(vec3(15.0f, 0.0f, -40.0f)) *
//         MatrixMakeScale(vec3(sc, sc, sc)));

//     // ---------------------------------------------------------------------
//     // Exterior wall piece 1.
//     // Preset child 18 is a gray exterior wall section.
//     // This creates defensive/perimeter structure near the origin.
//     // Position: left/middle side at X = -10, Z = 0.
//     // ---------------------------------------------------------------------
//     addNodeMeshes(presetScene.mRootNode.mChildren[18], presetScene,
//         MatrixMakeTranslation(vec3(-10.0f, 0.0f, 0.0f)) *
//         MatrixMakeScale(vec3(sc, sc, sc)));

//     // ---------------------------------------------------------------------
//     // Exterior wall piece 2.
//     // Same gray exterior wall section as above, reused on the right side.
//     // Position: right/middle side at X = 40, Z = 0.
//     // ---------------------------------------------------------------------
//     addNodeMeshes(presetScene.mRootNode.mChildren[18], presetScene,
//         MatrixMakeTranslation(vec3(40.0f, 0.0f, 0.0f)) *
//         MatrixMakeScale(vec3(sc, sc, sc)));

//     // ---------------------------------------------------------------------
//     // Sandbag cover 1.
//     // Preset child 20 is Sand_Bag_A.
//     // This acts as low cover between the buildings and walls.
//     // Position: near center-left/front at X = 10, Z = -10.
//     // ---------------------------------------------------------------------
//     addNodeMeshes(presetScene.mRootNode.mChildren[20], presetScene,
//         MatrixMakeTranslation(vec3(10.0f, 0.0f, -10.0f)) *
//         MatrixMakeScale(vec3(sc, sc, sc)));

//     // ---------------------------------------------------------------------
//     // Sandbag cover 2.
//     // Preset child 21 is Sand_Bag_B.
//     // This adds another cover object close to the cabins/building area.
//     // Position: slightly right of center at X = 20, Z = -15.
//     // ---------------------------------------------------------------------
//     addNodeMeshes(presetScene.mRootNode.mChildren[21], presetScene,
//         MatrixMakeTranslation(vec3(20.0f, 0.0f, -15.0f)) *
//         MatrixMakeScale(vec3(sc, sc, sc)));

//     // ---------------------------------------------------------------------
//     // Sandbag cover 3.
//     // Preset child 22 is Sand_Bag_C.
//     // This cover is placed deeper toward the main building.
//     // Position: X = 5, Z = -30.
//     // ---------------------------------------------------------------------
//     addNodeMeshes(presetScene.mRootNode.mChildren[22], presetScene,
//         MatrixMakeTranslation(vec3(5.0f, 0.0f, -30.0f)) *
//         MatrixMakeScale(vec3(sc, sc, sc)));

//     // ---------------------------------------------------------------------
//     // Exterior wall corner.
//     // Preset child 19 is the gray exterior wall corner piece.
//     // This helps make the wall layout feel like a compound/perimeter instead of
//     // isolated straight wall segments.
//     // Position: left/deep corner at X = -10, Z = -40.
//     // ---------------------------------------------------------------------
//     addNodeMeshes(presetScene.mRootNode.mChildren[19], presetScene,
//     MatrixMakeTranslation(vec3(-10.0f, 0.0f, -40.0f)) *
//     MatrixMakeScale(vec3(sc, sc, sc)));

//     // ---------------------------------------------------------------------
//     // SAME BOUNDS DEBUG, but fixed to recurse into child nodes.
//     // Your old version checked only node.mNumMeshes on the top-level preset.
//     // Many preset nodes have meshes nested inside children.
//     // ---------------------------------------------------------------------

//     writeln("[collision] Dumping arena piece bounding info:");

//     struct Bounds2D
//     {
//         float minX;
//         float minZ;
//         float maxX;
//         float maxZ;
//         bool valid;
//     }

//     void expandBounds(const(aiNode)* node, const(aiScene)* scene, ref Bounds2D b, vec3 pos)
//     {
//         if (node is null) return;

//         for (uint i = 0; i < node.mNumMeshes; i++)
//         {
//             auto mesh = scene.mMeshes[node.mMeshes[i]];

//             for (uint v = 0; v < mesh.mNumVertices; v++)
//             {
//                 float x = mesh.mVertices[v].x * sc + pos.x;
//                 float z = mesh.mVertices[v].z * sc + pos.z;

//                 if (!b.valid)
//                 {
//                     b.minX = x;
//                     b.maxX = x;
//                     b.minZ = z;
//                     b.maxZ = z;
//                     b.valid = true;
//                 }
//                 else
//                 {
//                     if (x < b.minX) b.minX = x;
//                     if (x > b.maxX) b.maxX = x;
//                     if (z < b.minZ) b.minZ = z;
//                     if (z > b.maxZ) b.maxZ = z;
//                 }
//             }
//         }

//         for (uint i = 0; i < node.mNumChildren; i++)
//         {
//             expandBounds(node.mChildren[i], scene, b, pos);
//         }
//     }

//     struct Piece
//     {
//         string name;
//         int nodeIdx;
//         vec3 pos;
//     }

//     Piece[] pieces = [
//         Piece("cabin1", 13, vec3(0, 0, -20)),
//         Piece("cabin2", 16, vec3(30, 0, -20)),
//         Piece("building", 1, vec3(15, 0, -40)),
//         Piece("wall1", 18, vec3(-10, 0, 0)),
//         Piece("wall2", 18, vec3(40, 0, 0)),
//         Piece("sandbag1", 20, vec3(10, 0, -10)),
//         Piece("sandbag2", 21, vec3(20, 0, -15)),
//         Piece("sandbag3", 22, vec3(5, 0, -30)),
//         Piece("cornerwall", 19, vec3(-10, 0, -40)),
//     ];

//     foreach (p; pieces)
//     {
//         if (p.nodeIdx < 0 || p.nodeIdx >= cast(int)presetScene.mRootNode.mNumChildren)
//         {
//             writeln("  ", p.name, " bad node index: ", p.nodeIdx);
//             continue;
//         }

//         auto node = presetScene.mRootNode.mChildren[p.nodeIdx];
//         auto nodeName = node.mName.data[0 .. node.mName.length];

//         Bounds2D b;
//         b.valid = false;

//         expandBounds(node, presetScene, b, p.pos);

//         if (b.valid)
//         {
//             writeln(
//                 "  ", p.name, " '", nodeName, "' box: ",
//                 "minX=", b.minX,
//                 " minZ=", b.minZ,
//                 " maxX=", b.maxX,
//                 " maxZ=", b.maxZ
//             );
//         }
//         else
//         {
//             writeln("  ", p.name, " '", nodeName, "' has no recursive mesh bounds");
//         }
//     }

//     writeln("[arena] built from presets");

//     aiReleaseImport(presetScene);
// }

// }


module level_builder;

import std.stdio;
import std.conv;
import std.string : toStringz, fromStringz;

import enginecore;
import linear;
import physics;
import materials;
import assimp;
import geometry;
import factory;
import materialregistry;
import resourcemanager;

class LevelBuilder
{
    Camera mCamera;
    SceneTree mSceneTree;
    SpawnFactory mSpawnFactory;
    MaterialRegistry mMaterials;
    float mMapKitScaleFactor = 0.015f;
    vec3[] mTreePositions;
    vec3[] mSoldierPositions;
    uint[] mSoldierEntityIds;   // parallel to mSoldierPositions

    this(Camera cam, SceneTree tree, EntityManager em, PhysicsWorld physics,
         MaterialRegistry materials, ResourceManager resources)
    {
        mCamera = cam;
        mSceneTree = tree;
        mMaterials = materials;
        mSpawnFactory = new SpawnFactory(cam, em, tree, physics, materials, resources);
    }

    SpawnFactory getSpawner()
{
    return mSpawnFactory;
}

    // void SetupMap()
    // {
    //     SetupLightbox();
    //     SetupTerrain();
    //     SetupArena();
    //     mSoldierPositions = mSpawnFactory.spawnSoldiers();
    //     // mSpawnFactory.spawnTrees();
    //     mTreePositions = mSpawnFactory.spawnTrees();
    //     // mSpawnFactory.spawnSoldiers();
    // }

    void SetupMap(bool spawnSoldiers = true, bool spawnTrees = true)
{
    SetupLightbox();
    SetupTerrain();
    SetupArena();

    mSoldierPositions.length = 0;
    mSoldierEntityIds.length = 0;
    mTreePositions.length = 0;

    if (spawnSoldiers)
        mSoldierPositions = mSpawnFactory.spawnSoldiers(mSoldierEntityIds);

    if (spawnTrees)
        mTreePositions = mSpawnFactory.spawnTrees();
}

    void SetupLightbox()
    {
        import bindbc.opengl;

        Pipeline lightPipeline = new Pipeline("light",
            "./pipelines/light/basic.vert",
            "./pipelines/light/basic.frag");
        IMaterial lightMaterial = new BasicMaterial("light");
        lightMaterial.AddUniform(new Uniform("uModel", "mat4", null));
        lightMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
        lightMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));

        GLfloat[] lightboxVBO = [
            -0.5f,-0.5f,-0.5f, 1,1,1,  0.5f,-0.5f,-0.5f, 1,1,1,
             0.5f, 0.5f,-0.5f, 1,1,1,  0.5f, 0.5f,-0.5f, 1,1,1,
            -0.5f, 0.5f,-0.5f, 1,1,1, -0.5f,-0.5f,-0.5f, 1,1,1,
            -0.5f,-0.5f, 0.5f, 1,1,1,  0.5f,-0.5f, 0.5f, 1,1,1,
             0.5f, 0.5f, 0.5f, 1,1,1,  0.5f, 0.5f, 0.5f, 1,1,1,
            -0.5f, 0.5f, 0.5f, 1,1,1, -0.5f,-0.5f, 0.5f, 1,1,1,
            -0.5f, 0.5f, 0.5f, 1,1,1, -0.5f, 0.5f,-0.5f, 1,1,1,
            -0.5f,-0.5f,-0.5f, 1,1,1, -0.5f,-0.5f,-0.5f, 1,1,1,
            -0.5f,-0.5f, 0.5f, 1,1,1, -0.5f, 0.5f, 0.5f, 1,1,1,
             0.5f, 0.5f, 0.5f, 1,1,1,  0.5f, 0.5f,-0.5f, 1,1,1,
             0.5f,-0.5f,-0.5f, 1,1,1,  0.5f,-0.5f,-0.5f, 1,1,1,
             0.5f,-0.5f, 0.5f, 1,1,1,  0.5f, 0.5f, 0.5f, 1,1,1,
            -0.5f,-0.5f,-0.5f, 1,1,1,  0.5f,-0.5f,-0.5f, 1,1,1,
             0.5f,-0.5f, 0.5f, 1,1,1,  0.5f,-0.5f, 0.5f, 1,1,1,
            -0.5f,-0.5f, 0.5f, 1,1,1, -0.5f,-0.5f,-0.5f, 1,1,1,
            -0.5f, 0.5f,-0.5f, 1,1,1,  0.5f, 0.5f,-0.5f, 1,1,1,
             0.5f, 0.5f, 0.5f, 1,1,1,  0.5f, 0.5f, 0.5f, 1,1,1,
            -0.5f, 0.5f, 0.5f, 1,1,1, -0.5f, 0.5f,-0.5f, 1,1,1
        ];

        ISurface lightBox = new SurfaceTriangle(lightboxVBO);
        MeshNode light = new MeshNode("light", lightBox, lightMaterial);
        mSceneTree.GetRootNode().AddChildSceneNode(light);
    }

    void SetupTerrain()
    {
        IMaterial grassMat = mMaterials.get("terrain");
        ISurface terrain = new SurfaceTerrain(512, 512,
            "./assets/heightmaps/flat_slight_variation_heightmap.ppm");
        MeshNode m2 = new MeshNode("terrain", terrain, grassMat);
        mSceneTree.GetRootNode().AddChildSceneNode(m2);
    }

    void SetupArena(){

    auto presetScene = aiImportFile(
        "./assets/fps_map_kit/uploads_files_3151797_FPS_Modular_Map_Kit_FBX/Fps_Modular_Map_Presets.fbx".toStringz,
        aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs);

    if (presetScene is null) return;

    IMaterial mapMat = mMaterials.get("map");
    float sc = mMapKitScaleFactor;

    


    void addNodeMeshes(const(aiNode)* node, const(aiScene)* scene, mat4 parentTransform)
{
    if (node is null) return;

    // Skip door nodes.
    // This removes door meshes from the imported FBX hierarchy.
    auto nodeName = node.mName.data[0 .. node.mName.length];
    if (nodeName.length > 4)
    {
        import std.algorithm : canFind;
        string nameStr = cast(string)nodeName;

        if (nameStr.canFind("Door"))
            return;
    }

    for (uint i = 0; i < node.mNumMeshes; i++)
    {
        uint meshIdx = node.mMeshes[i];
        auto mesh = scene.mMeshes[meshIdx];
        auto surf = new SurfaceAssimp(cast(aiMesh*)mesh);

        auto mn = new MeshNode("preset_" ~ meshIdx.to!string, surf, mapMat);
        mn.mModelMatrix = parentTransform;
        mn.mBoundingRadius = surf.mBoundingRadius * sc;

        mSceneTree.GetRootNode().AddChildSceneNode(mn);
    }

    for (uint i = 0; i < node.mNumChildren; i++)
    {
        addNodeMeshes(node.mChildren[i], scene, parentTransform);
    }
}

    mat4 place(float x, float z, float rotY = 0.0f)
    {
        if (rotY == 0.0f)
        {
            return MatrixMakeTranslation(vec3(x, 0.0f, z))
                 * MatrixMakeScale(vec3(sc, sc, sc));
        }

        return MatrixMakeTranslation(vec3(x, 0.0f, z))
             * MatrixMakeYRotation(rotY)
             * MatrixMakeScale(vec3(sc, sc, sc));
    }

    // ---------------------------------------------------------------------
    // SAME OLD LAYOUT — unchanged.
    // ---------------------------------------------------------------------
    // This section places the exact same preset pieces as the older working
    // version. The only thing added here is descriptive comments so it is easier
    // to remember what each mChildren[index] represents.
    //
    // Important preset family reminder:
    //   mChildren[13] = Metal cabin / blue-gray structure family
    //   mChildren[16] = Metal cabin with stairs / blue-gray structure family
    //   mChildren[1]  = Gray concrete building family
    //   mChildren[18] = Gray exterior wall piece
    //   mChildren[19] = Gray exterior wall corner
    //   mChildren[20] = Sandbag preset A
    //   mChildren[21] = Sandbag preset B
    //   mChildren[22] = Sandbag preset C
    //
    // This layout intentionally keeps the original mixed look:
    //   - two cabin-style structures in the front/middle,
    //   - one concrete building deeper in the scene,
    //   - two wall pieces,
    //   - three sandbag cover pieces,
    //   - one corner wall.

    // ---------------------------------------------------------------------
    // Cabin 1 / left-center structure.
    // Preset child 13 is a metal-cabin preset. This is one of the pieces that
    // can introduce the blue-gray industrial color into the scene.
    // Position: centered on X, slightly forward/back at Z = -20.
    // ---------------------------------------------------------------------
    addNodeMeshes(presetScene.mRootNode.mChildren[13], presetScene,
        MatrixMakeTranslation(vec3(0.0f, 0.0f, -20.0f)) *
        MatrixMakeScale(vec3(sc, sc, sc)));


    
    // Cabin 1 / left-center structure.
    // Preset child 13 is a metal-cabin preset. This is one of the pieces that
    // can introduce the blue-gray industrial color into the scene.
    // Position: centered on X, slightly forward/back at Z = -20.
    // ---------------------------------------------------------------------
    addNodeMeshes(presetScene.mRootNode.mChildren[13], presetScene,
        MatrixMakeTranslation(vec3(30.0f, 0.0f, -20.0f)) *
        MatrixMakeScale(vec3(sc, sc, sc)));

    // ---------------------------------------------------------------------
    // Cabin 2 / right-center structure.
    // Preset child 16 is another metal-cabin preset, likely the cabin variant
    // with stairs or extra structural details. It also belongs to the blue-gray
    // metal family.
    // Position: shifted right to X = 30, same depth as cabin 1.
    // ---------------------------------------------------------------------
    // addNodeMeshes(presetScene.mRootNode.mChildren[16], presetScene,
    //     MatrixMakeTranslation(vec3(30.0f, 0.0f, -20.0f)) *
    //     MatrixMakeScale(vec3(sc, sc, sc)));

    // ---------------------------------------------------------------------
    // Main concrete building.
    // Preset child 1 is Building_01 from the gray concrete building family.
    // This is closer to the stock gray building look than the metal cabins.
    // Position: centered between the cabins, deeper at Z = -40.
    // ---------------------------------------------------------------------
    addNodeMeshes(presetScene.mRootNode.mChildren[1], presetScene,
        MatrixMakeTranslation(vec3(15.0f, 0.0f, -40.0f)) *
        MatrixMakeScale(vec3(sc, sc, sc)));

    // ---------------------------------------------------------------------
    // Exterior wall piece 1.
    // Preset child 18 is a gray exterior wall section.
    // This creates defensive/perimeter structure near the origin.
    // Position: left/middle side at X = -10, Z = 0.
    // ---------------------------------------------------------------------
    addNodeMeshes(presetScene.mRootNode.mChildren[18], presetScene,
        MatrixMakeTranslation(vec3(-10.0f, 0.0f, 0.0f)) *
        MatrixMakeScale(vec3(sc, sc, sc)));

    // ---------------------------------------------------------------------
    // Exterior wall piece 2.
    // Same gray exterior wall section as above, reused on the right side.
    // Position: right/middle side at X = 40, Z = 0.
    // ---------------------------------------------------------------------
    addNodeMeshes(presetScene.mRootNode.mChildren[18], presetScene,
        MatrixMakeTranslation(vec3(40.0f, 0.0f, 0.0f)) *
        MatrixMakeScale(vec3(sc, sc, sc)));

    // ---------------------------------------------------------------------
    // Sandbag cover 1.
    // Preset child 20 is Sand_Bag_A.
    // This acts as low cover between the buildings and walls.
    // Position: near center-left/front at X = 10, Z = -10.
    // ---------------------------------------------------------------------
    addNodeMeshes(presetScene.mRootNode.mChildren[20], presetScene,
        MatrixMakeTranslation(vec3(10.0f, 0.0f, -10.0f)) *
        MatrixMakeScale(vec3(sc, sc, sc)));

    // ---------------------------------------------------------------------
    // Sandbag cover 2.
    // Preset child 21 is Sand_Bag_B.
    // This adds another cover object close to the cabins/building area.
    // Position: slightly right of center at X = 20, Z = -15.
    // ---------------------------------------------------------------------
    addNodeMeshes(presetScene.mRootNode.mChildren[21], presetScene,
        MatrixMakeTranslation(vec3(20.0f, 0.0f, -15.0f)) *
        MatrixMakeScale(vec3(sc, sc, sc)));

    // ---------------------------------------------------------------------
    // Sandbag cover 3.
    // Preset child 22 is Sand_Bag_C.
    // This cover is placed deeper toward the main building.
    // Position: X = 5, Z = -30.
    // ---------------------------------------------------------------------
    addNodeMeshes(presetScene.mRootNode.mChildren[22], presetScene,
        MatrixMakeTranslation(vec3(5.0f, 0.0f, -30.0f)) *
        MatrixMakeScale(vec3(sc, sc, sc)));

    // ---------------------------------------------------------------------
    // Exterior wall corner.
    // Preset child 19 is the gray exterior wall corner piece.
    // This helps make the wall layout feel like a compound/perimeter instead of
    // isolated straight wall segments.
    // Position: left/deep corner at X = -10, Z = -40.
    // ---------------------------------------------------------------------
    addNodeMeshes(presetScene.mRootNode.mChildren[19], presetScene,
    MatrixMakeTranslation(vec3(-10.0f, 0.0f, -40.0f)) *
    MatrixMakeScale(vec3(sc, sc, sc)));

    // ---------------------------------------------------------------------
    // SAME BOUNDS DEBUG, but fixed to recurse into child nodes.
    // Your old version checked only node.mNumMeshes on the top-level preset.
    // Many preset nodes have meshes nested inside children.
    // ---------------------------------------------------------------------

    writeln("[collision] Dumping arena piece bounding info:");

    struct Bounds2D
    {
        float minX;
        float minZ;
        float maxX;
        float maxZ;
        bool valid;
    }

    void expandBounds(const(aiNode)* node, const(aiScene)* scene, ref Bounds2D b, vec3 pos)
    {
        if (node is null) return;

        for (uint i = 0; i < node.mNumMeshes; i++)
        {
            auto mesh = scene.mMeshes[node.mMeshes[i]];

            for (uint v = 0; v < mesh.mNumVertices; v++)
            {
                float x = mesh.mVertices[v].x * sc + pos.x;
                float z = mesh.mVertices[v].z * sc + pos.z;

                if (!b.valid)
                {
                    b.minX = x;
                    b.maxX = x;
                    b.minZ = z;
                    b.maxZ = z;
                    b.valid = true;
                }
                else
                {
                    if (x < b.minX) b.minX = x;
                    if (x > b.maxX) b.maxX = x;
                    if (z < b.minZ) b.minZ = z;
                    if (z > b.maxZ) b.maxZ = z;
                }
            }
        }

        for (uint i = 0; i < node.mNumChildren; i++)
        {
            expandBounds(node.mChildren[i], scene, b, pos);
        }
    }

    struct Piece
    {
        string name;
        int nodeIdx;
        vec3 pos;
    }

    Piece[] pieces = [
        Piece("cabin1", 13, vec3(0, 0, -20)),
        Piece("cabin2", 16, vec3(30, 0, -20)),
        Piece("building", 1, vec3(15, 0, -40)),
        Piece("wall1", 18, vec3(-10, 0, 0)),
        Piece("wall2", 18, vec3(40, 0, 0)),
        Piece("sandbag1", 20, vec3(10, 0, -10)),
        Piece("sandbag2", 21, vec3(20, 0, -15)),
        Piece("sandbag3", 22, vec3(5, 0, -30)),
        Piece("cornerwall", 19, vec3(-10, 0, -40)),
    ];

    foreach (p; pieces)
    {
        if (p.nodeIdx < 0 || p.nodeIdx >= cast(int)presetScene.mRootNode.mNumChildren)
        {
            writeln("  ", p.name, " bad node index: ", p.nodeIdx);
            continue;
        }

        auto node = presetScene.mRootNode.mChildren[p.nodeIdx];
        auto nodeName = node.mName.data[0 .. node.mName.length];

        Bounds2D b;
        b.valid = false;

        expandBounds(node, presetScene, b, p.pos);

        if (b.valid)
        {
            writeln(
                "  ", p.name, " '", nodeName, "' box: ",
                "minX=", b.minX,
                " minZ=", b.minZ,
                " maxX=", b.maxX,
                " maxZ=", b.maxZ
            );
        }
        else
        {
            writeln("  ", p.name, " '", nodeName, "' has no recursive mesh bounds");
        }
    }

    writeln("[arena] built from presets");

    aiReleaseImport(presetScene);
}

}