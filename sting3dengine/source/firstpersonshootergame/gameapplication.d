module gameapplication;

// standard library files
import std.stdio;
import std.conv;
import std.datetime.systime : Clock;
import std.string : toStringz, fromStringz;
import std.math;
import std.random : uniform;

// project files
import enginecore;
import linear;
import physics;
import geometry;
import materials;
import audiosubsystem;
import assimp;
import editor;
import gamegui;
import light;

// Third-party libraries
import bindbc.sdl;
import bindbc.opengl;

class GameApplication : IGame{
    // Refs to engine systems
    PhysicsWorld mPhysicsWorld;
    EntityManager mEntityManager;
    Camera mCamera;
    SceneTree mSceneTree;
    IMaterial mBasicMaterial;
    AudioEngine* mAudio;

    // Game-specific state
    string gameName;
    uint mGroundEntity;
    uint mCubeEntity;
    int mShotsFired;
    int mShotsHit;
    bool mShootRequested;
    GLuint mCrosshairVAO;
    GLuint mCrosshairVBO;
    bool mCrosshairReady = false;
    GameGUI mGui;
    Light gLight;
    GLuint mSkyBoxVAO;
    GLuint  mSkyBoxVBO;
    GLuint mCubemapTexture;
    vec3 mFogColor;
    float mFogStart;
    float mFogEnd;

    //Game Materials
    IMaterial mLitTexturedMaterial;
    IMaterial mTreeBarkMaterial;
    IMaterial mTreeLeafMaterial;
    IMaterial mLindenBarkMaterial;

    //sound specific elements
    bool mWalkingSoundPlaying = false;
    FMOD_SOUND* mWalkingSound;
    FMOD_CHANNEL* mWalkingSoundChannel;
    FMOD_SYSTEM* mSystem;

    FMOD_SOUND* mPistolSound;
    FMOD_CHANNEL* mPistolSoundChannel;

    FMOD_SOUND* mBackgroundSound;
    FMOD_CHANNEL* mBackgroundChannel;
    bool mBackgroundPlaying = false;

    this(string name, PhysicsWorld physics, EntityManager em, Camera cam, SceneTree tree, IMaterial mat){
        this.gameName = name;
        mPhysicsWorld = physics;
        mEntityManager = em;
        mCamera = cam;
        mSceneTree = tree;
        mBasicMaterial = mat;
        mGui = new GameGUI("topshoota-game-gui");
        mFogColor = vec3(0.55f, 0.68f, 0.78f);
        mFogStart = 80.0f;
        mFogEnd = 180.0f;
    }

    override void Input(){
        if (mShootRequested){
            shoot();
            mShootRequested = false;
        }
    }

    override void Update(double frameDt){
        checkCollisions();

        // Update GUI state
        mGui.kills = mShotsHit;
        mGui.accuracy = mShotsFired > 0 ? cast(float)mShotsHit / mShotsFired * 100.0f : 0.0f;

        // placeholder until weapon system
        mGui.currentAmmo = 30;
        mGui.maxAmmo = 30;

        //update our light object
        MeshNode lightNode = cast(MeshNode)mSceneTree.FindNode("light");

        if (lightNode !is null){
            GLfloat x = gLight.mPosition[0];
            GLfloat y = gLight.mPosition[1];
            GLfloat z = gLight.mPosition[2];
            
            //move the lightbox that follows the point light and scale it to 15
            lightNode.mModelMatrix = MatrixMakeTranslation(vec3(x, y, z))
                                    * MatrixMakeScale(vec3(15.0f, 15.0f, 15.0f));
        }

        MeshNode m2 = cast(MeshNode)mSceneTree.FindNode("terrain");
        if (m2 is null) {
            writeln("[terrain] ERROR: terrain node not found in scene tree!");
        } else {
            m2.mModelMatrix = MatrixMakeTranslation(vec3(-256.0f, 0.0f, -256.0f));
        }
    }

    void Render(){

        //Render Cross Hair as it is like a GUI element
        drawCrosshair();

        //Render the games GUI last
        mGui.Render();
    }

    //--------------------------------------------------------------
    // Spawn a physics-driven object with both visual + physics
    //--------------------------------------------------------------
    /// Creates an entity with:
    ///   - a Bullet physics body (from URDF)
    ///   - a rendered mesh (from .obj)
    ///   - a TransformComponent synced each frame
    ///
    /// Returns the entity ID.
    uint spawnPhysicsObject(
    string urdfPath,
    string modelPath,
    vec3 pos,
    Quat orient = Quat.init){
        uint eid = mEntityManager.create();

        // add physics to the object
        mPhysicsWorld.addURDF(
            eid, urdfPath,
            pos.x, pos.y, pos.z,
            orient.x, orient.y, orient.z, orient.w
        );
        mEntityManager.markPhysics(eid);

        // add the model to rendering scene
        auto model = new Model(modelPath);
        auto nodes = model.addToScene(mSceneTree, mBasicMaterial, "entity_" ~ eid.to!string);

        //hook up the physics and rendering object together
        TransformComponent tc;
        tc.position = pos;
        tc.rotation = orient;
        mEntityManager.addTransform(eid, tc);

        foreach (node; nodes) {
            node.mModelMatrix = tc.toModelMatrix();
            mEntityManager.addRenderable(eid, node);
        }

        writeln("[spawn] entity=", eid, " urdf=", urdfPath, " model=", modelPath, " pos=", pos);
        return eid;
    }

    void drawCrosshair(){
        if (!mCrosshairReady) return;

        glDisable(GL_DEPTH_TEST);

        glUseProgram(Pipeline.sPipeline["crosshair"]);
        glBindVertexArray(mCrosshairVAO);
        glLineWidth(2.0f);
        glDrawArrays(GL_LINES, 0, 8);
        glBindVertexArray(0);

        glEnable(GL_DEPTH_TEST);
    }

    //Setup the Scene for the Game
    override void Setup(){
        
        // Create a pipeline and associate it with a material
        Pipeline basicPipeline = new Pipeline("basic","./pipelines/basic/basic.vert","./pipelines/basic/basic.frag");
        mBasicMaterial = new BasicMaterial("basic");  // cache for spawning

        // Create a pipeline for our light
        Pipeline lightPipeline = new Pipeline("light","./pipelines/light/basic.vert","./pipelines/light/basic.frag");
        IMaterial lightMaterial    = new BasicMaterial("light");

        //we create another object for our light box and add it to scene tree
        GLfloat[] lightboxVBO = [
            -0.5f, -0.5f, -0.5f,  1.0f,  1.0f, 1.0f,
                0.5f, -0.5f, -0.5f,  1.0f,  1.0f, 1.0f,
                0.5f,  0.5f, -0.5f,  1.0f,  1.0f, 1.0f,
                0.5f,  0.5f, -0.5f,  1.0f,  1.0f, 1.0f,
            -0.5f,  0.5f, -0.5f,  1.0f,  1.0f, 1.0f,
            -0.5f, -0.5f, -0.5f,  1.0f,  1.0f, 1.0f,

            -0.5f, -0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
                0.5f, -0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
                0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
                0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
            -0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
            -0.5f, -0.5f,  0.5f,  1.0f,  1.0f,  1.0f,

            -0.5f,  0.5f,  0.5f, 1.0f,  1.0f,  1.0f,
            -0.5f,  0.5f, -0.5f, 1.0f,  1.0f,  1.0f,
            -0.5f, -0.5f, -0.5f, 1.0f,  1.0f,  1.0f,
            -0.5f, -0.5f, -0.5f, 1.0f,  1.0f,  1.0f,
            -0.5f, -0.5f,  0.5f, 1.0f,  1.0f,  1.0f,
            -0.5f,  0.5f,  0.5f, 1.0f,  1.0f,  1.0f,

                0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
                0.5f,  0.5f, -0.5f,  1.0f,  1.0f,  1.0f,
                0.5f, -0.5f, -0.5f,  1.0f,  1.0f,  1.0f,
                0.5f, -0.5f, -0.5f,  1.0f,  1.0f,  1.0f,
                0.5f, -0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
                0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,

            -0.5f, -0.5f, -0.5f,  1.0f, 1.0f,  1.0f,
                0.5f, -0.5f, -0.5f,  1.0f, 1.0f,  1.0f,
                0.5f, -0.5f,  0.5f,  1.0f, 1.0f,  1.0f,
                0.5f, -0.5f,  0.5f,  1.0f, 1.0f,  1.0f,
            -0.5f, -0.5f,  0.5f,  1.0f, 1.0f,  1.0f,
            -0.5f, -0.5f, -0.5f,  1.0f, 1.0f,  1.0f,

            -0.5f,  0.5f, -0.5f,  1.0f,  1.0f,  1.0f,
                0.5f,  0.5f, -0.5f,  1.0f,  1.0f,  1.0f,
                0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
                0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
            -0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
            -0.5f,  0.5f, -0.5f,  1.0f,  1.0f,  1.0f
        ];
        ISurface lightBox = new SurfaceTriangle(lightboxVBO);
        MeshNode light = new MeshNode("light", lightBox, lightMaterial);
        mSceneTree.GetRootNode().AddChildSceneNode(light);

        // Add uniforms to the basic material
        mBasicMaterial.AddUniform(new Uniform("uModel", "mat4", null));
        mBasicMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
        mBasicMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));

        //Add uniforms to our light shader as well
        lightMaterial.AddUniform(new Uniform("uModel", "mat4", null));
        lightMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
        lightMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));

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
        //-----------------------------------------------------------------
        // add terrain to the game now 
        //-----------------------------------------------------------------
        // to do: check if need to get rid of multitexture code

        // Simple textured pipeline for terrain (position + UV, no normals)
        Pipeline simpleTexPipeline = new Pipeline("textured_simple",
            "./pipelines/textured_simple/textured_simple.vert",
            "./pipelines/textured_simple/textured_simple.frag");

        IMaterial grassMaterial = new LitTexturedMaterial("textured_simple",
            "./assets/textures/green-grass-background.jpg");
        grassMaterial.AddUniform(new Uniform("uTexture", 0));
        grassMaterial.AddUniform(new Uniform("uModel", "mat4", null));
        grassMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
        grassMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));

        ISurface terrain = new SurfaceTerrain(512, 512,
            "./assets/heightmaps/flat_slight_variation_heightmap.ppm");
        MeshNode m2 = new MeshNode("terrain", terrain, grassMaterial);
        mSceneTree.GetRootNode().AddChildSceneNode(m2);

        setUpLights();

        initCrosshair();

        mPhysicsWorld.setGravity(0.0, -1.0, 0.0);

        // Ground plane
        // note: the plane.urdf determines how far wide the 
        // physics body stretces, currently set to 3000 x and 300 z
        mGroundEntity = mEntityManager.create();
        mPhysicsWorld.addURDF(mGroundEntity, "plane.urdf",
            0, 0, 0,
            0, 0, 0, 1);
        mEntityManager.markPhysics(mGroundEntity);
        TransformComponent planeTc;
        mEntityManager.addTransform(mGroundEntity, planeTc);

        // // Spawn target
        // // to do: perhaps remove this cube entity object
        // mCubeEntity = spawnPhysicsObject(
        //     "cube.urdf",
        //     "./assets/meshes/bunny_centered.obj",
        //     vec3(0.0f, 0.0f, 0.0f),
        //     Quat.init
        // );

        // -------------------------------------------------------
        // Spawn Soldiers
        // -------------------------------------------------------
        spawnSoldierEnemy(vec3(33.0f, 0.0f, -10.0f), Quat.init);
        spawnSoldierEnemy(vec3(0.0f, 0.0f, -30.0f), Quat.init);
        spawnSoldierEnemy(vec3(0.0f, 0.0f, -40.0f), Quat.init);
        spawnSoldierEnemy(vec3(13.0f, 0.0f, -17.0f), Quat.init);
        spawnSoldierEnemy(vec3(23.0f, 0.0f, -17.0f), Quat.init);
        spawnSoldierEnemy(vec3(13.0f, 0.0f, -37.0f), Quat.init);
        spawnSoldierEnemy(vec3(43.0f, 0.0f, 17.0f), Quat.init);

        //Setup Skybox Vertices
        // Create the Skybox shader
        new Pipeline("skybox", "./pipelines/skybox/skybox.vert",
                                    "./pipelines/skybox/skybox.frag");

        float[] skyboxVertices = [

            // positions          
            -1.0f,  1.0f, -1.0f,
            -1.0f, -1.0f, -1.0f,
            1.0f, -1.0f, -1.0f,
            1.0f, -1.0f, -1.0f,
            1.0f,  1.0f, -1.0f,
            -1.0f,  1.0f, -1.0f,

            -1.0f, -1.0f,  1.0f,
            -1.0f, -1.0f, -1.0f,
            -1.0f,  1.0f, -1.0f,
            -1.0f,  1.0f, -1.0f,
            -1.0f,  1.0f,  1.0f,
            -1.0f, -1.0f,  1.0f,

            1.0f, -1.0f, -1.0f,
            1.0f, -1.0f,  1.0f,
            1.0f,  1.0f,  1.0f,
            1.0f,  1.0f,  1.0f,
            1.0f,  1.0f, -1.0f,
            1.0f, -1.0f, -1.0f,

            -1.0f, -1.0f,  1.0f,
            -1.0f,  1.0f,  1.0f,
            1.0f,  1.0f,  1.0f,
            1.0f,  1.0f,  1.0f,
            1.0f, -1.0f,  1.0f,
            -1.0f, -1.0f,  1.0f,

            -1.0f,  1.0f, -1.0f,
            1.0f,  1.0f, -1.0f,
            1.0f,  1.0f,  1.0f,
            1.0f,  1.0f,  1.0f,
            -1.0f,  1.0f,  1.0f,
            -1.0f,  1.0f, -1.0f,

            -1.0f, -1.0f, -1.0f,
            -1.0f, -1.0f,  1.0f,
            1.0f, -1.0f, -1.0f,
            1.0f, -1.0f, -1.0f,
            -1.0f, -1.0f,  1.0f,
            1.0f, -1.0f,  1.0f
        ];


        // skybox VAO
        // to do: check if there is better way to set this up, w curr code set up
        glGenVertexArrays(1, &mSkyBoxVAO);
        glGenBuffers(1, &mSkyBoxVBO);
        glBindVertexArray(mSkyBoxVAO);
        glBindBuffer(GL_ARRAY_BUFFER, mSkyBoxVBO);

        glBufferData(GL_ARRAY_BUFFER, 
        cast(GLsizeiptr)(skyboxVertices.length * float.sizeof),
        skyboxVertices.ptr,
        GL_STATIC_DRAW);

        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * float.sizeof, cast(void*)0);

        string[] faces = [
            "./assets/skybox/right.jpg",
            "./assets/skybox/left.jpg",
            "./assets/skybox/top.jpg",
            "./assets/skybox/bottom.jpg",
            "./assets/skybox/front.jpg",
            "./assets/skybox/back.jpg"
        ];

        string[] faces2 = [
            "./assets/sky_83_cubemap_2k/pz.png", // +X (RIGHT)
            "./assets/sky_83_cubemap_2k/nz.png", // -X (LEFT)
            "./assets/sky_83_cubemap_2k/py.png", // +Y (UP)
            "./assets/sky_83_cubemap_2k/ny.png", // -Y (DOWN)
            "./assets/sky_83_cubemap_2k/px.png", // +Z (FRONT)
            "./assets/sky_83_cubemap_2k/nx.png"  // -Z (BACK)
        ];

        string[] faces3 = [
            "./assets/sky_77_cubemap_2k/pz.png", // +X (RIGHT)
            "./assets/sky_77_cubemap_2k/nz.png", // -X (LEFT)
            "./assets/sky_77_cubemap_2k/py.png", // +Y (UP)
            "./assets/sky_77_cubemap_2k/ny.png", // -Y (DOWN)
            "./assets/sky_77_cubemap_2k/px.png", // +Z (FRONT)
            "./assets/sky_77_cubemap_2k/nx.png"  // -Z (BACK)
        ];

        // https://www.humus.name/index.php?page=Textures&start=24
        string[] faces4 = [
            "./assets/Yokohama3/posx.jpg", // +X (RIGHT)
            "./assets/Yokohama3/negx.jpg", // -X (LEFT)
            "./assets/Yokohama3/posy.jpg", // +Y (UP)
            "./assets/Yokohama3/negy.jpg", // -Y (DOWN)
            "./assets/Yokohama3/posz.jpg", // +Z (FRONT)
            "./assets/Yokohama3/negz.jpg"  // -Z (BACK)
        ];

        string[] grass_terrain_faces = [
            "./assets/Yokohama2/posx.jpg", // +X (RIGHT)
            "./assets/Yokohama2/negx.jpg", // -X (LEFT)
            "./assets/Yokohama2/posy.jpg", // +Y (UP)
            "./assets/Yokohama2/negy.jpg", // -Y (DOWN)
            "./assets/Yokohama2/posz.jpg", // +Z (FRONT)
            "./assets/Yokohama2/negz.jpg"  // -Z (BACK)
        ];

        stbi_set_flip_vertically_on_load(0);
        mCubemapTexture = loadCubemap(faces);

        //Set up the map as the last item
        SetupMap();

        writeln("[tree-test] A before linden block");

        // 30 trees, all at least radius 40 from origin
        foreach (i; 0 .. 160){
            float x, z;

            // keep sampling until outside radius 40
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
    }


    void SetupMap(){

        // === MAP: Build arena from presets ===
        auto presetScene = aiImportFile(
            "./assets/fps_map_kit/uploads_files_3151797_FPS_Modular_Map_Kit_FBX/Fps_Modular_Map_Presets.fbx".toStringz,
            aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs);
        
        if (presetScene !is null){

            IMaterial mapMat = new LitTexturedMaterial("lit_textured",
                "./assets/fps_map_kit/uploads_files_3151797_FPS_Modular_Map_Kit_Map/FPS_Modular_Map_BaseColor.png");
            mapMat.AddUniform(new Uniform("uTexture", 0));
            mapMat.AddUniform(new Uniform("uModel", "mat4", null));
            mapMat.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
            mapMat.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));

            float sc = 0.015f;

            // Helper: recursively add all meshes under a node
            void addNodeMeshes(const(aiNode)* node, const(aiScene)* scene, mat4 parentTransform)
            {
                for (uint i = 0; i < node.mNumMeshes; i++)
                {
                    uint meshIdx = node.mMeshes[i];
                    auto mesh = scene.mMeshes[meshIdx];
                    auto surf = new SurfaceAssimp(cast(aiMesh*)mesh);
                    auto mn = new MeshNode("preset_" ~ meshIdx.to!string, surf, mapMat);
                    mn.mModelMatrix = parentTransform;
                    mSceneTree.GetRootNode().AddChildSceneNode(mn);
                }
                for (uint i = 0; i < node.mNumChildren; i++)
                {
                    addNodeMeshes(node.mChildren[i], scene, parentTransform);
                }
            }

            // Place presets to build an arena
            // Cabin A at center
            addNodeMeshes(presetScene.mRootNode.mChildren[13], presetScene,
                MatrixMakeTranslation(vec3(0.0f, 0.0f, -20.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));

            // Cabin B offset
            addNodeMeshes(presetScene.mRootNode.mChildren[16], presetScene,
                MatrixMakeTranslation(vec3(30.0f, 0.0f, -20.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));

            // Building
            addNodeMeshes(presetScene.mRootNode.mChildren[1], presetScene,
                MatrixMakeTranslation(vec3(15.0f, 0.0f, -40.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));

            // Exterior walls
            addNodeMeshes(presetScene.mRootNode.mChildren[18], presetScene,
                MatrixMakeTranslation(vec3(-10.0f, 0.0f, 0.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));
            addNodeMeshes(presetScene.mRootNode.mChildren[18], presetScene,
                MatrixMakeTranslation(vec3(40.0f, 0.0f, 0.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));

            // Sandbags for cover
            addNodeMeshes(presetScene.mRootNode.mChildren[20], presetScene,
                MatrixMakeTranslation(vec3(10.0f, 0.0f, -10.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));
            addNodeMeshes(presetScene.mRootNode.mChildren[21], presetScene,
                MatrixMakeTranslation(vec3(20.0f, 0.0f, -15.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));
            addNodeMeshes(presetScene.mRootNode.mChildren[22], presetScene,
                MatrixMakeTranslation(vec3(5.0f, 0.0f, -30.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));

            // Corner wall
            addNodeMeshes(presetScene.mRootNode.mChildren[19], presetScene,
                MatrixMakeTranslation(vec3(-10.0f, 0.0f, -40.0f)) * MatrixMakeScale(vec3(sc, sc, sc)));

            writeln("[arena] built from presets");
            aiReleaseImport(presetScene);
        }
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

    void debugLindenAsset(){
        auto scene = aiImportFile(
            "./assets/4-linden-trees-pack-medium-poly/import_1/linden.obj".toStringz,
            aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs
        );

        if (scene is null)
        {
            writeln("[linden-debug] failed to import OBJ");
            return;
        }

        writeln("[linden-debug] mesh count = ", scene.mNumMeshes);
        writeln("[linden-debug] material count = ", scene.mNumMaterials);

        for (uint i = 0; i < scene.mNumMeshes; ++i)
        {
            auto mesh = scene.mMeshes[i];
            writeln("[linden-debug] mesh ", i,
                " materialIndex=", mesh.mMaterialIndex,
                " vertexCount=", mesh.mNumVertices,
                " faceCount=", mesh.mNumFaces);
        }

        writeln("[linden-debug] NODE TREE:");
        debugAssimpNodeTree(scene.mRootNode);

        aiReleaseImport(scene);
    }

    string aiNodeName(const(aiNode)* node){
        if (node is null) return "";

        size_t len = cast(size_t)node.mName.length;
        return cast(string) node.mName.data[0 .. len];
    }

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

            renderNode.mModelMatrix =
                MatrixMakeTranslation(pos) *
                MatrixMakeScale(vec3(1.0f, 1.0f, 1.0f));

            mSceneTree.GetRootNode().AddChildSceneNode(renderNode);
            mEntityManager.addRenderable(eid, renderNode);
        }
    }


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

        writeln("[linden] visual-only entity=", eid, " spawned at ", pos);
        return eid;
    }

    uint spawnTreeVisualOnly(vec3 pos, Quat orient = Quat.init){
        string treeModel = "./assets/free-tree-downloadfbx/source/Tree test.fbx";

        uint eid = mEntityManager.create();

        auto scene = aiImportFile(
            treeModel.toStringz,
            aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs
        );

        if (scene is null)
        {
            writeln("[tree] failed to import ", treeModel);
            return eid;
        }

        TransformComponent tc;
        tc.position = pos;
        tc.rotation = orient;
        mEntityManager.addTransform(eid, tc);

        for (uint i = 0; i < scene.mNumMeshes; ++i)
        {
            auto mesh = scene.mMeshes[i];
            IMaterial mat = (mesh.mMaterialIndex == 1) ? mTreeBarkMaterial : mTreeLeafMaterial;

            auto surf = new SurfaceAssimp(cast(aiMesh*)mesh);
            auto node = new MeshNode("tree_" ~ eid.to!string ~ "_" ~ i.to!string, surf, mat);
          
            node.mModelMatrix = MatrixMakeTranslation(pos) *
            MatrixMakeScale(vec3(1.02f, 1.02f, 1.02f));

            mSceneTree.GetRootNode().AddChildSceneNode(node);
            mEntityManager.addRenderable(eid, node);
        }

        aiReleaseImport(scene);

        writeln("[tree] visual-only entity=", eid, " spawned at ", pos);
        return eid;
    }

    void debugTreeAsset(){

        auto scene = aiImportFile(
            "./assets/free-tree-downloadfbx/source/Tree test.fbx".toStringz,
            aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs
        );

        if (scene is null){
            writeln("[tree-debug] failed to import tree FBX");
            return;
        }

        writeln("[tree-debug] mesh count = ", scene.mNumMeshes);
        writeln("[tree-debug] material count = ", scene.mNumMaterials);

        for (uint i = 0; i < scene.mNumMeshes; ++i){
            auto mesh = scene.mMeshes[i];
            writeln("[tree-debug] mesh ", i,
                " materialIndex=", mesh.mMaterialIndex,
                " vertexCount=", mesh.mNumVertices,
                " faceCount=", mesh.mNumFaces);
        }

        aiReleaseImport(scene);
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

    void attachAudio(AudioEngine* audio){
        mAudio = audio;
        mSystem = mAudio.mSystem;

        loadSounds();
        startBackgroundSound();
    }

    void loadSounds(){

        // load footsteps on gravel
        // to do: check if right mode was set
        auto result = FMOD_System_CreateSound(
            mSystem,
            "./assets/sounds/footsteps_walking_gravel_01_loop.wav".toStringz,
            FMOD_LOOP_NORMAL | FMOD_2D,
            null,
            &mWalkingSound
        );

        writeln("walk sound load result = ", result, " ptr = ", mWalkingSound);

        // load pistol
        // to do: check if right mode was set
        result = FMOD_System_CreateSound(
            mSystem,
            "./assets/sounds/gun_22_pistol_04.wav".toStringz,
            FMOD_LOOP_OFF | FMOD_2D,
            null,
            &mPistolSound
        );

        writeln("pistol sound load result = ", result, " ptr = ", mPistolSound);

        // background sound
        auto r3 = FMOD_System_CreateSound(
            mSystem,
            "./assets/sounds/war_ambience_01_30_loop.wav".toStringz,
            FMOD_LOOP_NORMAL | FMOD_2D | FMOD_CREATESTREAM,
            null,
            &mBackgroundSound
        );

        writeln("background sound load result = ", result, " ptr = ", mBackgroundSound);
    }

    /// CubeMap Setup
    uint loadCubemap(string[] faces){

        uint textureID;
        glGenTextures(1, &textureID);
        glBindTexture(GL_TEXTURE_CUBE_MAP, textureID);

        int width, height, nrChannels;
        for (uint i = 0; i < faces.length; i++){

            //load each of the faces
            auto data = stbi_load(faces[i].toStringz, &width, &height, &nrChannels, 0);

            if (data){
                writeln("[stb] successfully loaded: ", faces[i]);

                glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 
                            0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data
                );
                stbi_image_free(data);
            }
            else{

                writeln("Cubemap tex failed to load.");
                stbi_image_free(data);
            }
        }

        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);

        return textureID;
    }  

    void setUpLights(){

        GLuint shaderProgramID = Pipeline.sPipeline["basic"];
        glUseProgram(shaderProgramID);

        GLint field1 = glGetUniformLocation(shaderProgramID, "uLight1.mColor");
        GLint field2 = glGetUniformLocation(shaderProgramID, "uLight1.mPosition");
        GLint field3 = glGetUniformLocation(shaderProgramID, "uLight1.mAmbientIntensity");
        GLint field4 = glGetUniformLocation(shaderProgramID, "uLight1.mSpecularIntensity");
        GLint field5 = glGetUniformLocation(shaderProgramID, "uLight1.mSpecularExponent");
        GLint field6 = glGetUniformLocation(shaderProgramID, "viewpos");

        foreach(value ; [field1,field2,field3,field4,field5]){
            if(value < 0){
                writeln("Failed to find: ",value);
            }
        }
    
        // Postion light to move in a circle
        static float inc = 0.0f;
        float radius = 560.0f;
        float speed  = 0.1f;   // controls day/night speed
        inc += 0.0002 * speed;

        gLight.mPosition = [
            radius * cos(inc),
            radius,
            radius * sin(inc)
        ];

        glUniform1fv(field1,3,gLight.mColor.ptr);
        glUniform1fv(field2,3,gLight.mPosition.ptr);
        glUniform1f (field3,gLight.mAmbientIntensity);
        glUniform1f (field4,gLight.mSpecularIntensity);
        glUniform1f (field5,gLight.mSpecularExponent);
        glUniform3f(field6, mCamera.mEyePosition.x, mCamera.mEyePosition.y, mCamera.mEyePosition.z);


        if ("lit_textured" in Pipeline.sPipeline)
        {
            GLuint litTexID = Pipeline.sPipeline["lit_textured"];
            glUseProgram(litTexID);

            glUniform3f(glGetUniformLocation(litTexID, "uLightPos"),
                gLight.mPosition[0], gLight.mPosition[1], gLight.mPosition[2]);
            glUniform3f(glGetUniformLocation(litTexID, "viewpos"),
                mCamera.mEyePosition.x, mCamera.mEyePosition.y, mCamera.mEyePosition.z);
        }
    }

    void startBackgroundSound(){
        if (!mBackgroundPlaying && mBackgroundSound !is null) {
            FMOD_System_PlaySound(mSystem, mBackgroundSound, null, 0, &mBackgroundChannel);
            mBackgroundPlaying = true;
        }
    }

    void stopBackgroundSound(){
        if (mBackgroundChannel !is null) {
            FMOD_Channel_Stop(mBackgroundChannel);
            mBackgroundChannel = null;
            mBackgroundPlaying = false;
        }
    }

    void requestShoot(){
        mShootRequested = true;
    }

    void playSound(FMOD_SOUND* s, FMOD_CHANNEL** ch){
        FMOD_System_PlaySound(mAudio.mSystem, s, null, 0, ch);
    }

    void stopSound(FMOD_CHANNEL** ch) {
        if (*ch !is null) {
            FMOD_Channel_Stop(*ch);
            *ch = null;
        }
    }

    private void shoot(){
        vec3 from = mCamera.mEyePosition;
        vec3 dir  = Normalize(mCamera.mForwardVector);
        vec3 to   = from + dir * 1000.0f;

        mShotsFired++;

        // Play gunshot sound
        // to do: perhaps add a clause to stop the shooting just in case
        if (mAudio !is null){
            playSound(mPistolSound, &mPistolSoundChannel);
        }
            
        auto result = mPhysicsWorld.raycast(
            from.x, from.y, from.z,
            to.x, to.y, to.z);

        auto now = Clock.currTime();

        if (result.hit){
            mShotsHit++;
            writeln("[shoot] ", now.toSimpleString(),
                " HIT entity=", result.entityId,
                " at pos=[", result.hitPosition[0],
                ", ", result.hitPosition[1],
                ", ", result.hitPosition[2], "]");

            // Don't destroy the ground
            if (result.entityId != mGroundEntity && result.entityId != 0){
                destroyEntity(result.entityId);
            }
        } else{
            writeln("[shoot] ", now.toSimpleString(), " MISS");
        }

        float accuracy = mShotsFired > 0 ? cast(float)mShotsHit / mShotsFired * 100.0f : 0.0f;
        writeln("[stats] shots=", mShotsFired, " hits=", mShotsHit,
                " accuracy=", accuracy, "%");
    }

    // to do: refactor so that this does not check hard coded pairs but rather loops over every object
    private void checkCollisions(){
        if ((mCubeEntity in mPhysicsWorld.entityToBody) is null) return;
        if ((mGroundEntity in mPhysicsWorld.entityToBody) is null) return;

        b3ContactInformation contactInfo;
        mPhysicsWorld.getContacts(mCubeEntity, mGroundEntity, contactInfo);
    }

    void initCrosshair(){
        // Create the crosshair shader
        new Pipeline("crosshair", "./pipelines/crosshair/crosshair.vert",
                                    "./pipelines/crosshair/crosshair.frag");

        // Crosshair geometry in NDC (-1 to 1 range)
        // Gap in center, 4 line segments forming a + shape
        float size = 0.03f;
        float gap  = 0.008f;

        float[] verts = [
            // Horizontal left
            -size, 0.0f,
            -gap,  0.0f,
            // Horizontal right
                gap,  0.0f,
                size, 0.0f,
            // Vertical top
                0.0f, size,
                0.0f, gap,
            // Vertical bottom
                0.0f, -gap,
                0.0f, -size,
        ];

        glGenVertexArrays(1, &mCrosshairVAO);
        glGenBuffers(1, &mCrosshairVBO);

        glBindVertexArray(mCrosshairVAO);
        glBindBuffer(GL_ARRAY_BUFFER, mCrosshairVBO);
        glBufferData(GL_ARRAY_BUFFER, verts.length * float.sizeof,
                        verts.ptr, GL_STATIC_DRAW);

        // aPos at location 0, 2 floats per vertex
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, null);

        glBindVertexArray(0);
        mCrosshairReady = true;
    }

    /// Fully destroy an entity: physics body + scene tree node + entity manager
    void destroyEntity(uint entityId)
    {
        // 1. Remove from Bullet physics
        if (entityId in mPhysicsWorld.entityToBody){
            mPhysicsWorld.removeBody(entityId);
        }

        if (auto nodes = entityId in mEntityManager.renderables){
            foreach(node; *nodes){
                // Find parent and remove this child
                auto parent = node.GetParentSceneNode();
                if (parent !is null){
                    // Filter this node out of parent's children
                    ISceneNode[] remaining;
                    foreach (child; parent.mChildren){
                        if (child !is node){
                            remaining ~= child;
                        }   
                    }
                    parent.mChildren = remaining;
                }
            }
        }

        // 3. Remove from entity manager
        mEntityManager.destroy(entityId);
        writeln("[destroy] entity=", entityId);
    }
}


// top links:
// https://www.cgtrader.com/3d-models/exterior/other/lowpoly-fps-modular-map-kit
// https://www.cgtrader.com/3d-models/military/gun/fps-animations-single-pistol
// https://www.cgtrader.com/3d-models/military/gun/fps-automatic-rifle-01-animations