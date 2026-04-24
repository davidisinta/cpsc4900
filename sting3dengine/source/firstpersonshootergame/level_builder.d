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

    this(Camera cam, SceneTree tree, EntityManager em, PhysicsWorld physics,
         MaterialRegistry materials, ResourceManager resources)
    {
        mCamera = cam;
        mSceneTree = tree;
        mMaterials = materials;
        mSpawnFactory = new SpawnFactory(cam, em, tree, physics, materials, resources);
    }

    void SetupMap()
    {
        SetupLightbox();
        SetupTerrain();
        SetupArena();
        mSoldierPositions = mSpawnFactory.spawnSoldiers();
        // mSpawnFactory.spawnTrees();
        mTreePositions = mSpawnFactory.spawnTrees();
        // mSpawnFactory.spawnSoldiers();
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

    // void SetupArena()
    // {
    //     auto presetScene = aiImportFile(
    //         "./assets/fps_map_kit/uploads_files_3151797_FPS_Modular_Map_Kit_FBX/Fps_Modular_Map_Presets.fbx".toStringz,
    //         aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs);

    //     if (presetScene is null) return;

    //     IMaterial mapMat = mMaterials.get("map");
    //     float sc = mMapKitScaleFactor;

    //     void addMeshPiece(const(aiNode)* node, const(aiScene)* scene, mat4 parentTransform)
    //     {
    //         for (uint i = 0; i < node.mNumMeshes; i++)
    //         {
    //             uint meshIdx = node.mMeshes[i];
    //             auto mesh = scene.mMeshes[meshIdx];
    //             auto surf = new SurfaceAssimp(cast(aiMesh*)mesh);
    //             auto mn = new MeshNode("preset_" ~ meshIdx.to!string, surf, mapMat);
    //             mn.mModelMatrix = parentTransform;
    //             mn.mBoundingRadius = surf.mBoundingRadius * sc;
    //             mSceneTree.GetRootNode().AddChildSceneNode(mn);
    //         }
    //         for (uint i = 0; i < node.mNumChildren; i++)
    //             addMeshPiece(node.mChildren[i], scene, parentTransform);
    //     }

    //     addNodeMeshes(presetScene.mRootNode.mChildren[13], presetScene,
    //         MatrixMakeTranslation(vec3(0.0f, 0.0f, -20.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));
    //     addNodeMeshes(presetScene.mRootNode.mChildren[16], presetScene,
    //         MatrixMakeTranslation(vec3(30.0f, 0.0f, -20.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));
    //     addNodeMeshes(presetScene.mRootNode.mChildren[1], presetScene,
    //         MatrixMakeTranslation(vec3(15.0f, 0.0f, -40.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));
    //     addNodeMeshes(presetScene.mRootNode.mChildren[18], presetScene,
    //         MatrixMakeTranslation(vec3(-10.0f, 0.0f, 0.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));
    //     addNodeMeshes(presetScene.mRootNode.mChildren[18], presetScene,
    //         MatrixMakeTranslation(vec3(40.0f, 0.0f, 0.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));
    //     addNodeMeshes(presetScene.mRootNode.mChildren[20], presetScene,
    //         MatrixMakeTranslation(vec3(10.0f, 0.0f, -10.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));
    //     addNodeMeshes(presetScene.mRootNode.mChildren[21], presetScene,
    //         MatrixMakeTranslation(vec3(20.0f, 0.0f, -15.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));
    //     addNodeMeshes(presetScene.mRootNode.mChildren[22], presetScene,
    //         MatrixMakeTranslation(vec3(5.0f, 0.0f, -30.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));
    //     addNodeMeshes(presetScene.mRootNode.mChildren[19], presetScene,
    //         MatrixMakeTranslation(vec3(-10.0f, 0.0f, -40.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));


    //     // Print bounding info for collision boxes
    //     writeln("[collision] Dumping arena piece bounding info:");
    //     struct Piece { string name; int nodeIdx; vec3 pos; }
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
    //         auto node = presetScene.mRootNode.mChildren[p.nodeIdx];
    //         auto nodeName = node.mName.data[0 .. node.mName.length];
    //         // Get bounding from first mesh
    //         if (node.mNumMeshes > 0)
    //         {
    //             auto mesh = presetScene.mMeshes[node.mMeshes[0]];
    //             float minX = float.max, minZ = float.max;
    //             float maxX = -float.max, maxZ = -float.max;
    //             for (uint v = 0; v < mesh.mNumVertices; v++)
    //             {
    //                 float x = mesh.mVertices[v].x * sc + p.pos.x;
    //                 float z = mesh.mVertices[v].z * sc + p.pos.z;
    //                 if (x < minX) minX = x;
    //                 if (x > maxX) maxX = x;
    //                 if (z < minZ) minZ = z;
    //                 if (z > maxZ) maxZ = z;
    //             }
    //             writeln("  ", p.name, " '", nodeName, "' box: minX=", minX, " minZ=", minZ, " maxX=", maxX, " maxZ=", maxZ);
    //         }
    //     }

    //     writeln("[arena] built from presets");
    //     aiReleaseImport(presetScene);
    // }


    void SetupArena()
    {
        auto presetScene = aiImportFile(
            "./assets/fps_map_kit/uploads_files_3151797_FPS_Modular_Map_Kit_FBX/Fps_Modular_Map_Presets.fbx".toStringz,
            aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs);
        if (presetScene is null) return;
        IMaterial mapMat = mMaterials.get("map");
        float sc = mMapKitScaleFactor;

        // void addNodeMeshes(const(aiNode)* node, const(aiScene)* scene, mat4 parentTransform)
        // {
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
        //         addNodeMeshes(node.mChildren[i], scene, parentTransform);
        // }


        void addNodeMeshes(const(aiNode)* node, const(aiScene)* scene, mat4 parentTransform)
        {
            // Skip door nodes
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
                addNodeMeshes(node.mChildren[i], scene, parentTransform);
        }

        mat4 place(float x, float z, float rotY = 0)
        {
            if (rotY == 0)
                return MatrixMakeTranslation(vec3(x, 0, z)) * MatrixMakeScale(vec3(sc, sc, sc));
            else
                return MatrixMakeTranslation(vec3(x, 0, z)) * MatrixMakeYRotation(rotY) * MatrixMakeScale(vec3(sc, sc, sc));
        }

        // === VILLAGE CENTER — main street with buildings on both sides ===

        // Town square — Building_04 (large, 3 doors) as town hall
        addNodeMeshes(presetScene.mRootNode.mChildren[4], presetScene,
            place(0, -40));

        // Left side of main street
        addNodeMeshes(presetScene.mRootNode.mChildren[1], presetScene,  // Building_01
            place(-20, -15));
        addNodeMeshes(presetScene.mRootNode.mChildren[6], presetScene,  // Building_06
            place(-22, 10, 1.5708f));  // rotated 90°

        // Right side of main street
        addNodeMeshes(presetScene.mRootNode.mChildren[2], presetScene,  // Building_02
            place(20, -10));
        addNodeMeshes(presetScene.mRootNode.mChildren[5], presetScene,  // Building_05 shed
            place(25, 15));

        // === RESIDENTIAL AREA — cabins scattered north ===

        // Cabin cluster
        addNodeMeshes(presetScene.mRootNode.mChildren[13], presetScene,  // Cabin_A_Model_A
            place(-15, 40));
        addNodeMeshes(presetScene.mRootNode.mChildren[16], presetScene,  // Cabin_B_Model_A (stairs)
            place(15, 45, 3.14159f));  // facing south
        addNodeMeshes(presetScene.mRootNode.mChildren[14], presetScene,  // Cabin_A_Model_B
            place(35, 35, -1.5708f));

        // === OUTSKIRTS — walls and defensive positions ===

        // South wall with gap
        addNodeMeshes(presetScene.mRootNode.mChildren[18], presetScene,  // Exterior Wall
            place(-30, -55));
        addNodeMeshes(presetScene.mRootNode.mChildren[18], presetScene,  // Exterior Wall
            place(10, -55));
        addNodeMeshes(presetScene.mRootNode.mChildren[19], presetScene,  // Corner Wall
            place(-35, -55));

        // === COVER POSITIONS — sandbags at key intersections ===

        // Street cover
        addNodeMeshes(presetScene.mRootNode.mChildren[20], presetScene,  // Sand_Bag_A
            place(0, -20));
        addNodeMeshes(presetScene.mRootNode.mChildren[21], presetScene,  // Sand_Bag_B
            place(-8, 0, 1.5708f));
        addNodeMeshes(presetScene.mRootNode.mChildren[22], presetScene,  // Sand_Bag_C
            place(10, 25));

        // Metal wall as cover near shed
        addNodeMeshes(presetScene.mRootNode.mChildren[8], presetScene,  // Metal_Wall_Plain
            place(35, 10, 1.5708f));











        // Load props
        auto meshScene = aiImportFile(
            "./assets/fps_map_kit/uploads_files_3151797_FPS_Modular_Map_Kit_FBX/FPS_Modular_Map_Meshes.fbx".toStringz,
            aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs);

        if (meshScene !is null)
        {
            // Barrels near buildings
            addNodeMeshes(meshScene.mRootNode.mChildren[11], meshScene, place(18, -8));    // plastic barrel
            addNodeMeshes(meshScene.mRootNode.mChildren[12], meshScene, place(19, -8));    // metal barrel
            addNodeMeshes(meshScene.mRootNode.mChildren[11], meshScene, place(-18, 12));   // plastic barrel
            addNodeMeshes(meshScene.mRootNode.mChildren[12], meshScene, place(-19, 12));   // metal barrel

            // Concrete barriers as road blocks
            addNodeMeshes(meshScene.mRootNode.mChildren[7], meshScene, place(0, 0));       // barrier center
            addNodeMeshes(meshScene.mRootNode.mChildren[7], meshScene, place(5, 5, 0.5f)); // barrier angled

            // Wooden pallets
            addNodeMeshes(meshScene.mRootNode.mChildren[14], meshScene, place(22, -18));
            addNodeMeshes(meshScene.mRootNode.mChildren[14], meshScene, place(-14, 38));

            // Targets for practice
            addNodeMeshes(meshScene.mRootNode.mChildren[15], meshScene, place(0, -35));
            addNodeMeshes(meshScene.mRootNode.mChildren[15], meshScene, place(30, -35));

            // Metal barriers
            addNodeMeshes(meshScene.mRootNode.mChildren[9], meshScene, place(-5, 25, 1.5708f));
            addNodeMeshes(meshScene.mRootNode.mChildren[9], meshScene, place(10, 30));

            // Fence sections
            addNodeMeshes(meshScene.mRootNode.mChildren[8], meshScene, place(-25, -10));
            addNodeMeshes(meshScene.mRootNode.mChildren[8], meshScene, place(-25, -5));

            writeln("[arena] props placed: 14 pieces");
            aiReleaseImport(meshScene);
        }

        writeln("[arena] village built: 15 pieces");
        aiReleaseImport(presetScene);
    }






    



    // // ============================================================
    // // FULL ARENA SETUP — Military Training Compound
    // // 7 buildings from raw meshes + presets, targets, props
    // // ============================================================
    // void SetupArena()
    // {
    //     // Load preset buildings
    //     auto presetScene = aiImportFile(
    //         "./assets/fps_map_kit/uploads_files_3151797_FPS_Modular_Map_Kit_FBX/Fps_Modular_Map_Presets.fbx".toStringz,
    //         aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs);

    //     // Load raw mesh pieces
    //     auto meshScene = aiImportFile(
    //         "./assets/fps_map_kit/uploads_files_3151797_FPS_Modular_Map_Kit_FBX/FPS_Modular_Map_Meshes.fbx".toStringz,
    //         aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs);

    //     if (presetScene is null || meshScene is null)
    //     {
    //         writeln("[arena] ERROR: failed to load FBX files");
    //         return;
    //     }

    //     // IMaterial mapMat = mMaterials.get("map");



    //     IMaterial mapMat = mMaterials.get("map");
    //     IMaterial meshesMat = mMaterials.get("meshes");
    //     float sc = mMapKitScaleFactor;

    //     // Helper: place a node at position with optional Y rotation
    //     void addMeshPiece(const(aiNode)* node, const(aiScene)* scene, mat4 parentTransform)
    //     {
    //         auto nodeName = node.mName.data[0 .. node.mName.length];
    //         string nameStr = cast(string)nodeName;
    //         import std.algorithm : canFind;
    //         if (nameStr.canFind("Door"))
    //             return;

    //         for (uint i = 0; i < node.mNumMeshes; i++)
    //         {
    //             uint meshIdx = node.mMeshes[i];
    //             auto mesh = scene.mMeshes[meshIdx];
    //             auto surf = new SurfaceAssimp(cast(aiMesh*)mesh);
    //             auto mn = new MeshNode("preset_" ~ meshIdx.to!string, surf, mapMat);
    //             mn.mModelMatrix = parentTransform;
    //             mn.mBoundingRadius = surf.mBoundingRadius * sc;
    //             mSceneTree.GetRootNode().AddChildSceneNode(mn);
    //         }
    //         for (uint i = 0; i < node.mNumChildren; i++)
    //             addMeshPiece(node.mChildren[i], scene, parentTransform);
    //     }

    //     mat4 place(float x, float z, float rotY = 0)
    //     {
    //         if (rotY == 0)
    //             return MatrixMakeTranslation(vec3(x, 0, z)) * MatrixMakeScale(vec3(sc, sc, sc));
    //         else
    //             return MatrixMakeTranslation(vec3(x, 0, z)) * MatrixMakeYRotation(rotY) * MatrixMakeScale(vec3(sc, sc, sc));
    //     }

    //     // ============================================================
    //     // BUILDING 1: HQ — Large building at south center (Preset Building_04)
    //     // The main command building, 3 doors, central position
    //     // ============================================================
    //     addMeshPiece(presetScene.mRootNode.mChildren[4], presetScene,
    //         place(0, -20));

    //     // ============================================================
    //     // BUILDING 2: Barracks West — Cabin with windows (Preset Cabin_A_Model_A)
    //     // Sleeping quarters, northwest
    //     // ============================================================
    //     addMeshPiece(presetScene.mRootNode.mChildren[13], presetScene,
    //         place(-30, 60));

    //     // ============================================================
    //     // BUILDING 3: Watchtower — Cabin with stairs (Preset Cabin_B_Model_A)
    //     // Elevated position, north center
    //     // ============================================================
    //     addMeshPiece(presetScene.mRootNode.mChildren[16], presetScene,
    //         place(0, 65));

    //     // ============================================================
    //     // BUILDING 4: Armory — Cabin variant (Preset Cabin_A_Model_B)
    //     // Weapons storage, northeast
    //     // ============================================================
    //     addMeshPiece(presetScene.mRootNode.mChildren[14], presetScene,
    //         place(30, 60, 3.14159f));

    //     // ============================================================
    //     // BUILDING 5: Garage — Open shed (Preset Building_05)
    //     // Vehicle storage, west side
    //     // ============================================================
    //     addMeshPiece(presetScene.mRootNode.mChildren[5], presetScene,
    //         place(-25, 25));

    //     // ============================================================
    //     // BUILDING 6: Storage Shed — Small building (Preset Building_01)
    //     // Supply storage, east side
    //     // ============================================================
    //     addMeshPiece(presetScene.mRootNode.mChildren[1], presetScene,
    //         place(25, 20, -1.5708f));

    //     // ============================================================
    //     // BUILDING 7: Guard Post — Building_02
    //     // Checkpoint near south gate
    //     // ============================================================
    //     addMeshPiece(presetScene.mRootNode.mChildren[2], presetScene,
    //         place(20, -35, 1.5708f));

    //     // ============================================================
    //     // PERIMETER — South wall with gate gap
    //     // ============================================================
    //     addMeshPiece(presetScene.mRootNode.mChildren[18], presetScene,  // Exterior Wall
    //         place(-30, -45));
    //     addMeshPiece(presetScene.mRootNode.mChildren[18], presetScene,  // Exterior Wall
    //         place(-15, -45));
    //     // Gate gap here (no wall from -5 to 5)
    //     addMeshPiece(presetScene.mRootNode.mChildren[18], presetScene,  // Exterior Wall
    //         place(15, -45));
    //     addMeshPiece(presetScene.mRootNode.mChildren[18], presetScene,  // Exterior Wall
    //         place(30, -45));

    //     // Corner walls at south wall ends
    //     addMeshPiece(presetScene.mRootNode.mChildren[19], presetScene,
    //         place(-40, -45));
    //     addMeshPiece(presetScene.mRootNode.mChildren[19], presetScene,
    //         place(40, -45, 1.5708f));

    //     // East perimeter walls
    //     addMeshPiece(presetScene.mRootNode.mChildren[18], presetScene,
    //         place(45, -30, 1.5708f));
    //     addMeshPiece(presetScene.mRootNode.mChildren[18], presetScene,
    //         place(45, -15, 1.5708f));
    //     addMeshPiece(presetScene.mRootNode.mChildren[18], presetScene,
    //         place(45, 0, 1.5708f));

    //     // West perimeter walls
    //     addMeshPiece(presetScene.mRootNode.mChildren[18], presetScene,
    //         place(-40, -30, 1.5708f));
    //     addMeshPiece(presetScene.mRootNode.mChildren[18], presetScene,
    //         place(-40, -15, 1.5708f));
    //     addMeshPiece(presetScene.mRootNode.mChildren[18], presetScene,
    //         place(-40, 0, 1.5708f));

    //     // ============================================================
    //     // SANDBAG COVER — Strategic positions
    //     // ============================================================
    //     // Near HQ entrance
    //     addMeshPiece(presetScene.mRootNode.mChildren[21], presetScene,  // Sand_Bag_B
    //         place(-8, -10));
    //     addMeshPiece(presetScene.mRootNode.mChildren[21], presetScene,
    //         place(8, -10));

    //     // Mid-field cover
    //     addMeshPiece(presetScene.mRootNode.mChildren[22], presetScene,  // Sand_Bag_C
    //         place(-15, 10, 0.7854f));
    //     addMeshPiece(presetScene.mRootNode.mChildren[20], presetScene,  // Sand_Bag_A
    //         place(15, 15));
    //     addMeshPiece(presetScene.mRootNode.mChildren[22], presetScene,
    //         place(0, 35, -0.7854f));

    //     // Near barracks
    //     addMeshPiece(presetScene.mRootNode.mChildren[20], presetScene,
    //         place(-20, 50));
    //     addMeshPiece(presetScene.mRootNode.mChildren[20], presetScene,
    //         place(20, 50));

    //     // ============================================================
    //     // TARGET RANGE — Center north area
    //     // ============================================================
    //     // Row of targets at various distances
    //     addMeshPiece(meshScene.mRootNode.mChildren[15], meshScene,  // Target
    //         place(-10, 10));
    //     addMeshPiece(meshScene.mRootNode.mChildren[15], meshScene,
    //         place(-5, 10));
    //     addMeshPiece(meshScene.mRootNode.mChildren[15], meshScene,
    //         place(0, 10));
    //     addMeshPiece(meshScene.mRootNode.mChildren[15], meshScene,
    //         place(5, 10));
    //     addMeshPiece(meshScene.mRootNode.mChildren[15], meshScene,
    //         place(10, 10));

    //     // Far targets
    //     addMeshPiece(meshScene.mRootNode.mChildren[15], meshScene,
    //         place(-8, 30));
    //     addMeshPiece(meshScene.mRootNode.mChildren[15], meshScene,
    //         place(0, 30));
    //     addMeshPiece(meshScene.mRootNode.mChildren[15], meshScene,
    //         place(8, 30));

    //     // ============================================================
    //     // PROPS — Barrels, barriers, pallets, fences
    //     // ============================================================

    //     // Barrels near garage
    //     addMeshPiece(meshScene.mRootNode.mChildren[11], meshScene, place(-22, 22));     // plastic
    //     addMeshPiece(meshScene.mRootNode.mChildren[12], meshScene, place(-23, 22));     // metal
    //     addMeshPiece(meshScene.mRootNode.mChildren[11], meshScene, place(-22, 28));     // plastic
    //     addMeshPiece(meshScene.mRootNode.mChildren[12], meshScene, place(-24, 28));     // metal
    //     addMeshPiece(meshScene.mRootNode.mChildren[11], meshScene, place(-23, 25));     // plastic

    //     // Barrels near armory
    //     addMeshPiece(meshScene.mRootNode.mChildren[12], meshScene, place(28, 55));
    //     addMeshPiece(meshScene.mRootNode.mChildren[12], meshScene, place(32, 55));
    //     addMeshPiece(meshScene.mRootNode.mChildren[11], meshScene, place(30, 57));

    //     // Barrels near HQ
    //     addMeshPiece(meshScene.mRootNode.mChildren[11], meshScene, place(5, -18));
    //     addMeshPiece(meshScene.mRootNode.mChildren[12], meshScene, place(-5, -18));

    //     // Concrete barriers as road blocks at gate
    //     addMeshPiece(meshScene.mRootNode.mChildren[7], meshScene, place(-3, -42));
    //     addMeshPiece(meshScene.mRootNode.mChildren[7], meshScene, place(3, -42, 0.3f));

    //     // Concrete barriers mid-compound
    //     addMeshPiece(meshScene.mRootNode.mChildren[7], meshScene, place(-10, 5, 1.5708f));
    //     addMeshPiece(meshScene.mRootNode.mChildren[7], meshScene, place(12, 0));

    //     // Metal barriers near target range
    //     addMeshPiece(meshScene.mRootNode.mChildren[9], meshScene, place(-12, 8, 1.5708f));
    //     addMeshPiece(meshScene.mRootNode.mChildren[9], meshScene, place(12, 8, 1.5708f));

    //     // Wooden pallets scattered
    //     addMeshPiece(meshScene.mRootNode.mChildren[14], meshScene, place(-28, 18));
    //     addMeshPiece(meshScene.mRootNode.mChildren[14], meshScene, place(22, 18));
    //     addMeshPiece(meshScene.mRootNode.mChildren[14], meshScene, place(-18, 55));
    //     addMeshPiece(meshScene.mRootNode.mChildren[14], meshScene, place(5, -25));

    //     // Fence sections — between buildings
    //     addMeshPiece(meshScene.mRootNode.mChildren[8], meshScene, place(-35, 15));
    //     addMeshPiece(meshScene.mRootNode.mChildren[8], meshScene, place(-35, 20));
    //     addMeshPiece(meshScene.mRootNode.mChildren[8], meshScene, place(-35, 25));
    //     addMeshPiece(meshScene.mRootNode.mChildren[8], meshScene, place(38, 15, 1.5708f));
    //     addMeshPiece(meshScene.mRootNode.mChildren[8], meshScene, place(38, 20, 1.5708f));

    //     // Fence along north
    //     addMeshPiece(meshScene.mRootNode.mChildren[8], meshScene, place(-20, 75));
    //     addMeshPiece(meshScene.mRootNode.mChildren[8], meshScene, place(-10, 75));
    //     addMeshPiece(meshScene.mRootNode.mChildren[8], meshScene, place(0, 75));
    //     addMeshPiece(meshScene.mRootNode.mChildren[8], meshScene, place(10, 75));
    //     addMeshPiece(meshScene.mRootNode.mChildren[8], meshScene, place(20, 75));

    //     // Barbed wire near perimeter
    //     addMeshPiece(meshScene.mRootNode.mChildren[22], meshScene, place(-38, 10));
    //     addMeshPiece(meshScene.mRootNode.mChildren[22], meshScene, place(43, 5));

    //     // Concrete pillars at HQ entrance
    //     addMeshPiece(meshScene.mRootNode.mChildren[21], meshScene, place(-4, -15));
    //     addMeshPiece(meshScene.mRootNode.mChildren[21], meshScene, place(4, -15));

    //     // Metal wall as shooting range backstop
    //     addMeshPiece(presetScene.mRootNode.mChildren[8], presetScene,  // Metal_Wall_Plain
    //         place(-12, 12));
    //     addMeshPiece(presetScene.mRootNode.mChildren[8], presetScene,
    //         place(0, 12));
    //     addMeshPiece(presetScene.mRootNode.mChildren[8], presetScene,
    //         place(12, 12));

    //     writeln("[arena] Military compound built: 7 buildings + perimeter + props");
    //     aiReleaseImport(presetScene);
    //     aiReleaseImport(meshScene);
    // }




    // void addMeshPiece(const(aiNode)* node, const(aiScene)* scene, mat4 parentTransform)
    //     {
    //         for (uint i = 0; i < node.mNumMeshes; i++)
    //         {
    //             uint meshIdx = node.mMeshes[i];
    //             auto mesh = scene.mMeshes[meshIdx];
    //             auto surf = new SurfaceAssimp(cast(aiMesh*)mesh);
    //             auto mn = new MeshNode("mesh_" ~ meshIdx.to!string, surf, meshesMat);
    //             mn.mModelMatrix = parentTransform;
    //             mn.mBoundingRadius = surf.mBoundingRadius * sc;
    //             mSceneTree.GetRootNode().AddChildSceneNode(mn);
    //         }
    //         for (uint i = 0; i < node.mNumChildren; i++)
    //             addMeshPiece(node.mChildren[i], scene, parentTransform);
    //     }





}
