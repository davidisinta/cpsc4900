module gameapplication;

// standard library files
import std.stdio;
import std.conv;
import std.datetime.systime : Clock;

// project files
import enginecore;
import linear;
import physics;
import geometry;
import materials;

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
        mCubeEntity = spawnPhysicsObject(
            "cube.urdf",
            "./assets/meshes/bunny_centered.obj",
            vec3(0.0f, 10.0f, 0.0f),
            Quat.init
        );

        // Another target for testing
        vec3 testPos = mCamera.mEyePosition + vec3(0.0f, 0.0f, -4.0f);
        spawnPhysicsObject(
            "cube.urdf",
            "./assets/meshes/bunny_centered.obj",
            testPos,
            Quat.init
        );

        // Another target for testing
        testPos = mCamera.mEyePosition + vec3(0.0f, 0.0f, -14.0f);
        spawnPhysicsObject(
            "cube.urdf",
            "./assets/meshes/bunny_centered.obj",
            testPos,
            Quat.init
        );

         // Another target for testing
        testPos = mCamera.mEyePosition + vec3(0.0f, 0.0f, -24.0f);
        spawnPhysicsObject(
            "cube.urdf",
            "./assets/meshes/bunny_centered.obj",
            testPos,
            Quat.init
        );


         // Another target for testing
        testPos = mCamera.mEyePosition + vec3(10.0f, 0.0f, -4.0f);
        spawnPhysicsObject(
            "cube.urdf",
            "./assets/meshes/bunny_centered.obj",
            testPos,
            Quat.init
        );

         // Another target for testing
        testPos = mCamera.mEyePosition + vec3(20.0f, 0.0f, -4.0f);
        spawnPhysicsObject(
            "cube.urdf",
            "./assets/meshes/bunny_centered.obj",
            testPos,
            Quat.init
        );
    }

    override void HandleInput(){
        if (mShootRequested)
        {
            shoot();
            mShootRequested = false;
        }
    }

    override void Update(double frameDt){
        checkCollisions();
    }

    override void RenderOverlay(){
        drawCrosshair();
    }

    void requestShoot(){
        mShootRequested = true;
    }

    private void shoot(){
        vec3 from = mCamera.mEyePosition;
        vec3 dir  = mCamera.mForwardVector * -1.0f;
        dir = Normalize(dir);
        vec3 to   = from + dir * 1000.0f;

        mShotsFired++;

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
        } else{
            writeln("[shoot] ", now.toSimpleString(), " MISS");
        }

        float accuracy = mShotsFired > 0 ? cast(float)mShotsHit / mShotsFired * 100.0f : 0.0f;
        writeln("[stats] shots=", mShotsFired, " hits=", mShotsHit,
                " accuracy=", accuracy, "%");
    }

    private void checkCollisions(){
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
}
