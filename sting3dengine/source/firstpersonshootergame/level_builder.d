// /// Sets up the map and terrain of the game
// /// The level builder also relies on object factory for placement of game objects to the scene

// module level_builder;

// // standard library files
// import std.stdio;
// import std.conv;
// // import std.datetime.systime : Clock;
// import std.string : toStringz, fromStringz;
// // import std.math;
// // import std.random : uniform;

// // project files
// import enginecore;
// import linear;
// import physics;
// // import geometry;
// import materials;
// // import audiosubsystem;
// import assimp;
// // import editor;
// // import gamegui;
// // import light;
// import factory;

// // Third-party libraries
// // import bindbc.sdl;
// // import bindbc.opengl;


// class LevelBuilder{


//     //Objects Belonging to Engine
//     Camera mCamera;
//     SceneTree mSceneTree;


//     //Objects Belonging to Game



//     //Objects belonging to Level Builder
//     IMaterial mMapMaterial;
//     IMaterial mBasicMaterial;
//     float mMapKitScaleFactor = 0.015f;
//     SpawnFactory mSpawnFactory;

//     this(Camera cam, SceneTree tree, EntityManager em, PhysicsWorld physics, IMaterial mat){
//         mCamera = cam;
//         mSceneTree = tree;
//         mBasicMaterial = mat;

//         //create spawn Factory that will spawn game Objects
//         mSpawnFactory = new SpawnFactory(cam, em, tree, physics, mat);

//     }

//     void SetupMap()
//     {
//         SetupLightbox();
//         SetupTerrain();
//         SetupArena();
//         mSpawnFactory.SpawnFactoryObjects();
//     }



//     void SetupLightbox()
//     {
//         import bindbc.opengl;
//         import geometry;

//         Pipeline lightPipeline = new Pipeline("light",
//             "./pipelines/light/basic.vert",
//             "./pipelines/light/basic.frag");
//         IMaterial lightMaterial = new BasicMaterial("light");

//         GLfloat[] lightboxVBO = [
//             -0.5f, -0.5f, -0.5f,  1.0f, 1.0f, 1.0f,
//              0.5f, -0.5f, -0.5f,  1.0f, 1.0f, 1.0f,
//              0.5f,  0.5f, -0.5f,  1.0f, 1.0f, 1.0f,
//              0.5f,  0.5f, -0.5f,  1.0f, 1.0f, 1.0f,
//             -0.5f,  0.5f, -0.5f,  1.0f, 1.0f, 1.0f,
//             -0.5f, -0.5f, -0.5f,  1.0f, 1.0f, 1.0f,
//             -0.5f, -0.5f,  0.5f,  1.0f, 1.0f, 1.0f,
//              0.5f, -0.5f,  0.5f,  1.0f, 1.0f, 1.0f,
//              0.5f,  0.5f,  0.5f,  1.0f, 1.0f, 1.0f,
//              0.5f,  0.5f,  0.5f,  1.0f, 1.0f, 1.0f,
//             -0.5f,  0.5f,  0.5f,  1.0f, 1.0f, 1.0f,
//             -0.5f, -0.5f,  0.5f,  1.0f, 1.0f, 1.0f,
//             -0.5f,  0.5f,  0.5f,  1.0f, 1.0f, 1.0f,
//             -0.5f,  0.5f, -0.5f,  1.0f, 1.0f, 1.0f,
//             -0.5f, -0.5f, -0.5f,  1.0f, 1.0f, 1.0f,
//             -0.5f, -0.5f, -0.5f,  1.0f, 1.0f, 1.0f,
//             -0.5f, -0.5f,  0.5f,  1.0f, 1.0f, 1.0f,
//             -0.5f,  0.5f,  0.5f,  1.0f, 1.0f, 1.0f,
//              0.5f,  0.5f,  0.5f,  1.0f, 1.0f, 1.0f,
//              0.5f,  0.5f, -0.5f,  1.0f, 1.0f, 1.0f,
//              0.5f, -0.5f, -0.5f,  1.0f, 1.0f, 1.0f,
//              0.5f, -0.5f, -0.5f,  1.0f, 1.0f, 1.0f,
//              0.5f, -0.5f,  0.5f,  1.0f, 1.0f, 1.0f,
//              0.5f,  0.5f,  0.5f,  1.0f, 1.0f, 1.0f,
//             -0.5f, -0.5f, -0.5f,  1.0f, 1.0f, 1.0f,
//              0.5f, -0.5f, -0.5f,  1.0f, 1.0f, 1.0f,
//              0.5f, -0.5f,  0.5f,  1.0f, 1.0f, 1.0f,
//              0.5f, -0.5f,  0.5f,  1.0f, 1.0f, 1.0f,
//             -0.5f, -0.5f,  0.5f,  1.0f, 1.0f, 1.0f,
//             -0.5f, -0.5f, -0.5f,  1.0f, 1.0f, 1.0f,
//             -0.5f,  0.5f, -0.5f,  1.0f, 1.0f, 1.0f,
//              0.5f,  0.5f, -0.5f,  1.0f, 1.0f, 1.0f,
//              0.5f,  0.5f,  0.5f,  1.0f, 1.0f, 1.0f,
//              0.5f,  0.5f,  0.5f,  1.0f, 1.0f, 1.0f,
//             -0.5f,  0.5f,  0.5f,  1.0f, 1.0f, 1.0f,
//             -0.5f,  0.5f, -0.5f,  1.0f, 1.0f, 1.0f
//         ];

//         ISurface lightBox = new SurfaceTriangle(lightboxVBO);
//         MeshNode light = new MeshNode("light", lightBox, lightMaterial);
//         mSceneTree.GetRootNode().AddChildSceneNode(light);

//         lightMaterial.AddUniform(new Uniform("uModel", "mat4", null));
//         lightMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
//         lightMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));
//     }

//     void SetupTerrain()
//     {
//         Pipeline simpleTexPipeline = new Pipeline("textured_simple",
//             "./pipelines/textured_simple/textured_simple.vert",
//             "./pipelines/textured_simple/textured_simple.frag");

//         IMaterial grassMaterial = new LitTexturedMaterial("textured_simple",
//             "./assets/textures/green-grass-background.jpg");
//         grassMaterial.AddUniform(new Uniform("uTexture", 0));
//         grassMaterial.AddUniform(new Uniform("uModel", "mat4", null));
//         grassMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
//         grassMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));

//         import geometry;
//         ISurface terrain = new SurfaceTerrain(512, 512,
//             "./assets/heightmaps/flat_slight_variation_heightmap.ppm");
//         MeshNode m2 = new MeshNode("terrain", terrain, grassMaterial);
//         mSceneTree.GetRootNode().AddChildSceneNode(m2);
//     }


//      void SetupArena(){
    
//         auto presetScene = aiImportFile(
//             "./assets/fps_map_kit/uploads_files_3151797_FPS_Modular_Map_Kit_FBX/Fps_Modular_Map_Presets.fbx".toStringz,
//             aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs);
        
//         if (presetScene !is null){

//             mMapMaterial = new LitTexturedMaterial("lit_textured",
//                 "./assets/fps_map_kit/uploads_files_3151797_FPS_Modular_Map_Kit_Map/FPS_Modular_Map_BaseColor.png");
//             mMapMaterial.AddUniform(new Uniform("uTexture", 0));
//             mMapMaterial.AddUniform(new Uniform("uModel", "mat4", null));
//             mMapMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
//             mMapMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));

//             float sc = 0.015f;


//             // Place presets to build an arena
//             // Cabin A at center
//             addNodeMeshes(presetScene.mRootNode.mChildren[13], presetScene,
//                 MatrixMakeTranslation(vec3(0.0f, 0.0f, -20.0f)) * MatrixMakeScale(vec3(mMapKitScaleFactor, mMapKitScaleFactor, mMapKitScaleFactor)));

//             // Cabin B offset
//             addNodeMeshes(presetScene.mRootNode.mChildren[16], presetScene,
//                 MatrixMakeTranslation(vec3(30.0f, 0.0f, -20.0f)) * MatrixMakeScale(vec3(mMapKitScaleFactor, mMapKitScaleFactor, mMapKitScaleFactor)));

//             // Building
//             addNodeMeshes(presetScene.mRootNode.mChildren[1], presetScene,
//                 MatrixMakeTranslation(vec3(15.0f, 0.0f, -40.0f)) * MatrixMakeScale(vec3(mMapKitScaleFactor, mMapKitScaleFactor, mMapKitScaleFactor)));

//             // Exterior walls
//             addNodeMeshes(presetScene.mRootNode.mChildren[18], presetScene,
//                 MatrixMakeTranslation(vec3(-10.0f, 0.0f, 0.0f)) * MatrixMakeScale(vec3(mMapKitScaleFactor, mMapKitScaleFactor, mMapKitScaleFactor)));
//             addNodeMeshes(presetScene.mRootNode.mChildren[18], presetScene,
//                 MatrixMakeTranslation(vec3(40.0f, 0.0f, 0.0f)) * MatrixMakeScale(vec3(mMapKitScaleFactor, mMapKitScaleFactor, mMapKitScaleFactor)));

//             // Sandbags for cover
//             addNodeMeshes(presetScene.mRootNode.mChildren[20], presetScene,
//                 MatrixMakeTranslation(vec3(10.0f, 0.0f, -10.0f)) * MatrixMakeScale(vec3(mMapKitScaleFactor, mMapKitScaleFactor, mMapKitScaleFactor)));

//             addNodeMeshes(presetScene.mRootNode.mChildren[21], presetScene,
//                 MatrixMakeTranslation(vec3(20.0f, 0.0f, -15.0f)) * MatrixMakeScale(vec3(mMapKitScaleFactor, mMapKitScaleFactor, mMapKitScaleFactor)));
//             addNodeMeshes(presetScene.mRootNode.mChildren[22], presetScene,
//                 MatrixMakeTranslation(vec3(5.0f, 0.0f, -30.0f)) * MatrixMakeScale(vec3(mMapKitScaleFactor, mMapKitScaleFactor, mMapKitScaleFactor)));

//             // Corner wall
//             addNodeMeshes(presetScene.mRootNode.mChildren[19], presetScene,
//                 MatrixMakeTranslation(vec3(-10.0f, 0.0f, -40.0f)) * MatrixMakeScale(vec3(mMapKitScaleFactor, mMapKitScaleFactor, mMapKitScaleFactor)));

//             writeln("[arena] built from presets");
//             aiReleaseImport(presetScene);
//         }
//     }



//     // Helper: recursively add all meshes under a node
//     void addNodeMeshes(const(aiNode)* node, const(aiScene)* scene, mat4 parentTransform){

//         for (uint i = 0; i < node.mNumMeshes; i++){
//             uint meshIdx = node.mMeshes[i];
//             auto mesh = scene.mMeshes[meshIdx];
//             auto surf = new SurfaceAssimp(cast(aiMesh*)mesh);
//             auto mn = new MeshNode("preset_" ~ meshIdx.to!string, surf, mMapMaterial);
//             mn.mModelMatrix = parentTransform;
//             mn.mBoundingRadius = surf.mBoundingRadius * mMapKitScaleFactor;  // scale the radius too
//             mSceneTree.GetRootNode().AddChildSceneNode(mn);
//         }

//         for (uint i = 0; i < node.mNumChildren; i++){
//             addNodeMeshes(node.mChildren[i], scene, parentTransform);
//         }
//     } //end addNodeMeshes



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

        writeln("[arena] built from presets");
        aiReleaseImport(presetScene);
    }
}
