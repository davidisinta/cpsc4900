/// Sets up the map and terrain of the game
/// The level builder also relies on object factory for placement of game objects to the scene

module level_builder;

// standard library files
import std.stdio;
import std.conv;
// import std.datetime.systime : Clock;
import std.string : toStringz, fromStringz;
// import std.math;
// import std.random : uniform;

// project files
import enginecore;
import linear;
import physics;
// import geometry;
import materials;
// import audiosubsystem;
import assimp;
// import editor;
// import gamegui;
// import light;
import factory;

// Third-party libraries
// import bindbc.sdl;
// import bindbc.opengl;


class LevelBuilder{


    //Objects Belonging to Engine
    Camera mCamera;
    SceneTree mSceneTree;


    //Objects Belonging to Game



    //Objects belonging to Level Builder
    IMaterial mMapMaterial;
    float mMapKitScaleFactor = 0.015f;
    SpawnFactory mSpawnFactory;

    this(Camera cam, SceneTree tree, EntityManager em, PhysicsWorld physics){
        mCamera = cam;
        mSceneTree = tree;



        //create spawn Factory that will spawn game Objects
        mSpawnFactory = new SpawnFactory(cam, em, tree, physics);





    }


    /// Set up the map of the game
    ///This is the main function of this class and is called by GameApp to load Map
    void SetupMap(){
        
        // Build game from presets
        auto presetScene = aiImportFile(
            "./assets/fps_map_kit/uploads_files_3151797_FPS_Modular_Map_Kit_FBX/Fps_Modular_Map_Presets.fbx".toStringz,
            aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs);
        
        if (presetScene !is null){

            mMapMaterial = new LitTexturedMaterial("lit_textured",
                "./assets/fps_map_kit/uploads_files_3151797_FPS_Modular_Map_Kit_Map/FPS_Modular_Map_BaseColor.png");
            mMapMaterial.AddUniform(new Uniform("uTexture", 0));
            mMapMaterial.AddUniform(new Uniform("uModel", "mat4", null));
            mMapMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
            mMapMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));

            float sc = 0.015f;


            // Place presets to build an arena
            // Cabin A at center
            addNodeMeshes(presetScene.mRootNode.mChildren[13], presetScene,
                MatrixMakeTranslation(vec3(0.0f, 0.0f, -20.0f)) * MatrixMakeScale(vec3(mMapKitScaleFactor, mMapKitScaleFactor, mMapKitScaleFactor)));

            // Cabin B offset
            addNodeMeshes(presetScene.mRootNode.mChildren[16], presetScene,
                MatrixMakeTranslation(vec3(30.0f, 0.0f, -20.0f)) * MatrixMakeScale(vec3(mMapKitScaleFactor, mMapKitScaleFactor, mMapKitScaleFactor)));

            // Building
            addNodeMeshes(presetScene.mRootNode.mChildren[1], presetScene,
                MatrixMakeTranslation(vec3(15.0f, 0.0f, -40.0f)) * MatrixMakeScale(vec3(mMapKitScaleFactor, mMapKitScaleFactor, mMapKitScaleFactor)));

            // Exterior walls
            addNodeMeshes(presetScene.mRootNode.mChildren[18], presetScene,
                MatrixMakeTranslation(vec3(-10.0f, 0.0f, 0.0f)) * MatrixMakeScale(vec3(mMapKitScaleFactor, mMapKitScaleFactor, mMapKitScaleFactor)));
            addNodeMeshes(presetScene.mRootNode.mChildren[18], presetScene,
                MatrixMakeTranslation(vec3(40.0f, 0.0f, 0.0f)) * MatrixMakeScale(vec3(mMapKitScaleFactor, mMapKitScaleFactor, mMapKitScaleFactor)));

            // Sandbags for cover
            addNodeMeshes(presetScene.mRootNode.mChildren[20], presetScene,
                MatrixMakeTranslation(vec3(10.0f, 0.0f, -10.0f)) * MatrixMakeScale(vec3(mMapKitScaleFactor, mMapKitScaleFactor, mMapKitScaleFactor)));

            addNodeMeshes(presetScene.mRootNode.mChildren[21], presetScene,
                MatrixMakeTranslation(vec3(20.0f, 0.0f, -15.0f)) * MatrixMakeScale(vec3(mMapKitScaleFactor, mMapKitScaleFactor, mMapKitScaleFactor)));
            addNodeMeshes(presetScene.mRootNode.mChildren[22], presetScene,
                MatrixMakeTranslation(vec3(5.0f, 0.0f, -30.0f)) * MatrixMakeScale(vec3(mMapKitScaleFactor, mMapKitScaleFactor, mMapKitScaleFactor)));

            // Corner wall
            addNodeMeshes(presetScene.mRootNode.mChildren[19], presetScene,
                MatrixMakeTranslation(vec3(-10.0f, 0.0f, -40.0f)) * MatrixMakeScale(vec3(mMapKitScaleFactor, mMapKitScaleFactor, mMapKitScaleFactor)));

            writeln("[arena] built from presets");
            aiReleaseImport(presetScene);
        }


        // spawn the objects created by factory
        mSpawnFactory.SpawnFactoryObjects();

    } // end SetupMap



    // Helper: recursively add all meshes under a node
    void addNodeMeshes(const(aiNode)* node, const(aiScene)* scene, mat4 parentTransform){

        for (uint i = 0; i < node.mNumMeshes; i++){
            uint meshIdx = node.mMeshes[i];
            auto mesh = scene.mMeshes[meshIdx];
            auto surf = new SurfaceAssimp(cast(aiMesh*)mesh);
            auto mn = new MeshNode("preset_" ~ meshIdx.to!string, surf, mMapMaterial);
            mn.mModelMatrix = parentTransform;
            mn.mBoundingRadius = surf.mBoundingRadius * mMapKitScaleFactor;  // scale the radius too
            mSceneTree.GetRootNode().AddChildSceneNode(mn);
        }

        for (uint i = 0; i < node.mNumChildren; i++){
            addNodeMeshes(node.mChildren[i], scene, parentTransform);
        }
    } //end addNodeMeshes



}
