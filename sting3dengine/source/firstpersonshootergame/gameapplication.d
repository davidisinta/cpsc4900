module gameapplication;

// standard library files
import std.stdio;
import std.conv;
import std.datetime.systime : Clock;
import std.string : toStringz;
import std.math;

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





        testLoadWithStb();







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

        
        
        //Render 3D stuff
        drawCrosshair();


        //Render the Skybox Last
        // drawSkyBox();

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
    Quat orient = Quat.init)
    {
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


    // void drawSkyBox(){


    //     // draw skybox as last
    //     glDepthFunc(GL_LEQUAL);  // change depth function so depth test passes when values are equal to depth buffer's content

        
    //     // set skybox shader as active shader otherwise you see no skybox
    //     // glUseProgram(Pipeline.sPipeline["skybox"]);
    //     uint skyboxProgram = Pipeline.sPipeline["skybox"];



    //     // view = glm::mat4(glm::mat3(camera.GetViewMatrix())); // remove translation from the view matrix

    //     // remove translation from the view matrix
    //     mat4 view = MatrixMakeIdentity();
    //     mat3 rotOnly = mat3(mCamera.mViewMatrix);

    //     // copy 3x3 rotation into top-left of mat4
    //     view[0]  = rotOnly[0];
    //     view[1]  = rotOnly[1];
    //     view[2]  = rotOnly[2];

    //     view[4]  = rotOnly[3];
    //     view[5]  = rotOnly[4];
    //     view[6]  = rotOnly[5];

    //     view[8]  = rotOnly[6];
    //     view[9]  = rotOnly[7];
    //     view[10] = rotOnly[8];





    //     //set the view and projection matrix
    //     // to do: explain why this is done (in opengl skybox tutorials)
    // //     void setMat4(const std::string &name, const glm::mat4 &mat) const
    // // {
    // //     glUniformMatrix4fv(glGetUniformLocation(ID, name.c_str()), 1, GL_FALSE, &mat[0][0]);
    // // }

    //     // glUniformMatrix4fv(glGetUniformLocation(ID, "view"), 1, GL_FALSE, &view[0][0]);

    //     // glUniformMatrix4fv(glGetUniformLocation(ID, "projection"), 1, GL_FALSE, &mCamera.mProjectionMatrix[0][0]);


    //     glUniformMatrix4fv(
    //     glGetUniformLocation(skyboxProgram, "view"),
    //     1, GL_FALSE, view.DataPtr()
    // );

    // glUniformMatrix4fv(
    //     glGetUniformLocation(skyboxProgram, "projection"),
    //     1, GL_FALSE, mCamera.mProjectionMatrix.DataPtr()
    // );





    //     // skyboxShader.setMat4("view", view);
    //     // skyboxShader.setMat4("projection", projection);


    //     // skybox cube
    //     glBindVertexArray(mSkyBoxVAO);
    //     glActiveTexture(GL_TEXTURE0);
    //     glBindTexture(GL_TEXTURE_CUBE_MAP, mCubemapTexture);
    //     glDrawArrays(GL_TRIANGLES, 0, 36);
    //     glBindVertexArray(0);

    //     glDepthFunc(GL_LESS); // set depth function back to default

    // }


//     void drawSkyBox(){
//     import std.math : cos, sin;

//     glDepthFunc(GL_LEQUAL);

//     uint skyboxProgram = Pipeline.sPipeline["skybox"];
//     glUseProgram(skyboxProgram);

//     float cy = cos(mCamera.mYaw);
//     float sy = sin(mCamera.mYaw);
//     float cp = cos(mCamera.mPitch);
//     float sp = sin(mCamera.mPitch);

//     vec3 f = vec3(cy * cp, sp, sy * cp);
//     f = Normalize(f);
//     vec3 r = Normalize(Cross(f, vec3(0, 1, 0)));
//     vec3 u = Normalize(Cross(r, f));

//     mat4 view = mat4(
//          r.x,  r.y,  r.z,  0.0f,
//          u.x,  u.y,  u.z,  0.0f,
//         -f.x, -f.y, -f.z,  0.0f,
//          0.0f, 0.0f, 0.0f, 1.0f
//     );

//     glUniformMatrix4fv(
//         glGetUniformLocation(skyboxProgram, "view"),
//         1, GL_FALSE, view.DataPtr()
//     );

//     glUniformMatrix4fv(
//         glGetUniformLocation(skyboxProgram, "projection"),
//         1, GL_FALSE, mCamera.mProjectionMatrix.DataPtr()
//     );

//     glUniform1i(glGetUniformLocation(skyboxProgram, "skybox"), 0);

//     glBindVertexArray(mSkyBoxVAO);
//     glActiveTexture(GL_TEXTURE0);
//     glBindTexture(GL_TEXTURE_CUBE_MAP, mCubemapTexture);
//     glDrawArrays(GL_TRIANGLES, 0, 36);
//     glBindVertexArray(0);

//     glDepthFunc(GL_LESS);
// }


void drawSkyBox(){
    glDepthFunc(GL_LEQUAL);

    uint skyboxProgram = Pipeline.sPipeline["skybox"];
    glUseProgram(skyboxProgram);

    mat4 view = mCamera.mViewMatrix;
    view[3]  = 0.0f;
    view[7]  = 0.0f;
    view[11] = 0.0f;

    glUniformMatrix4fv(
        glGetUniformLocation(skyboxProgram, "view"),
        1, GL_FALSE, view.DataPtr());

    glUniformMatrix4fv(
        glGetUniformLocation(skyboxProgram, "projection"),
        1, GL_FALSE, mCamera.mProjectionMatrix.DataPtr());

    glUniform1i(glGetUniformLocation(skyboxProgram, "skybox"), 0);

    glBindVertexArray(mSkyBoxVAO);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_CUBE_MAP, mCubemapTexture);
    glDrawArrays(GL_TRIANGLES, 0, 36);
    glBindVertexArray(0);

    glDepthFunc(GL_LESS);
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

        // Spawn target
        // to do: perhaps remove this cube entity object
        mCubeEntity = spawnPhysicsObject(
            "cube.urdf",
            "./assets/meshes/bunny_centered.obj",
            vec3(0.0f, 0.0f, 0.0f),
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

        //  Another target for testing
        testPos = mCamera.mEyePosition + vec3(0.0f, 20.0f, -24.0f);
        spawnPhysicsObject(
            "cube.urdf",
            "./assets/meshes/bunny_centered.obj",
            testPos,
            Quat.init
        );

        // Another target for testing
        testPos = mCamera.mEyePosition + vec3(10.0f, 0.0f, -24.0f);
        spawnPhysicsObject(
            "cube.urdf",
            "./assets/meshes/bunny_centered.obj",
            testPos,
            Quat.init
        );

        // Another target for testing
        testPos = mCamera.mEyePosition + vec3(20.0f, 0.0f, -54.0f);
        spawnPhysicsObject(
            "cube.urdf",
            "./assets/meshes/bunny_centered.obj",
            testPos,
            Quat.init
        );

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

        MeshNode m2 = new MeshNode("terrain", terrain, mBasicMaterial);
        writeln("[terrain] created MeshNode");

        mSceneTree.GetRootNode().AddChildSceneNode(m2);
        writeln("[terrain] added to scene tree");
        writeln("[terrain] root children count: ", mSceneTree.GetRootNode().mChildren.length);










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

        // glBufferData(GL_ARRAY_BUFFER, 
        // cast(GLsizeiptr)(skyboxVertices.length * float.sizeof),&skyboxVertices, GL_STATIC_DRAW);

        glBufferData(GL_ARRAY_BUFFER, 
        cast(GLsizeiptr)(skyboxVertices.length * float.sizeof),
        skyboxVertices.ptr,   // CORRECT — pointer to actual float data
        GL_STATIC_DRAW);



        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * float.sizeof, cast(void*)0);





        // string[] faces = ["./assets/skybox/back.jpg",
        //     "./assets/skybox/right.jpg",
        //     "./assets/skybox/left.jpg",
        //     "./assets/skybox/front.jpg",
        //     "./assets/skybox/top.jpg",
        //     "./assets/skybox/bottom.jpg"];

        // string[] faces = ["./assets/skybox/back.jpg",
        //     "./assets/skybox/right.jpg",
        //     "./assets/skybox/left.jpg",
        //     "./assets/skybox/front.jpg",
        //     "./assets/skybox/top.jpg",
        //     "./assets/skybox/bottom.jpg"];
        

        string[] faces = [
            "./assets/skybox/right.jpg",
            "./assets/skybox/left.jpg",
            "./assets/skybox/top.jpg",
            "./assets/skybox/bottom.jpg",
            "./assets/skybox/front.jpg",
            "./assets/skybox/back.jpg"
        ];
        

        stbi_set_flip_vertically_on_load(0);
        mCubemapTexture = loadCubemap(faces);








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




            // auto data = stbi_load("./assets/skybox/back.jpg".toStringz, &w, &h, &channels, 0);
        // if (data !is null)
        // {
        //     writeln("[stb] skybox back.jpg: ", w, "x", h, " channels=", channels);
        //     stbi_image_free(data);
        // }







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


    void testLoadWithStb(){

        int w, h, channels;
        stbi_set_flip_vertically_on_load(1);
        auto data = stbi_load("./assets/skybox/back.jpg".toStringz, &w, &h, &channels, 0);

        if (data !is null){
            writeln("[stb] skybox back.jpg: ", w, "x", h, " channels=", channels);
            stbi_image_free(data);
        }

        else{
            writeln("[stb] failed to load");
        }       
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

        //rotate the light in sunlike manner
        // gLight.mPosition = [
        //     radius * cos(inc),
        //     radius * sin(inc),
        //     radius * 0.2f
        // ];

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
