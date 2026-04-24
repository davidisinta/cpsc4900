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
        mSpawnFactory.spawnSoldiers();
        mSpawnFactory.spawnTrees();
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

    void SetupArena()
    {
        auto presetScene = aiImportFile(
            "./assets/fps_map_kit/uploads_files_3151797_FPS_Modular_Map_Kit_FBX/Fps_Modular_Map_Presets.fbx".toStringz,
            aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs);

        if (presetScene is null) return;

        IMaterial mapMat = mMaterials.get("map");
        float sc = mMapKitScaleFactor;

        void addNodeMeshes(const(aiNode)* node, const(aiScene)* scene, mat4 parentTransform)
        {
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

        addNodeMeshes(presetScene.mRootNode.mChildren[13], presetScene,
            MatrixMakeTranslation(vec3(0.0f, 0.0f, -20.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));
        addNodeMeshes(presetScene.mRootNode.mChildren[16], presetScene,
            MatrixMakeTranslation(vec3(30.0f, 0.0f, -20.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));
        addNodeMeshes(presetScene.mRootNode.mChildren[1], presetScene,
            MatrixMakeTranslation(vec3(15.0f, 0.0f, -40.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));
        addNodeMeshes(presetScene.mRootNode.mChildren[18], presetScene,
            MatrixMakeTranslation(vec3(-10.0f, 0.0f, 0.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));
        addNodeMeshes(presetScene.mRootNode.mChildren[18], presetScene,
            MatrixMakeTranslation(vec3(40.0f, 0.0f, 0.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));
        addNodeMeshes(presetScene.mRootNode.mChildren[20], presetScene,
            MatrixMakeTranslation(vec3(10.0f, 0.0f, -10.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));
        addNodeMeshes(presetScene.mRootNode.mChildren[21], presetScene,
            MatrixMakeTranslation(vec3(20.0f, 0.0f, -15.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));
        addNodeMeshes(presetScene.mRootNode.mChildren[22], presetScene,
            MatrixMakeTranslation(vec3(5.0f, 0.0f, -30.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));
        addNodeMeshes(presetScene.mRootNode.mChildren[19], presetScene,
            MatrixMakeTranslation(vec3(-10.0f, 0.0f, -40.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));


        // Print bounding info for collision boxes
        writeln("[collision] Dumping arena piece bounding info:");
        struct Piece { string name; int nodeIdx; vec3 pos; }
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
            auto node = presetScene.mRootNode.mChildren[p.nodeIdx];
            auto nodeName = node.mName.data[0 .. node.mName.length];
            // Get bounding from first mesh
            if (node.mNumMeshes > 0)
            {
                auto mesh = presetScene.mMeshes[node.mMeshes[0]];
                float minX = float.max, minZ = float.max;
                float maxX = -float.max, maxZ = -float.max;
                for (uint v = 0; v < mesh.mNumVertices; v++)
                {
                    float x = mesh.mVertices[v].x * sc + p.pos.x;
                    float z = mesh.mVertices[v].z * sc + p.pos.z;
                    if (x < minX) minX = x;
                    if (x > maxX) maxX = x;
                    if (z < minZ) minZ = z;
                    if (z > maxZ) maxZ = z;
                }
                writeln("  ", p.name, " '", nodeName, "' box: minX=", minX, " minZ=", minZ, " maxX=", maxX, " maxZ=", maxZ);
            }
        }

        writeln("[arena] built from presets");
        aiReleaseImport(presetScene);
    }
}
