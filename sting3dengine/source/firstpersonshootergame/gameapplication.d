module gameapplication;

// standard library files
import std.stdio;
import std.conv;
import std.datetime.systime : Clock;
import std.string : toStringz;

// project files
import enginecore;
import linear;
import physics;
import geometry;
import materials;
import audiosubsystem;
import assimp;

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
        string objPath,
        vec3 pos,
        Quat orient = Quat.init){
        // Allocate entity
        uint eid = mEntityManager.create();

        // Physics side: load URDF into Bullet
        mPhysicsWorld.addURDF(eid, urdfPath,
            pos.x, pos.y, pos.z,
            orient.x, orient.y, orient.z, orient.w);
        mEntityManager.markPhysics(eid);

        // Render side: load .obj mesh, attach to scene tree
        ISurface surf = new SurfaceOBJ(objPath);
        MeshNode node = new MeshNode("entity_" ~ eid.to!string, surf, mBasicMaterial);
        mSceneTree.GetRootNode().AddChildSceneNode(node);

        // Register in EntityManager
        TransformComponent tc;
        tc.position = pos;
        tc.rotation = orient;
        mEntityManager.addTransform(eid, tc);
        mEntityManager.addRenderable(eid, node);

        // Set initial model matrix
        node.mModelMatrix = tc.toModelMatrix();

        writeln("[spawn] entity=", eid, " urdf=", urdfPath, " obj=", objPath, " pos=", pos);
        return eid;
    }


    void drawCrosshair(){
        if (!mCrosshairReady) return;

        glDisable(GL_DEPTH_TEST);

        glUseProgram(Pipeline.sPipeline["crosshair"]);
        glBindVertexArray(mCrosshairVAO);
        glLineWidth(2.0f);
        glDrawArrays(GL_LINES, 0, 8);  // 4 line segments = 8 vertices
        glBindVertexArray(0);

        glEnable(GL_DEPTH_TEST);
    }

    override void Setup(){

        initCrosshair();

        mPhysicsWorld.setGravity(0.0, -1.0, 0.0);

        // Ground plane
        mGroundEntity = mEntityManager.create();
        mPhysicsWorld.addURDF(mGroundEntity, "plane.urdf",
            0, 0, 0,
            0, 0, 0, 1);
        mEntityManager.markPhysics(mGroundEntity);
        TransformComponent planeTc;
        mEntityManager.addTransform(mGroundEntity, planeTc);

        // Spawn target
        // to do: perhaps remove this cube entity object
        // mCubeEntity = spawnPhysicsObject(
        //     "cube.urdf",
        //     "./assets/meshes/bunny_centered.obj",
        //     vec3(0.0f, 0.0f, 0.0f),
        //     Quat.init
        // );

        // // Another target for testing
        // vec3 testPos = mCamera.mEyePosition + vec3(0.0f, 0.0f, -4.0f);
        // spawnPhysicsObject(
        //     "cube.urdf",
        //     "./assets/meshes/bunny_centered.obj",
        //     testPos,
        //     Quat.init
        // );

        // Another target for testing
        // testPos = mCamera.mEyePosition + vec3(0.0f, 0.0f, -14.0f);
        // spawnPhysicsObject(
        //     "cube.urdf",
        //     "./assets/meshes/bunny_centered.obj",
        //     testPos,
        //     Quat.init
        // );

         // Another target for testing
        // testPos = mCamera.mEyePosition + vec3(0.0f, 0.0f, -24.0f);
        // spawnPhysicsObject(
        //     "cube.urdf",
        //     "./assets/meshes/bunny_centered.obj",
        //     testPos,
        //     Quat.init
        // );


         // Another target for testing
        // testPos = mCamera.mEyePosition + vec3(10.0f, 0.0f, -24.0f);
        // spawnPhysicsObject(
        //     "cube.urdf",
        //     "./assets/meshes/bunny_centered.obj",
        //     testPos,
        //     Quat.init
        // );

         // Another target for testing
        // testPos = mCamera.mEyePosition + vec3(20.0f, 0.0f, -54.0f);
        // spawnPhysicsObject(
        //     "cube.urdf",
        //     "./assets/meshes/bunny_centered.obj",
        //     testPos,
        //     Quat.init
        // );



        // add assimp loaded model
        // import assimp;
        auto bunnyModel = new Model("./assets/meshes/bunny_centered.obj");
        auto bunnyNodes = bunnyModel.addToScene(mSceneTree, mBasicMaterial, "assimp_bunny");
        foreach (node; bunnyNodes)
            node.mModelMatrix = MatrixMakeTranslation(vec3(5.0f, 0.5f, 0.0f));
        writeln("[test] assimp bunny loaded with ", bunnyNodes.length, " meshes");













        //-----------------------------------------------------------------
        // add terrain to the game now 
        //-----------------------------------------------------------------
        Pipeline texturePipeline = new Pipeline("multiTexturePipeline","./pipelines/multitexture/basic.vert","./pipelines/multitexture/basic.frag");

        IMaterial multiTextureMaterial = new MultiTextureMaterial("multiTexturePipeline","./assets/textures/sand.ppm","./assets/textures/grass.ppm","./assets/textures/dirt.ppm","./assets/textures/snow.ppm");
        multiTextureMaterial.AddUniform(new Uniform("sampler1", 0));
        multiTextureMaterial.AddUniform(new Uniform("sampler2", 1));
        multiTextureMaterial.AddUniform(new Uniform("sampler3", 2));
        multiTextureMaterial.AddUniform(new Uniform("sampler4", 3));
        multiTextureMaterial.AddUniform(new Uniform("uModel", "mat4", null));
        multiTextureMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
        multiTextureMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));

        ISurface terrain = new SurfaceTerrain(512,512,"./assets/heightmaps/flat_slight_variation_heightmap.ppm"); 
        writeln("[terrain] created SurfaceTerrain");

        // MeshNode m2 = new MeshNode("terrain", terrain, multiTextureMaterial);
        MeshNode m2 = new MeshNode("terrain", terrain, mBasicMaterial);
        writeln("[terrain] created MeshNode");

        mSceneTree.GetRootNode().AddChildSceneNode(m2);
        writeln("[terrain] added to scene tree");
        writeln("[terrain] root children count: ", mSceneTree.GetRootNode().mChildren.length);




        // Test Assimp linkage
        loadAssimp();



    }

    void loadAssimp(){
        // import assimp;
        import std.string : toStringz, fromStringz;
        auto testScene = aiImportFile("./assets/meshes/bunny_centered.obj".toStringz,
                                       aiProcess_Triangulate | aiProcess_GenNormals);
        if (testScene is null)
        {
            writeln("[assimp] ERROR: ", fromStringz(aiGetErrorString()));
        }
        else
        {
            auto mesh = testScene.mMeshes[0];
            writeln("[assimp] vertices: ", mesh.mNumVertices, " faces: ", mesh.mNumFaces);

            // Print first 3 vertices
            for (int i = 0; i < 3; i++)
            {
                auto v = mesh.mVertices[i];
                auto n = mesh.mNormals[i];
                writeln("[assimp] v", i, " pos=(", v.x, ", ", v.y, ", ", v.z,
                        ") normal=(", n.x, ", ", n.y, ", ", n.z, ")");
            }

            // Print first face indices
            auto face = mesh.mFaces[0];
            writeln("[assimp] face0: indices=", face.mNumIndices,
                    " [", face.mIndices[0], ", ", face.mIndices[1], ", ", face.mIndices[2], "]");

            aiReleaseImport(testScene);
        }
    }


    void attachAudio(AudioEngine* audio){
        mAudio = audio;
        mSystem = mAudio.mSystem;


        loadSounds();

        //not to be called in input update/render
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

    override void HandleInput(){

        if (mShootRequested){
            shoot();
            mShootRequested = false;
        }
    }

    override void Update(double frameDt){
        checkCollisions();

        MeshNode m2 = cast(MeshNode)mSceneTree.FindNode("terrain");
        if (m2 is null) {
            writeln("[terrain] ERROR: terrain node not found in scene tree!");
        } else {
            m2.mModelMatrix = MatrixMakeTranslation(vec3(-256.0f, 0.0f, -256.0f));
        }
    }

    override void RenderOverlay(){
        drawCrosshair();
    }

    void requestShoot(){
        mShootRequested = true;
    }

    void playSound(FMOD_SOUND* s,
    FMOD_CHANNEL** ch){
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

        if (result.hit)
        {
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
        if (entityId in mPhysicsWorld.entityToBody)
        {
            mPhysicsWorld.removeBody(entityId);
        }

        // 2. Remove MeshNode from scene tree
        if (auto node = entityId in mEntityManager.renderables)
        {
            // Find parent and remove this child
            auto parent = node.GetParentSceneNode();
            if (parent !is null)
            {
                // Filter this node out of parent's children
                ISceneNode[] remaining;
                foreach (child; parent.mChildren)
                {
                    if (child !is *node)
                        remaining ~= child;
                }
                parent.mChildren = remaining;
            }
        }

        // 3. Remove from entity manager
        mEntityManager.destroy(entityId);

        writeln("[destroy] entity=", entityId);
    }
}
