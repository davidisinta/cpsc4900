/// Spawn game entities conviniently
/// For example soldiers trees and physics backed entities

module factory;




// standard library files
import std.stdio;
import std.conv;
// import std.datetime.systime : Clock;
import std.string : toStringz, fromStringz;
// import std.math;
import std.random : uniform;

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

// Third-party libraries
// import bindbc.sdl;
// import bindbc.opengl;




class SpawnFactory{


    //Objects Belonging to Engine
    EntityManager mEntityManager;
    SceneTree mSceneTree;
    Camera mCamera;
    PhysicsWorld mPhysicsWorld;
    

    //Objects Belonging to Game



    //Objects belonging to Spawn Factory
    IMaterial mLindenBarkMaterial;
    IMaterial mLitTexturedMaterial;
    vec3 mFogColor;
    float mFogStart;
    float mFogEnd;


    this(Camera cam, EntityManager em, SceneTree tree, PhysicsWorld physics){
        mCamera = cam;
        mEntityManager = em;
        mSceneTree = tree;
        mPhysicsWorld = physics;

        //Set up Fog Values
        mFogColor = vec3(0.55f, 0.68f, 0.78f);
        mFogStart = 80.0f;
        mFogEnd = 180.0f;

        //Setup Materials that are needed by objects to color them
        SetupMaterials();

    }

    /// Main Function For this file and Spawns All objects
    /// To do: refactor to use factory pattern
    void SpawnFactoryObjects(){
        spawnSoldiers();
        spawnTrees();

    }

    /// create Soldiers
    void spawnSoldiers(){
        spawnSoldierEnemy(vec3(33.0f, 0.0f, -10.0f), Quat.init);
        spawnSoldierEnemy(vec3(0.0f, 0.0f, -30.0f), Quat.init);
        spawnSoldierEnemy(vec3(0.0f, 0.0f, -40.0f), Quat.init);
        spawnSoldierEnemy(vec3(13.0f, 0.0f, -17.0f), Quat.init);
        spawnSoldierEnemy(vec3(23.0f, 0.0f, -17.0f), Quat.init);
        spawnSoldierEnemy(vec3(13.0f, 0.0f, -37.0f), Quat.init);
        spawnSoldierEnemy(vec3(43.0f, 0.0f, 17.0f), Quat.init);

    } // end spawnSoldiers


    /// create Trees
    void spawnTrees(){

        writeln("[tree-test] A before linden block");

        // 160 trees, all at least radius 100 from origin
        foreach (i; 0 .. 160){
            float x, z;

            // keep sampling until outside radius 100
            do
            {
                x = uniform(-120.0f, 120.0f);
                z = uniform(-120.0f, 120.0f);
            }
            while ((x * x + z * z) < (100.0f * 100.0f));

            spawnLinden1VisualOnly(vec3(x, 0.0f, z), Quat.init);
        }

        debugLindenAsset();
        writeln("[tree-test] B after linden block");

    } // end spawnTrees




    uint spawnLinden1VisualOnly(vec3 pos, Quat orient = Quat.init){

        string modelPath = "./assets/4-linden-trees-pack-medium-poly/import_1/linden.obj";

        uint eid = mEntityManager.create();

        auto scene = aiImportFile(
            modelPath.toStringz,
            aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs
        );

        if (scene is null)
        {
            writeln("[linden] failed to import ", modelPath);
            return eid;
        }

        TransformComponent tc;
        tc.position = pos;
        tc.rotation = orient;
        mEntityManager.addTransform(eid, tc);

        auto lindenNode = findNodeByName(scene.mRootNode, "linden_1");

        if (lindenNode is null){
            writeln("[linden] node linden_1 not found");
            aiReleaseImport(scene);
            return eid;
        }

        addMeshesFromNode(lindenNode, scene, eid, pos, mLindenBarkMaterial);

        aiReleaseImport(scene);

        // writeln("[linden] visual-only entity=", eid, " spawned at ", pos);
        return eid;

    } // end spawnLinden1VisualOnly



    const(aiNode)* findNodeByName(const(aiNode)* node, string targetName){
        if (node is null) return null;

        auto nodeName = fromStringz(node.mName.data);
        if (nodeName == targetName)
            return node;

        foreach (i; 0 .. node.mNumChildren)
        {
            auto found = findNodeByName(node.mChildren[i], targetName);
            if (found !is null)
                return found;
        }

        return null;
    }

    void addMeshesFromNode(
        const(aiNode)* node,
        const(aiScene)* scene,
        uint eid,
        vec3 pos,
        IMaterial mat){

        if (node is null || scene is null) return;

        foreach (i; 0 .. node.mNumMeshes)
        {
            uint meshIdx = node.mMeshes[i];
            auto mesh = scene.mMeshes[meshIdx];

            auto surf = new SurfaceAssimp(cast(aiMesh*)mesh);
            auto renderNode = new MeshNode(
                "linden_" ~ eid.to!string ~ "_" ~ meshIdx.to!string,
                surf,
                mat
            );
            renderNode.mBoundingRadius = surf.mBoundingRadius;

            renderNode.mModelMatrix =
                MatrixMakeTranslation(pos) *
                MatrixMakeScale(vec3(1.0f, 1.0f, 1.0f));

            mSceneTree.GetRootNode().AddChildSceneNode(renderNode);
            mEntityManager.addRenderable(eid, renderNode);
        }
    }



    void debugLindenAsset(){
        auto scene = aiImportFile(
            "./assets/4-linden-trees-pack-medium-poly/import_1/linden.obj".toStringz,
            aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs
        );

        if (scene is null)
        {
            // writeln("[linden-debug] failed to import OBJ");
            return;
        }

        // writeln("[linden-debug] mesh count = ", scene.mNumMeshes);
        // writeln("[linden-debug] material count = ", scene.mNumMaterials);

        for (uint i = 0; i < scene.mNumMeshes; ++i)
        {
            auto mesh = scene.mMeshes[i];
            // writeln("[linden-debug] mesh ", i,
            //     " materialIndex=", mesh.mMaterialIndex,
            //     " vertexCount=", mesh.mNumVertices,
            //     " faceCount=", mesh.mNumFaces);
        }

        // writeln("[linden-debug] NODE TREE:");
        debugAssimpNodeTree(scene.mRootNode);

        aiReleaseImport(scene);
    }




    void debugAssimpNodeTree(const(aiNode)* node, int depth = 0){
        if (node is null) return;

        string indent;
        foreach (_; 0 .. depth) indent ~= "  ";

        auto nodeName = aiNodeName(node);

        writeln(indent, "[assimp-node] name=", nodeName,
            " meshes=", node.mNumMeshes,
            " children=", node.mNumChildren);

        foreach (i; 0 .. node.mNumMeshes)
        {
            writeln(indent, "  meshIndex=", node.mMeshes[i]);
        }

        foreach (i; 0 .. node.mNumChildren)
        {
            debugAssimpNodeTree(node.mChildren[i], depth + 1);
        }
    }


    string aiNodeName(const(aiNode)* node){
        if (node is null) return "";

        size_t len = cast(size_t)node.mName.length;
        return cast(string) node.mName.data[0 .. len];
    }








    uint spawnSoldierEnemy(vec3 pos, Quat orient = Quat.init){

        string soldierModel = "./assets/modern_soldier/scene.gltf";
        string soldierPhysics = "soldier.urdf";

        uint eid = mEntityManager.create();

        mPhysicsWorld.addURDF(eid, soldierPhysics,
            pos.x, pos.y + 1.0f, pos.z,
            orient.x, orient.y, orient.z, orient.w);
        mEntityManager.markPhysics(eid);

        // Load model and add with TEXTURED material
        auto model = new Model(soldierModel);
        auto nodes = model.addToScene(mSceneTree, mLitTexturedMaterial, "soldier_" ~ eid.to!string);

        TransformComponent tc;
        tc.position = vec3(pos.x, pos.y + 1.0f, pos.z);
        tc.rotation = orient;
        mEntityManager.addTransform(eid, tc);

        foreach (node; nodes){
            node.mModelMatrix = tc.toModelMatrix();
            mEntityManager.addRenderable(eid, node);
        }

        writeln("[soldier] spawned entity=", eid, " at ", pos);
        return eid;
    }






    //----------------------------------------------------------------
    // Helper to Setup Materials For Objects such as Trees
    //----------------------------------------------------------------
    void SetupMaterials(){

        // Lit + textured pipeline for models with UV + texture
        Pipeline litTexPipeline = new Pipeline("lit_textured",
            "./pipelines/lit_textured/lit_textured.vert",
            "./pipelines/lit_textured/lit_textured.frag");

        mLitTexturedMaterial = new LitTexturedMaterial("lit_textured",
            "./assets/modern_soldier/textures/material_0_baseColor.jpeg");

        mLitTexturedMaterial.AddUniform(new Uniform("uTexture", 0));
        mLitTexturedMaterial.AddUniform(new Uniform("uModel", "mat4", null));
        mLitTexturedMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
        mLitTexturedMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));
        mLitTexturedMaterial.AddUniform(new Uniform("uFogColor", "vec3", &mFogColor));
        mLitTexturedMaterial.AddUniform(new Uniform("uFogStart", mFogStart));
        mLitTexturedMaterial.AddUniform(new Uniform("uFogEnd", mFogEnd));













        //----------------------------------------------------------------
        // Add Materials for the tree
        //----------------------------------------------------------------
        // simple tree
        mLindenBarkMaterial = new LitTexturedMaterial("lit_textured", "./assets/4-linden-trees-pack-medium-poly/import_1/nature_bark_linden_04_m_0001.jpg");

        mLindenBarkMaterial.AddUniform(new Uniform("uTexture", 0));
        mLindenBarkMaterial.AddUniform(new Uniform("uModel", "mat4", null));
        mLindenBarkMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
        mLindenBarkMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));

        mLitTexturedMaterial.AddUniform(new Uniform("uFogColor", "vec3", &mFogColor));
        mLitTexturedMaterial.AddUniform(new Uniform("uFogStart", mFogStart));
        mLitTexturedMaterial.AddUniform(new Uniform("uFogEnd", mFogEnd));
    }








    




}