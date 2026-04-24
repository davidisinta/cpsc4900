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
import level_builder;
import audiocontroller;
import materialregistry;
import resourcemanager;
import animation;
import viewweapon;

// Third-party libraries
import bindbc.sdl;
import bindbc.opengl;

class GameApplication : IGame{
    // Refs to engine systems
    PhysicsWorld mPhysicsWorld;
    EntityManager mEntityManager;
    Camera mCamera;
    SceneTree mSceneTree;
    // IMaterial mBasicMaterial;
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
    LevelBuilder mLevelBuilder;



    //Shooting elements
    int mCurrentAmmo = 30;
    int mMaxAmmo = 30;
    double mRoundTimer = 120.0;
    ViewWeapon mViewWeapon;

    //Game Materials

    /// sound specific elements
    AudioController mAudioController;


    MaterialRegistry mMaterialRegistry;

    ResourceManager mResourceManager;

    this(string name, PhysicsWorld physics, EntityManager em, Camera cam, SceneTree tree, IMaterial mat){
        this.gameName = name;
        mPhysicsWorld = physics;
        mEntityManager = em;
        mCamera = cam;
        mSceneTree = tree;
        mGui = new GameGUI("topshoota-game-gui");
        mAudioController = new AudioController();

        mMaterialRegistry = new MaterialRegistry(cam);
        mMaterialRegistry.setup();

        mResourceManager = new ResourceManager();

        mLevelBuilder = new LevelBuilder(cam, tree, em, physics, mMaterialRegistry, mResourceManager);
    }

    override void Input(){
        if (mShootRequested){
            shoot();
            mShootRequested = false;
        }
    }

    override void Update(double frameDt){
        checkCollisions();
        
        // Round timer
        mRoundTimer -= frameDt;
        if (mRoundTimer < 0) mRoundTimer = 0;

        // Update GUI state
        mGui.kills = mShotsHit;
        mGui.accuracy = mShotsFired > 0 ? cast(float)mShotsHit / mShotsFired * 100.0f : 0.0f;
        mGui.currentAmmo = mCurrentAmmo;
        mGui.maxAmmo = mMaxAmmo;
        mGui.roundTimeSeconds = cast(int)mRoundTimer;


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

        // Update view weapon animation
        mViewWeapon.update(frameDt);
    }

    void Render(){

        // Render view weapon
        mViewWeapon.render();

        //Render Cross Hair as it is like a GUI element
        drawCrosshair();

        //Render the games GUI last
        mGui.Render();
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

    void printSpawnPoint(string type)
    {
        auto pos = mCamera.mEyePosition;
        writeln("[spawn-marker] ", type, " at <", pos.x, ",", pos.y, ",", pos.z, ">");
    }

    //Setup the Scene for the Game
    override void Setup(){
        
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

        //Let Level Builder Set up the map
        mLevelBuilder.SetupMap();

        //Stress testing for Frustum culling
        // spawnStressTest(300);


        // // Test skeleton loading
        
        // auto glockScene = aiImportFile(
        //     "./assets/weapons/glock/Glock.fbx".toStringz,
        //     aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs);
        // if (glockScene !is null)
        // {
        //     Skeleton skel;
        //     skel.loadFromScene(glockScene);
        //     skel.printHierarchy();
        //     aiReleaseImport(glockScene);
        // }


        // // Test animation clip loading
        // AnimationClip idleClip;
        // idleClip.loadFromFile("./assets/weapons/glock/Glock_Idle.fbx", "idle");
        // idleClip.printSummary();

        // AnimationClip fireClip;
        // fireClip.loadFromFile("./assets/weapons/glock/Glock_Fire1.fbx", "fire");
        // fireClip.printSummary();

        // AnimationClip reloadClip;
        // reloadClip.loadFromFile("./assets/weapons/glock/Glock_Reload.fbx", "reload");
        // reloadClip.printSummary();


        // // Test full animation pipeline
        // import animation;
        // auto glockScene = aiImportFile(
        //     "./assets/weapons/glock/Glock.fbx".toStringz,
        //     aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs);
        // if (glockScene !is null)
        // {
        //     Skeleton skel;
        //     skel.loadFromScene(glockScene);
        //     aiReleaseImport(glockScene);

        //     AnimationClip idleClip;
        //     idleClip.loadFromFile("./assets/weapons/glock/Glock_Idle.fbx", "idle");

        //     Animator anim;
        //     anim.init(&skel);
        //     anim.play(&idleClip, true);

        //     // Simulate 10 frames at 60fps
        //     for (int i = 0; i < 10; i++)
        //     {
        //         anim.update(1.0 / 60.0);
                
        //         // Print muzzle bone world position as sanity check
        //         mat4 muzzle = anim.getBoneWorldMatrix("Muzzle");
        //         writeln("[anim] frame ", i,
        //                 " muzzle pos=(", muzzle[3], ", ", muzzle[7], ", ", muzzle[11], ")",
        //                 " time=", anim.mCurrentTime);
        //     }
        // }


// Test skinned mesh loading
        // import skinnedmesh;
        // auto glockScene = aiImportFile(
        //     "./assets/weapons/glock/Glock.fbx".toStringz,
        //     aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs);
        // if (glockScene !is null)
        // {
        //     auto armsMesh = glockScene.mMeshes[1];
        //     writeln("[skintest] ArmsMale bones=", armsMesh.mNumBones,
        //             " verts=", armsMesh.mNumVertices);

        //     // Check first bone's data
        //     auto bone0 = armsMesh.mBones[0];
        //     writeln("[skintest] bone0 ptr=", bone0);
        //     writeln("[skintest] bone0 name length=", bone0.mName.length);
        //     writeln("[skintest] bone0 name='", bone0.mName.data[0 .. bone0.mName.length], "'");
        //     writeln("[skintest] bone0 numWeights=", bone0.mNumWeights);
        //     writeln("[skintest] bone0 weights ptr=", bone0.mWeights);

        //     if (bone0.mNumWeights > 0 && bone0.mWeights !is null)
        //     {
        //         writeln("[skintest] bone0 weight[0] vertexId=", bone0.mWeights[0].mVertexId,
        //                 " weight=", bone0.mWeights[0].mWeight);
        //     }

        //     writeln("[skintest] bone0 offsetMatrix a1=", bone0.mOffsetMatrix.a1);

        //     aiReleaseImport(glockScene);
        // }

        // import skinnedmesh;
        // auto glockScene = aiImportFile(
        //     "./assets/weapons/glock/Glock.fbx".toStringz,
        //     aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs);
        // if (glockScene !is null)
        // {
        //     auto armsMesh = glockScene.mMeshes[1];


        // // Check bone 4 which has weights
        //     auto bone4 = armsMesh.mBones[4];
        //     writeln("[skintest] bone4 name='", bone4.mName.data[0 .. bone4.mName.length], "'");
        //     writeln("[skintest] bone4 numWeights=", bone4.mNumWeights);
        //     writeln("[skintest] bone4 weights ptr=", bone4.mWeights);

        //     if (bone4.mNumWeights > 0 && bone4.mWeights !is null)
        //     {
        //         writeln("[skintest] bone4 weight[0] vertexId=", bone4.mWeights[0].mVertexId,
        //                 " weight=", bone4.mWeights[0].mWeight);
        //         writeln("[skintest] bone4 weight[1] vertexId=", bone4.mWeights[1].mVertexId,
        //                 " weight=", bone4.mWeights[1].mWeight);
        //     }

        //     writeln("[skintest] bone4 offsetMatrix:");
        //     writeln("[skintest]   ", bone4.mOffsetMatrix.a1, " ", bone4.mOffsetMatrix.a2, " ", bone4.mOffsetMatrix.a3, " ", bone4.mOffsetMatrix.a4);
        //     writeln("[skintest]   ", bone4.mOffsetMatrix.b1, " ", bone4.mOffsetMatrix.b2, " ", bone4.mOffsetMatrix.b3, " ", bone4.mOffsetMatrix.b4);
        //     writeln("[skintest]   ", bone4.mOffsetMatrix.c1, " ", bone4.mOffsetMatrix.c2, " ", bone4.mOffsetMatrix.c3, " ", bone4.mOffsetMatrix.c4);
        //     writeln("[skintest]   ", bone4.mOffsetMatrix.d1, " ", bone4.mOffsetMatrix.d2, " ", bone4.mOffsetMatrix.d3, " ", bone4.mOffsetMatrix.d4);


        //     auto skinnedSurf = new SkinnedSurface(cast(aiMesh*)armsMesh);
        //     writeln("[skintest] SUCCESS");}



        // Setup view weapon
        // mViewWeapon = new ViewWeapon();
        // // mViewWeapon.init(mCamera, 
        // //     "./assets/weapons/glock/Glock.fbx",
        // //     "./assets/weapons/glock/textures/Glock_BaseColor.png");

        // mViewWeapon.init(mCamera, 
        //     "./assets/weapons/knife/Knife.fbx",
        //     "./assets/modern_soldier/textures/material_0_baseColor.jpeg");

        // // Load animation clips
        // mViewWeapon.loadClip("./assets/weapons/knife/Knife_Idle.fbx", "idle", true);

        
        // // mViewWeapon.loadClip("./assets/weapons/glock/Glock_Fire1.fbx", "fire");
        // // mViewWeapon.loadClip("./assets/weapons/glock/Glock_Reload.fbx", "reload");
        // mViewWeapon.loadClip("./assets/weapons/knife/Knife_Draw.fbx", "draw");
        // mViewWeapon.loadClip("./assets/weapons/knife/Knife_Walk.fbx", "walk");

        // Register collision boxes from arena pieces
        // Walls
        mCamera.addCollisionBox(-11.657f, -0.507f, -8.343f, 0.507f);   // wall1
        mCamera.addCollisionBox(38.343f, -0.507f, 41.657f, 0.507f);    // wall2
        // Sandbags
        mCamera.addCollisionBox(7.519f, -10.527f, 12.481f, -9.473f);   // sandbag1
        mCamera.addCollisionBox(16.813f, -15.541f, 23.187f, -14.459f); // sandbag2
        mCamera.addCollisionBox(2.377f, -31.364f, 7.623f, -28.636f);   // sandbag3
        // Corner wall
        mCamera.addCollisionBox(-11.972f, -41.964f, -8.028f, -38.036f); // cornerwall
        // Cabins and building (estimated — we'll refine)
        mCamera.addCollisionBox(-5.0f, -25.0f, 5.0f, -15.0f);    // cabin1 at (0,0,-20)
        mCamera.addCollisionBox(25.0f, -25.0f, 35.0f, -15.0f);   // cabin2 at (30,0,-20)
        mCamera.addCollisionBox(10.0f, -47.0f, 20.0f, -33.0f);   // building at (15,0,-40)
        writeln("[collision] registered ", mCamera.mCollisionBoxes.length, " collision boxes");

        mViewWeapon = new ViewWeapon();
        mViewWeapon.init(mCamera, 
            "./assets/weapons/glock/Glock.fbx",
            "./assets/modern_soldier/textures/material_0_baseColor.jpeg");

        mViewWeapon.loadClip("./assets/weapons/glock/Glock_Idle.fbx", "idle", true);
        mViewWeapon.loadClip("./assets/weapons/glock/Glock_Fire1.fbx", "fire");
        mViewWeapon.loadClip("./assets/weapons/glock/Glock_Reload.fbx", "reload");
        mViewWeapon.loadClip("./assets/weapons/glock/Glock_Draw.fbx", "draw");
        mViewWeapon.loadClip("./assets/weapons/glock/Glock_Walk.fbx", "walk");





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

    void attachAudio(AudioEngine* audio){
        mAudio = audio;
        mAudioController.attach(audio);
        mAudioController.startBackground();
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
   
    void requestShoot(){
        mShootRequested = true;
    }

    void reload(){
        mCurrentAmmo = mMaxAmmo;
        writeln("[reload] ammo restored to ", mMaxAmmo);
        mViewWeapon.playReload();

    }


    private void shoot(){
        // Ammo check
        if (mCurrentAmmo <= 0)
        {
            writeln("[shoot] EMPTY — press R to reload");
            return;
        }
        mCurrentAmmo--;

        vec3 from = mCamera.mEyePosition;
        vec3 dir  = Normalize(mCamera.mForwardVector);

        // Weapon spread
        float spread = 0.02f;
        dir.x += uniform(-spread, spread);
        dir.y += uniform(-spread, spread);
        dir.z += uniform(-spread, spread);
        dir = Normalize(dir);

        vec3 to = from + dir * 1000.0f;

        mShotsFired++;

        mAudioController.playGunshot();
        mViewWeapon.playFire();

            
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



// to do: look at architecture from 2D game and try to get nifty game strategies here
