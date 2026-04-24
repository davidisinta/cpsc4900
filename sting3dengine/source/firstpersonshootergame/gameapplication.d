// module gameapplication;

// // standard library files
// import std.stdio;
// import std.conv;
// import std.datetime.systime : Clock;
// import std.string : toStringz, fromStringz;
// import std.math;
// import std.random : uniform;

// // project files
// import enginecore;
// import linear;
// import physics;
// import geometry;
// import materials;
// import audiosubsystem;
// import assimp;
// import editor;
// import gamegui;
// import light;
// import level_builder;
// import audiocontroller;
// import materialregistry;
// import resourcemanager;
// import animation;
// import viewweapon;
// import collisioneditor;
// import challenge_state;
// import leaderboard;

// // Third-party libraries
// import bindbc.sdl;
// import bindbc.opengl;

// class GameApplication : IGame{
//     // Refs to engine systems
//     PhysicsWorld mPhysicsWorld;
//     EntityManager mEntityManager;
//     Camera mCamera;
//     SceneTree mSceneTree;
//     // IMaterial mBasicMaterial;
//     AudioEngine* mAudio;

//     // Game-specific state
//     string gameName;
//     uint mGroundEntity;
//     uint mCubeEntity;
//     int mShotsFired;
//     int mShotsHit;
//     bool mShootRequested;
//     GLuint mCrosshairVAO;
//     GLuint mCrosshairVBO;
//     bool mCrosshairReady = false;
//     GameGUI mGui;
//     Light gLight;
//     GLuint mSkyBoxVAO;
//     GLuint  mSkyBoxVBO;
//     GLuint mCubemapTexture;
//     LevelBuilder mLevelBuilder;
    



//     //Shooting elements
//     int mCurrentAmmo = 30;
//     int mMaxAmmo = 30;
//     double mRoundTimer = 120.0;
//     // ViewWeapon mViewWeapon;


//     ChallengePhase mPhase = ChallengePhase.Intro;
//     LeaderboardStore mLeaderboard;
//     ChallengeTarget[] mChallengeTargets;
//     bool[uint] mActiveTargetIds;

//     string mPlayerName = "Player";
//     int mScore = 0;
//     double mTargetSpawnAccumulator = 0.0;

//     bool mIsMoving = false;
//     bool mIsSprinting = false;
//     float mCurrentSpread = 0.0f;

//     //Game Materials

//     /// sound specific elements
//     AudioController mAudioController;
//     CollisionEditor mCollisionEditor;


//     MaterialRegistry mMaterialRegistry;

//     ResourceManager mResourceManager;

//     this(string name, PhysicsWorld physics, EntityManager em, Camera cam, SceneTree tree, IMaterial mat){
//         this.gameName = name;
//         mPhysicsWorld = physics;
//         mEntityManager = em;
//         mCamera = cam;
//         mSceneTree = tree;
//         mGui = new GameGUI("topshoota-game-gui");
//         mAudioController = new AudioController();

//         mMaterialRegistry = new MaterialRegistry(cam);
//         mMaterialRegistry.setup();

//         mResourceManager = new ResourceManager();

//         mLevelBuilder = new LevelBuilder(cam, tree, em, physics, mMaterialRegistry, mResourceManager);


//         mLeaderboard = new LeaderboardStore("./data/topshoota_leaderboard.txt");
//         mGui.leaderboard = mLeaderboard.top10();
//         mGui.phase = mPhase;
//     }

//     // override void Input(){
//     //     if (mShootRequested){
//     //         shoot();
//     //         mShootRequested = false;
//     //     }
//     // }

//     override void Input()
// {
//     if (mGui.consumeStartPressed())
//         startChallengeRound();

//     if (mGui.consumeRestartPressed())
//     {
//         mPhase = ChallengePhase.Intro;
//         mGui.phase = mPhase;
//         mGui.leaderboard = mLeaderboard.top10();
//         // SDL_SetRelativeMouseMode(SDL_FALSE);
//         return;
//     }

//     const(ubyte)* keys = SDL_GetKeyboardState(null);
//     mIsMoving =
//         keys[SDL_SCANCODE_W] != 0 ||
//         keys[SDL_SCANCODE_A] != 0 ||
//         keys[SDL_SCANCODE_S] != 0 ||
//         keys[SDL_SCANCODE_D] != 0;

//     mIsSprinting = mIsMoving &&
//         (keys[SDL_SCANCODE_LSHIFT] != 0 || keys[SDL_SCANCODE_RSHIFT] != 0);

//     if (mPhase != ChallengePhase.Live)
//     {
//         mShootRequested = false;
//         return;
//     }

//     if (mShootRequested)
//     {
//         shoot();
//         mShootRequested = false;
//     }
// }






//     override void Update(double frameDt){
//         checkCollisions();

//     if (mPhase == ChallengePhase.Live)
//     {
//         mRoundTimer -= frameDt;
//         if (mRoundTimer < 0)
//             mRoundTimer = 0;

//         mTargetSpawnAccumulator += frameDt;
//         while (mTargetSpawnAccumulator >= kTargetSpawnInterval)
//         {
//             mTargetSpawnAccumulator -= kTargetSpawnInterval;
//             spawnFallingTarget();
//         }

//         updateChallengeTargets(frameDt);

//         if (mRoundTimer <= 0)
//             finishChallengeRound();
//     }

//     mCurrentSpread = computeWeaponSpread();

//     mGui.phase = mPhase;
//     mGui.score = mScore;
//     mGui.finalScore = mScore;
//     mGui.shotsFired = mShotsFired;
//     mGui.shotsHit = mShotsHit;
//     mGui.playerName = mPlayerName;
//     mGui.accuracy = mShotsFired > 0 ? cast(float)mShotsHit / mShotsFired * 100.0f : 0.0f;
//     mGui.currentAmmo = mCurrentAmmo;
//     mGui.maxAmmo = mMaxAmmo;
//     mGui.roundTimeSeconds = cast(int)mRoundTimer;
//     mGui.leaderboard = mLeaderboard.top10();
//     mGui.movementState = mIsSprinting ? "SPRINTING" : (mIsMoving ? "MOVING" : "STOPPED");
//     mGui.currentSpread = mCurrentSpread;


//         //update our light object
//         MeshNode lightNode = cast(MeshNode)mSceneTree.FindNode("light");

//         if (lightNode !is null){
//             GLfloat x = gLight.mPosition[0];
//             GLfloat y = gLight.mPosition[1];
//             GLfloat z = gLight.mPosition[2];
            
//             //move the lightbox that follows the point light and scale it to 15
//             lightNode.mModelMatrix = MatrixMakeTranslation(vec3(x, y, z))
//                                     * MatrixMakeScale(vec3(15.0f, 15.0f, 15.0f));
//         }

//         MeshNode m2 = cast(MeshNode)mSceneTree.FindNode("terrain");
//         if (m2 is null) {
//             writeln("[terrain] ERROR: terrain node not found in scene tree!");
//         } else {
//             m2.mModelMatrix = MatrixMakeTranslation(vec3(-256.0f, 0.0f, -256.0f));
//         }

//         // Update view weapon animation
//         // mViewWeapon.update(frameDt);
//     }

//     // void Render(){

//     //     // Render view weapon
//     //     // mViewWeapon.render();

//     //     mCollisionEditor.render();

//     //     //Render Cross Hair as it is like a GUI element
//     //     drawCrosshair();

//     //     //Render the games GUI last
//     //     mGui.Render();
//     // }


//     void Render()
// {
//     if (mPhase == ChallengePhase.Live)
//     {
//         if (mCollisionEditor !is null)
//             mCollisionEditor.render();
//         drawCrosshair();
//     }

//     mGui.Render();
// }


//     void drawCrosshair(){
//         if (!mCrosshairReady) return;

//         glDisable(GL_DEPTH_TEST);

//         glUseProgram(Pipeline.sPipeline["crosshair"]);
//         glBindVertexArray(mCrosshairVAO);
//         glLineWidth(2.0f);
//         glDrawArrays(GL_LINES, 0, 8);
//         glBindVertexArray(0);

//         glEnable(GL_DEPTH_TEST);
//     }

//     void printSpawnPoint(string type)
//     {
//         auto pos = mCamera.mEyePosition;
//         writeln("[spawn-marker] ", type, " at <", pos.x, ",", pos.y, ",", pos.z, ">");
//     }

//     //Setup the Scene for the Game
//     override void Setup(){
        
//         setUpLights();

//         initCrosshair();

//         mPhysicsWorld.setGravity(0.0, -1.0, 0.0);

//         // Ground plane
//         // note: the plane.urdf determines how far wide the 
//         // physics body stretces, currently set to 3000 x and 300 z
//         mGroundEntity = mEntityManager.create();
//         mPhysicsWorld.addURDF(mGroundEntity, "plane.urdf",
//             0, 0, 0,
//             0, 0, 0, 1);
//         mEntityManager.markPhysics(mGroundEntity);
//         TransformComponent planeTc;
//         mEntityManager.addTransform(mGroundEntity, planeTc);

//         //Let Level Builder Set up the map
//         // mLevelBuilder.SetupMap();

//         mLevelBuilder.SetupMap(false, true);

        

//         //Stress testing for Frustum culling
//         // spawnStressTest(300);

//         // mViewWeapon = new ViewWeapon();
//         // mViewWeapon.init(mCamera, 
//         //     "./assets/weapons/glock/Glock.fbx",
//         //     "./assets/modern_soldier/textures/material_0_baseColor.jpeg");

//         // mViewWeapon.loadClip("./assets/weapons/glock/Glock_Idle.fbx", "idle", true);
//         // mViewWeapon.loadClip("./assets/weapons/glock/Glock_Fire1.fbx", "fire");
//         // mViewWeapon.loadClip("./assets/weapons/glock/Glock_Reload.fbx", "reload");
//         // mViewWeapon.loadClip("./assets/weapons/glock/Glock_Draw.fbx", "draw");
//         // mViewWeapon.loadClip("./assets/weapons/glock/Glock_Walk.fbx", "walk");


//         mCollisionEditor = new CollisionEditor();
//         mCollisionEditor.init(mCamera);
        

//         // Register tree collision boxes
//         float th = 1.0f;
//         foreach (i, p; mLevelBuilder.mTreePositions)
//         {
//             mCollisionEditor.addBox(p.x - th, p.z - th, p.x + th, p.z + th,
//                                     "tree_" ~ (cast(int)i).to!string);
//         }

//         // Register soldier collision boxes
//         float sh = 0.4f;  // soldier half-size
//         foreach (i, p; mLevelBuilder.mSoldierPositions)
//         {
//             mCollisionEditor.addBox(p.x - sh, p.z - sh, p.x + sh, p.z + sh,
//                                     "soldier_" ~ (cast(int)i).to!string);
//         }

//     //   mCollisionEditor.addBox(38.04f, -0.507f, 40.907f, 0.507f, "wall2");


//     // mCollisionEditor.addBox(-11.61f, -0.207f, -8.643f, 0.293f, "wall1");
//     // // mCollisionEditor.addBox(28.29f, -0.507f, 41.657f, 0.507f, "wall2");
//     // mCollisionEditor.addBox(7.82179f, -10.4576f, 12.3838f, -9.55355f, "sandbag1");
//     // mCollisionEditor.addBox(17.013f, -15.391f, 23.187f, -14.659f, "sandbag2");
//     // mCollisionEditor.addBox(2.477f, -29.664f, 7.573f, -29.086f, "sandbag3");
//     // mCollisionEditor.addBox(-12.17f, -41.914f, -8.228f, -41.414f, "cornerwall");
//     // mCollisionEditor.addBox(-5f, -25f, 5f, -15f, "cabin1");
//     // mCollisionEditor.addBox(25f, -25f, 35f, -15f, "cabin2");
//     // mCollisionEditor.addBox(10f, -47f, 20f, -33f, "building");
//     // mCollisionEditor.addBox(6.723f, -31.136f, 7.423f, -29.936f, "sandbag3_copy");
//     // mCollisionEditor.addBox(-8.82f, -41.114f, -8.128f, -38.114f, "cornerwall_copy");
//     // mCollisionEditor.addBox(56.3832f, -115.304f, 58.6332f, -113.804f, "new_11");


//     mCollisionEditor.addBox(38.04f, -0.507f, 40.907f, 0.507f, "wall2");
//         mCollisionEditor.addBox(-11.61f, -0.207f, -8.643f, 0.293f, "wall1");
//         mCollisionEditor.addBox(7.82179f, -10.4576f, 12.3838f, -9.55355f, "sandbag1");
//         mCollisionEditor.addBox(17.013f, -15.391f, 23.187f, -14.659f, "sandbag2");
//         mCollisionEditor.addBox(2.477f, -29.664f, 7.573f, -29.086f, "sandbag3");
//         mCollisionEditor.addBox(-12.17f, -41.914f, -8.228f, -41.414f, "cornerwall");
//         // mCollisionEditor.addBox(10.1f, -45.9f, 18.9f, -33f, "building");
//         mCollisionEditor.addBox(6.723f, -31.136f, 7.423f, -29.936f, "sandbag3_copy");
//         mCollisionEditor.addBox(-8.82f, -41.114f, -8.128f, -38.114f, "cornerwall_copy");
//         mCollisionEditor.addBox(56.3832f, -115.304f, 58.6332f, -113.804f, "new_11");
//         mCollisionEditor.addBox(2.76157f, -26.1423f, 3.21157f, -13.9923f, "new_228");
//         mCollisionEditor.addBox(-3.13843f, -26.2423f, -2.68843f, -14.0923f, "new_228_copy");
//         mCollisionEditor.addBox(26.8616f, -26.4423f, 27.3116f, -14.2923f, "new_228_copy_copy");
//         mCollisionEditor.addBox(32.7866f, -26.1924f, 33.2866f, -14.0423f, "new_228_copy_copy_copy");
//         mCollisionEditor.addBox(27.0217f, -25.9311f, 33.0217f, -25.4311f, "new_231");
//         mCollisionEditor.addBox(-2.97832f, -26.2311f, 3.02166f, -25.7311f, "new_231_copy");
//         mCollisionEditor.addBox(-2.96161f, -14.2567f, -0.711613f, -13.7567f, "new_233");
//         mCollisionEditor.addBox(0.938388f, -14.2567f, 3.18839f, -13.7567f, "new_233_copy");
//         mCollisionEditor.addBox(26.9384f, -14.2567f, 29.1884f, -13.7567f, "new_233_copy_copy");
//         mCollisionEditor.addBox(30.9384f, -14.2567f, 33.1884f, -13.7567f, "new_233_copy_copy_copy");
//         mCollisionEditor.addBox(16.3f, -36.9001f, 18.4f, -36.4001f, "building_copy");
//         mCollisionEditor.addBox(11.4f, -36.9001f, 14f, -36.4001f, "building_copy_copy");
//         mCollisionEditor.addBox(18.05f, -43.5251f, 18.65f, -36.7751f, "building_copy_copy");
//         mCollisionEditor.addBox(11.55f, -43.5251f, 12.15f, -36.7751f, "building_copy_copy_copy");
//           mCollisionEditor.addBox(11.8217f, -43.5311f, 17.8217f, -43.0311f, "new_231_copy_copy");





//           mRoundTimer = kChallengeDuration;
// mGui.phase = mPhase;
// mGui.playerName = mPlayerName;
// mGui.roundTimeSeconds = cast(int)mRoundTimer;
// mGui.leaderboard = mLeaderboard.top10();
// mGui.setDefaultName("Player");
// // SDL_SetRelativeMouseMode(SDL_FALSE);










//         mGui.mCollisionEditor = mCollisionEditor;





//     }

//     void debugTreeAsset(){

//         auto scene = aiImportFile(
//             "./assets/free-tree-downloadfbx/source/Tree test.fbx".toStringz,
//             aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs
//         );

//         if (scene is null){
//             writeln("[tree-debug] failed to import tree FBX");
//             return;
//         }

//         writeln("[tree-debug] mesh count = ", scene.mNumMeshes);
//         writeln("[tree-debug] material count = ", scene.mNumMaterials);

//         for (uint i = 0; i < scene.mNumMeshes; ++i){
//             auto mesh = scene.mMeshes[i];
//             writeln("[tree-debug] mesh ", i,
//                 " materialIndex=", mesh.mMaterialIndex,
//                 " vertexCount=", mesh.mNumVertices,
//                 " faceCount=", mesh.mNumFaces);
//         }

//         aiReleaseImport(scene);
//     }

//     void attachAudio(AudioEngine* audio){
//         mAudio = audio;
//         mAudioController.attach(audio);
//         mAudioController.startBackground();
//     }

//     void setUpLights(){

//         GLuint shaderProgramID = Pipeline.sPipeline["basic"];
//         glUseProgram(shaderProgramID);

//         GLint field1 = glGetUniformLocation(shaderProgramID, "uLight1.mColor");
//         GLint field2 = glGetUniformLocation(shaderProgramID, "uLight1.mPosition");
//         GLint field3 = glGetUniformLocation(shaderProgramID, "uLight1.mAmbientIntensity");
//         GLint field4 = glGetUniformLocation(shaderProgramID, "uLight1.mSpecularIntensity");
//         GLint field5 = glGetUniformLocation(shaderProgramID, "uLight1.mSpecularExponent");
//         GLint field6 = glGetUniformLocation(shaderProgramID, "viewpos");

//         foreach(value ; [field1,field2,field3,field4,field5]){
//             if(value < 0){
//                 writeln("Failed to find: ",value);
//             }
//         }
    
//         // Postion light to move in a circle
//         static float inc = 0.0f;
//         float radius = 560.0f;
//         float speed  = 0.1f;   // controls day/night speed
//         inc += 0.0002 * speed;

//         gLight.mPosition = [
//             radius * cos(inc),
//             radius,
//             radius * sin(inc)
//         ];

//         glUniform1fv(field1,3,gLight.mColor.ptr);
//         glUniform1fv(field2,3,gLight.mPosition.ptr);
//         glUniform1f (field3,gLight.mAmbientIntensity);
//         glUniform1f (field4,gLight.mSpecularIntensity);
//         glUniform1f (field5,gLight.mSpecularExponent);
//         glUniform3f(field6, mCamera.mEyePosition.x, mCamera.mEyePosition.y, mCamera.mEyePosition.z);


//         if ("lit_textured" in Pipeline.sPipeline)
//         {
//             GLuint litTexID = Pipeline.sPipeline["lit_textured"];
//             glUseProgram(litTexID);

//             glUniform3f(glGetUniformLocation(litTexID, "uLightPos"),
//                 gLight.mPosition[0], gLight.mPosition[1], gLight.mPosition[2]);
//             glUniform3f(glGetUniformLocation(litTexID, "viewpos"),
//                 mCamera.mEyePosition.x, mCamera.mEyePosition.y, mCamera.mEyePosition.z);
//         }
//     }
   
//     // void requestShoot(){
//     //     mShootRequested = true;
//     // }

//     void requestShoot()
// {
//     if (mPhase != ChallengePhase.Live)
//         return;

//     if (mCollisionEditor !is null && mCollisionEditor.isActive())
//         return;

//     mShootRequested = true;
// }

//     // void reload(){
//     //     mCurrentAmmo = mMaxAmmo;
//     //     writeln("[reload] ammo restored to ", mMaxAmmo);
//     //     // mViewWeapon.playReload();

//     // }

//     void reload()
// {
//     if (mPhase != ChallengePhase.Live)
//         return;

//     mCurrentAmmo = mMaxAmmo;
//     writeln("[reload] ammo restored to ", mMaxAmmo);
// }


//     // private void shoot(){
//     //     // Ammo check
//     //     if (mCurrentAmmo <= 0)
//     //     {
//     //         writeln("[shoot] EMPTY — press R to reload");
//     //         return;
//     //     }
//     //     mCurrentAmmo--;

//     //     vec3 from = mCamera.mEyePosition;
//     //     vec3 dir  = Normalize(mCamera.mForwardVector);

//     //     // Weapon spread
//     //     float spread = 0.02f;
//     //     dir.x += uniform(-spread, spread);
//     //     dir.y += uniform(-spread, spread);
//     //     dir.z += uniform(-spread, spread);
//     //     dir = Normalize(dir);

//     //     vec3 to = from + dir * 1000.0f;

//     //     mShotsFired++;

//     //     mAudioController.playGunshot();
//     //     // mViewWeapon.playFire();

            
//     //     auto result = mPhysicsWorld.raycast(
//     //         from.x, from.y, from.z,
//     //         to.x, to.y, to.z);

//     //     auto now = Clock.currTime();

//     //     if (result.hit){
//     //         mShotsHit++;
//     //         // writeln("[shoot] ", now.toSimpleString(),
//     //         //     " HIT entity=", result.entityId,
//     //         //     " at pos=[", result.hitPosition[0],
//     //         //     ", ", result.hitPosition[1],
//     //         //     ", ", result.hitPosition[2], "]");

//     //         if (result.entityId != mGroundEntity && result.entityId != 0){
//     //             destroyEntity(result.entityId);
//     //         }
//     //     } else{
//     //         // writeln("[shoot] ", now.toSimpleString(), " MISS");
//     //     }

//     //     float accuracy = mShotsFired > 0 ? cast(float)mShotsHit / mShotsFired * 100.0f : 0.0f;
//     //     writeln("[stats] shots=", mShotsFired, " hits=", mShotsHit,
//     //             " accuracy=", accuracy, "%");
//     // }


//     private void shoot()
// {
//     if (mPhase != ChallengePhase.Live)
//         return;

//     if (mCurrentAmmo <= 0)
//     {
//         writeln("[shoot] EMPTY — press R to reload");
//         return;
//     }

//     mCurrentAmmo--;
//     mShotsFired++;

//     vec3 from = mCamera.mEyePosition;
//     vec3 dir  = Normalize(mCamera.mForwardVector);

//     float spread = computeWeaponSpread();
//     dir.x += uniform(-spread, spread);
//     dir.y += uniform(-spread, spread);
//     dir.z += uniform(-spread, spread);
//     dir = Normalize(dir);

//     vec3 to = from + dir * 1000.0f;

//     mAudioController.playGunshot();

//     auto result = mPhysicsWorld.raycast(
//         from.x, from.y, from.z,
//         to.x, to.y, to.z);

//     if (result.hit)
//     {
//         if ((result.entityId in mActiveTargetIds) !is null)
//         {
//             mShotsHit++;
//             mScore += kPointsPerHit;

//             writeln("[challenge] HIT target entity=", result.entityId,
//                 " score=", mScore);

//             removeChallengeTarget(result.entityId);
//             destroyEntity(result.entityId);
//         }
//         else
//         {
//             writeln("[shoot] hit non-target entity=", result.entityId);
//         }
//     }
//     else
//     {
//         writeln("[shoot] MISS");
//     }

//     float acc = mShotsFired > 0 ? cast(float)mShotsHit / mShotsFired * 100.0f : 0.0f;
//     writeln("[stats] shots=", mShotsFired, " hits=", mShotsHit,
//         " accuracy=", acc, "% score=", mScore);
// }




//     // to do: refactor so that this does not check hard coded pairs but rather loops over every object
//     private void checkCollisions(){
//         if ((mCubeEntity in mPhysicsWorld.entityToBody) is null) return;
//         if ((mGroundEntity in mPhysicsWorld.entityToBody) is null) return;

//         b3ContactInformation contactInfo;
//         mPhysicsWorld.getContacts(mCubeEntity, mGroundEntity, contactInfo);
//     }

//     void initCrosshair(){
//         // Create the crosshair shader
//         new Pipeline("crosshair", "./pipelines/crosshair/crosshair.vert",
//                                     "./pipelines/crosshair/crosshair.frag");

//         // Crosshair geometry in NDC (-1 to 1 range)
//         // Gap in center, 4 line segments forming a + shape
//         float size = 0.03f;
//         float gap  = 0.008f;

//         float[] verts = [
//             // Horizontal left
//             -size, 0.0f,
//             -gap,  0.0f,
//             // Horizontal right
//                 gap,  0.0f,
//                 size, 0.0f,
//             // Vertical top
//                 0.0f, size,
//                 0.0f, gap,
//             // Vertical bottom
//                 0.0f, -gap,
//                 0.0f, -size,
//         ];

//         glGenVertexArrays(1, &mCrosshairVAO);
//         glGenBuffers(1, &mCrosshairVBO);

//         glBindVertexArray(mCrosshairVAO);
//         glBindBuffer(GL_ARRAY_BUFFER, mCrosshairVBO);
//         glBufferData(GL_ARRAY_BUFFER, verts.length * float.sizeof,
//                         verts.ptr, GL_STATIC_DRAW);

//         // aPos at location 0, 2 floats per vertex
//         glEnableVertexAttribArray(0);
//         glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, null);

//         glBindVertexArray(0);
//         mCrosshairReady = true;
//     }


//     private float computeWeaponSpread()
// {
//     if (mIsSprinting) return 0.055f;
//     if (mIsMoving)    return 0.030f;
//     return 0.008f;
// }

// private void startChallengeRound()
// {
//     clearChallengeTargets();

//     mPlayerName = mGui.enteredName();
//     if (mPlayerName.length == 0)
//         mPlayerName = "Player";

//     mShotsFired = 0;
//     mShotsHit = 0;
//     mScore = 0;
//     mCurrentAmmo = mMaxAmmo;
//     mRoundTimer = kChallengeDuration;
//     mTargetSpawnAccumulator = 0.0;

//     mPhase = ChallengePhase.Live;
//     mGui.phase = mPhase;
//     mGui.playerName = mPlayerName;

//     // SDL_SetRelativeMouseMode(SDL_TRUE);
//     writeln("[challenge] started for ", mPlayerName);
// }

// private void finishChallengeRound()
// {
//     if (mPhase != ChallengePhase.Live)
//         return;

//     clearChallengeTargets();

//     mLeaderboard.addScore(mPlayerName, mScore, mShotsFired, mShotsHit);
//     mGui.leaderboard = mLeaderboard.top10();

//     mPhase = ChallengePhase.Results;
//     mGui.phase = mPhase;
//     mGui.finalScore = mScore;

//     // SDL_SetRelativeMouseMode(SDL_FALSE);
//     writeln("[challenge] finished for ", mPlayerName, " score=", mScore);
// }


// bool wantsGameMouseLook()
//     {
//         return mPhase == ChallengePhase.Live &&
//                mCollisionEditor !is null &&
//                !mCollisionEditor.isActive();
//     }

//     bool wantsCursorVisible()
//     {
//         if (mPhase != ChallengePhase.Live)
//             return true;
//         if (mCollisionEditor !is null && mCollisionEditor.isActive())
//             return true;
//         return false;
//     }



// private void spawnFallingTarget()
// {
//         writeln("[debug] spawnFallingTarget called");
//     auto spawner = mLevelBuilder.getSpawner();
//     writeln("[debug] got spawner: ", spawner !is null);
//     // auto spawner = mLevelBuilder.getSpawner();

//     vec3[] scales = [
//         vec3(1.0f, 1.0f, 1.0f),
//         vec3(0.75f, 1.35f, 0.75f),
//         vec3(1.35f, 0.65f, 0.65f)
//     ];

//     vec3[] colors = [
//         vec3(0.94f, 0.58f, 0.17f),
//         vec3(0.45f, 0.85f, 0.38f),
//         vec3(0.35f, 0.75f, 1.00f)
//     ];

//     int idx = uniform(0, cast(int)scales.length);

//     float x = uniform(-6.0f, 38.0f);
//     float z = uniform(-42.0f, 4.0f);
//     float y = uniform(18.0f, 25.0f);

//     uint eid = spawner.spawnChallengeBox(
//         vec3(x, y, z),
//         scales[idx],
//         colors[idx],
//         "cube.urdf"
//     );

//     mChallengeTargets ~= ChallengeTarget(eid, kTargetLifetime);
//     mActiveTargetIds[eid] = true;
// }

// private void updateChallengeTargets(double dt)
// {
//     for (int i = cast(int)mChallengeTargets.length - 1; i >= 0; --i)
//     {
//         size_t idx = cast(size_t)i;
//         mChallengeTargets[idx].ttl -= dt;

//         if (mChallengeTargets[idx].ttl <= 0)
//         {
//             uint eid = mChallengeTargets[idx].entityId;
//             mActiveTargetIds.remove(eid);
//             destroyEntity(eid);

//             if (idx != mChallengeTargets.length - 1)
//                 mChallengeTargets[idx] = mChallengeTargets[$ - 1];

//             mChallengeTargets.length = mChallengeTargets.length - 1;
//         }
//     }
// }

// private void removeChallengeTarget(uint entityId)
// {
//     mActiveTargetIds.remove(entityId);

//     foreach (i, t; mChallengeTargets)
//     {
//         if (t.entityId == entityId)
//         {
//             if (i != mChallengeTargets.length - 1)
//                 mChallengeTargets[i] = mChallengeTargets[$ - 1];

//             mChallengeTargets.length = mChallengeTargets.length - 1;
//             break;
//         }
//     }
// }

// private void clearChallengeTargets()
// {
//     foreach (t; mChallengeTargets)
//         destroyEntity(t.entityId);

//     mChallengeTargets.length = 0;
//     mActiveTargetIds = null;
// }

//     /// Fully destroy an entity: physics body + scene tree node + entity manager
//     void destroyEntity(uint entityId)
//     {
//         // 1. Remove from Bullet physics
//         if (entityId in mPhysicsWorld.entityToBody){
//             mPhysicsWorld.removeBody(entityId);
//         }

//         if (auto nodes = entityId in mEntityManager.renderables){
//             foreach(node; *nodes){
//                 // Find parent and remove this child
//                 auto parent = node.GetParentSceneNode();
//                 if (parent !is null){
//                     // Filter this node out of parent's children
//                     ISceneNode[] remaining;
//                     foreach (child; parent.mChildren){
//                         if (child !is node){
//                             remaining ~= child;
//                         }   
//                     }
//                     parent.mChildren = remaining;
//                 }
//             }
//         }

//         // 3. Remove from entity manager
//         mEntityManager.destroy(entityId);
//         writeln("[destroy] entity=", entityId);
//     }
// }


// // top links:
// // https://www.cgtrader.com/3d-models/exterior/other/lowpoly-fps-modular-map-kit
// // https://www.cgtrader.com/3d-models/military/gun/fps-animations-single-pistol
// // https://www.cgtrader.com/3d-models/military/gun/fps-automatic-rifle-01-animations



// // to do: look at architecture from 2D game and try to get nifty game strategies here





















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
import collisioneditor;
import challenge_state;
import leaderboard;

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
    // ViewWeapon mViewWeapon;


    ChallengePhase mPhase = ChallengePhase.Intro;
    LeaderboardStore mLeaderboard;
    ChallengeTarget[] mChallengeTargets;
    bool[uint] mActiveTargetIds;
    bool[uint] mSoldierIds;    // entity ids of soldiers spawned in the map — shootable, box dies with them

    string mPlayerName = "Player";
    int mScore = 0;
    double mTargetSpawnAccumulator = 0.0;

    bool mIsMoving = false;
    bool mIsSprinting = false;
    float mCurrentSpread = 0.0f;

    //Game Materials

    /// sound specific elements
    AudioController mAudioController;
    CollisionEditor mCollisionEditor;


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


        mLeaderboard = new LeaderboardStore("./data/topshoota_leaderboard.txt");
        mGui.leaderboard = mLeaderboard.top10();
        mGui.phase = mPhase;
    }

    // override void Input(){
    //     if (mShootRequested){
    //         shoot();
    //         mShootRequested = false;
    //     }
    // }

    override void Input()
{
    if (mGui.consumeStartPressed())
        startChallengeRound();

    if (mGui.consumeRestartPressed())
    {
        mPhase = ChallengePhase.Intro;
        mGui.phase = mPhase;
        mGui.leaderboard = mLeaderboard.top10();
        // SDL_SetRelativeMouseMode(SDL_FALSE);
        return;
    }

    const(ubyte)* keys = SDL_GetKeyboardState(null);
    mIsMoving =
        keys[SDL_SCANCODE_W] != 0 ||
        keys[SDL_SCANCODE_A] != 0 ||
        keys[SDL_SCANCODE_S] != 0 ||
        keys[SDL_SCANCODE_D] != 0;

    mIsSprinting = mIsMoving &&
        (keys[SDL_SCANCODE_LSHIFT] != 0 || keys[SDL_SCANCODE_RSHIFT] != 0);

    if (mPhase != ChallengePhase.Live)
    {
        mShootRequested = false;
        return;
    }

    if (mShootRequested)
    {
        shoot();
        mShootRequested = false;
    }
}






    override void Update(double frameDt){
        checkCollisions();

    if (mPhase == ChallengePhase.Live)
    {
        mRoundTimer -= frameDt;
        if (mRoundTimer < 0)
            mRoundTimer = 0;

        mTargetSpawnAccumulator += frameDt;
        while (mTargetSpawnAccumulator >= kTargetSpawnInterval)
        {
            mTargetSpawnAccumulator -= kTargetSpawnInterval;
            spawnFallingTarget();
        }

        updateChallengeTargets(frameDt);

        if (mRoundTimer <= 0)
            finishChallengeRound();
    }

    mCurrentSpread = computeWeaponSpread();

    mGui.phase = mPhase;
    mGui.score = mScore;
    mGui.finalScore = mScore;
    mGui.shotsFired = mShotsFired;
    mGui.shotsHit = mShotsHit;
    mGui.playerName = mPlayerName;
    mGui.accuracy = mShotsFired > 0 ? cast(float)mShotsHit / mShotsFired * 100.0f : 0.0f;
    mGui.currentAmmo = mCurrentAmmo;
    mGui.maxAmmo = mMaxAmmo;
    mGui.roundTimeSeconds = cast(int)mRoundTimer;
    mGui.leaderboard = mLeaderboard.top10();
    mGui.movementState = mIsSprinting ? "SPRINTING" : (mIsMoving ? "MOVING" : "STOPPED");
    mGui.currentSpread = mCurrentSpread;


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
        // mViewWeapon.update(frameDt);
    }

    // void Render(){

    //     // Render view weapon
    //     // mViewWeapon.render();

    //     mCollisionEditor.render();

    //     //Render Cross Hair as it is like a GUI element
    //     drawCrosshair();

    //     //Render the games GUI last
    //     mGui.Render();
    // }


    void Render()
{
    if (mPhase == ChallengePhase.Live)
    {
        // Only draw collider boxes when the collision editor is active (CTRL+E).
        // Otherwise keep the game view clean.
        if (mCollisionEditor !is null && mCollisionEditor.isActive())
            mCollisionEditor.render();
        drawCrosshair();
    }

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
        // mLevelBuilder.SetupMap();

        mLevelBuilder.SetupMap(false, true);

        

        //Stress testing for Frustum culling
        // spawnStressTest(300);

        // mViewWeapon = new ViewWeapon();
        // mViewWeapon.init(mCamera, 
        //     "./assets/weapons/glock/Glock.fbx",
        //     "./assets/modern_soldier/textures/material_0_baseColor.jpeg");

        // mViewWeapon.loadClip("./assets/weapons/glock/Glock_Idle.fbx", "idle", true);
        // mViewWeapon.loadClip("./assets/weapons/glock/Glock_Fire1.fbx", "fire");
        // mViewWeapon.loadClip("./assets/weapons/glock/Glock_Reload.fbx", "reload");
        // mViewWeapon.loadClip("./assets/weapons/glock/Glock_Draw.fbx", "draw");
        // mViewWeapon.loadClip("./assets/weapons/glock/Glock_Walk.fbx", "walk");


        mCollisionEditor = new CollisionEditor();
        mCollisionEditor.init(mCamera);
        

        // Register tree collision boxes
        float th = 1.0f;
        foreach (i, p; mLevelBuilder.mTreePositions)
        {
            mCollisionEditor.addBox(p.x - th, p.z - th, p.x + th, p.z + th,
                                    "tree_" ~ (cast(int)i).to!string);
        }

        // Register soldier collision boxes, tied to their entity ids so they
        // are removed when the soldier is destroyed.
        float sh = 0.4f;  // soldier half-size
        foreach (i, p; mLevelBuilder.mSoldierPositions)
        {
            uint eid = (i < mLevelBuilder.mSoldierEntityIds.length)
                ? mLevelBuilder.mSoldierEntityIds[i]
                : 0;
            mCollisionEditor.addBoxForEntity(eid,
                p.x - sh, p.z - sh, p.x + sh, p.z + sh,
                "soldier_" ~ (cast(int)i).to!string);

            // Track soldiers as valid shoot targets so they can be killed.
            if (eid != 0)
                mSoldierIds[eid] = true;
        }

    //   mCollisionEditor.addBox(38.04f, -0.507f, 40.907f, 0.507f, "wall2");


    // mCollisionEditor.addBox(-11.61f, -0.207f, -8.643f, 0.293f, "wall1");
    // // mCollisionEditor.addBox(28.29f, -0.507f, 41.657f, 0.507f, "wall2");
    // mCollisionEditor.addBox(7.82179f, -10.4576f, 12.3838f, -9.55355f, "sandbag1");
    // mCollisionEditor.addBox(17.013f, -15.391f, 23.187f, -14.659f, "sandbag2");
    // mCollisionEditor.addBox(2.477f, -29.664f, 7.573f, -29.086f, "sandbag3");
    // mCollisionEditor.addBox(-12.17f, -41.914f, -8.228f, -41.414f, "cornerwall");
    // mCollisionEditor.addBox(-5f, -25f, 5f, -15f, "cabin1");
    // mCollisionEditor.addBox(25f, -25f, 35f, -15f, "cabin2");
    // mCollisionEditor.addBox(10f, -47f, 20f, -33f, "building");
    // mCollisionEditor.addBox(6.723f, -31.136f, 7.423f, -29.936f, "sandbag3_copy");
    // mCollisionEditor.addBox(-8.82f, -41.114f, -8.128f, -38.114f, "cornerwall_copy");
    // mCollisionEditor.addBox(56.3832f, -115.304f, 58.6332f, -113.804f, "new_11");


    mCollisionEditor.addBox(38.04f, -0.507f, 40.907f, 0.507f, "wall2");
        mCollisionEditor.addBox(-11.61f, -0.207f, -8.643f, 0.293f, "wall1");
        mCollisionEditor.addBox(7.82179f, -10.4576f, 12.3838f, -9.55355f, "sandbag1");
        mCollisionEditor.addBox(17.013f, -15.391f, 23.187f, -14.659f, "sandbag2");
        mCollisionEditor.addBox(2.477f, -29.664f, 7.573f, -29.086f, "sandbag3");
        mCollisionEditor.addBox(-12.17f, -41.914f, -8.228f, -41.414f, "cornerwall");
        // mCollisionEditor.addBox(10.1f, -45.9f, 18.9f, -33f, "building");
        mCollisionEditor.addBox(6.723f, -31.136f, 7.423f, -29.936f, "sandbag3_copy");
        mCollisionEditor.addBox(-8.82f, -41.114f, -8.128f, -38.114f, "cornerwall_copy");
        mCollisionEditor.addBox(56.3832f, -115.304f, 58.6332f, -113.804f, "new_11");
        mCollisionEditor.addBox(2.76157f, -26.1423f, 3.21157f, -13.9923f, "new_228");
        mCollisionEditor.addBox(-3.13843f, -26.2423f, -2.68843f, -14.0923f, "new_228_copy");
        mCollisionEditor.addBox(26.8616f, -26.4423f, 27.3116f, -14.2923f, "new_228_copy_copy");
        mCollisionEditor.addBox(32.7866f, -26.1924f, 33.2866f, -14.0423f, "new_228_copy_copy_copy");
        mCollisionEditor.addBox(27.0217f, -25.9311f, 33.0217f, -25.4311f, "new_231");
        mCollisionEditor.addBox(-2.97832f, -26.2311f, 3.02166f, -25.7311f, "new_231_copy");
        mCollisionEditor.addBox(-2.96161f, -14.2567f, -0.711613f, -13.7567f, "new_233");
        mCollisionEditor.addBox(0.938388f, -14.2567f, 3.18839f, -13.7567f, "new_233_copy");
        mCollisionEditor.addBox(26.9384f, -14.2567f, 29.1884f, -13.7567f, "new_233_copy_copy");
        mCollisionEditor.addBox(30.9384f, -14.2567f, 33.1884f, -13.7567f, "new_233_copy_copy_copy");
        mCollisionEditor.addBox(16.3f, -36.9001f, 18.4f, -36.4001f, "building_copy");
        mCollisionEditor.addBox(11.4f, -36.9001f, 14f, -36.4001f, "building_copy_copy");
        mCollisionEditor.addBox(18.05f, -43.5251f, 18.65f, -36.7751f, "building_copy_copy");
        mCollisionEditor.addBox(11.55f, -43.5251f, 12.15f, -36.7751f, "building_copy_copy_copy");
          mCollisionEditor.addBox(11.8217f, -43.5311f, 17.8217f, -43.0311f, "new_231_copy_copy");





          mRoundTimer = kChallengeDuration;
mGui.phase = mPhase;
mGui.playerName = mPlayerName;
mGui.roundTimeSeconds = cast(int)mRoundTimer;
mGui.leaderboard = mLeaderboard.top10();
mGui.setDefaultName("Player");
// SDL_SetRelativeMouseMode(SDL_FALSE);










        mGui.mCollisionEditor = mCollisionEditor;





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
   
    // void requestShoot(){
    //     mShootRequested = true;
    // }

    void requestShoot()
{
    if (mPhase != ChallengePhase.Live)
        return;

    if (mCollisionEditor !is null && mCollisionEditor.isActive())
        return;

    mShootRequested = true;
}

    // void reload(){
    //     mCurrentAmmo = mMaxAmmo;
    //     writeln("[reload] ammo restored to ", mMaxAmmo);
    //     // mViewWeapon.playReload();

    // }

    void reload()
{
    if (mPhase != ChallengePhase.Live)
        return;

    mCurrentAmmo = mMaxAmmo;
    writeln("[reload] ammo restored to ", mMaxAmmo);
}


    // private void shoot(){
    //     // Ammo check
    //     if (mCurrentAmmo <= 0)
    //     {
    //         writeln("[shoot] EMPTY — press R to reload");
    //         return;
    //     }
    //     mCurrentAmmo--;

    //     vec3 from = mCamera.mEyePosition;
    //     vec3 dir  = Normalize(mCamera.mForwardVector);

    //     // Weapon spread
    //     float spread = 0.02f;
    //     dir.x += uniform(-spread, spread);
    //     dir.y += uniform(-spread, spread);
    //     dir.z += uniform(-spread, spread);
    //     dir = Normalize(dir);

    //     vec3 to = from + dir * 1000.0f;

    //     mShotsFired++;

    //     mAudioController.playGunshot();
    //     // mViewWeapon.playFire();

            
    //     auto result = mPhysicsWorld.raycast(
    //         from.x, from.y, from.z,
    //         to.x, to.y, to.z);

    //     auto now = Clock.currTime();

    //     if (result.hit){
    //         mShotsHit++;
    //         // writeln("[shoot] ", now.toSimpleString(),
    //         //     " HIT entity=", result.entityId,
    //         //     " at pos=[", result.hitPosition[0],
    //         //     ", ", result.hitPosition[1],
    //         //     ", ", result.hitPosition[2], "]");

    //         if (result.entityId != mGroundEntity && result.entityId != 0){
    //             destroyEntity(result.entityId);
    //         }
    //     } else{
    //         // writeln("[shoot] ", now.toSimpleString(), " MISS");
    //     }

    //     float accuracy = mShotsFired > 0 ? cast(float)mShotsHit / mShotsFired * 100.0f : 0.0f;
    //     writeln("[stats] shots=", mShotsFired, " hits=", mShotsHit,
    //             " accuracy=", accuracy, "%");
    // }


    private void shoot()
{
    if (mPhase != ChallengePhase.Live)
        return;

    if (mCurrentAmmo <= 0)
    {
        writeln("[shoot] EMPTY — press R to reload");
        return;
    }

    mCurrentAmmo--;
    mShotsFired++;

    vec3 from = mCamera.mEyePosition;
    vec3 dir  = Normalize(mCamera.mForwardVector);

    float spread = computeWeaponSpread();
    dir.x += uniform(-spread, spread);
    dir.y += uniform(-spread, spread);
    dir.z += uniform(-spread, spread);
    dir = Normalize(dir);

    vec3 to = from + dir * 1000.0f;

    mAudioController.playGunshot();

    auto result = mPhysicsWorld.raycast(
        from.x, from.y, from.z,
        to.x, to.y, to.z);

    if (result.hit)
    {
        if ((result.entityId in mActiveTargetIds) !is null)
        {
            mShotsHit++;
            mScore += kPointsPerHit;

            writeln("[challenge] HIT target entity=", result.entityId,
                " score=", mScore);

            removeChallengeTarget(result.entityId);
            destroyEntity(result.entityId);
        }
        else if ((result.entityId in mSoldierIds) !is null)
        {
            mShotsHit++;
            mScore += kPointsPerHit;

            writeln("[shoot] HIT soldier entity=", result.entityId,
                " score=", mScore);

            mSoldierIds.remove(result.entityId);
            destroyEntity(result.entityId);
        }
        else
        {
            writeln("[shoot] hit non-target entity=", result.entityId);
        }
    }
    else
    {
        writeln("[shoot] MISS");
    }

    float acc = mShotsFired > 0 ? cast(float)mShotsHit / mShotsFired * 100.0f : 0.0f;
    writeln("[stats] shots=", mShotsFired, " hits=", mShotsHit,
        " accuracy=", acc, "% score=", mScore);
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


    private float computeWeaponSpread()
{
    if (mIsSprinting) return 0.055f;
    if (mIsMoving)    return 0.030f;
    return 0.008f;
}

private void startChallengeRound()
{
    clearChallengeTargets();

    mPlayerName = mGui.enteredName();
    if (mPlayerName.length == 0)
        mPlayerName = "Player";

    mShotsFired = 0;
    mShotsHit = 0;
    mScore = 0;
    mCurrentAmmo = mMaxAmmo;
    mRoundTimer = kChallengeDuration;
    mTargetSpawnAccumulator = 0.0;

    mPhase = ChallengePhase.Live;
    mGui.phase = mPhase;
    mGui.playerName = mPlayerName;

    // SDL_SetRelativeMouseMode(SDL_TRUE);
    writeln("[challenge] started for ", mPlayerName);
}

private void finishChallengeRound()
{
    if (mPhase != ChallengePhase.Live)
        return;

    clearChallengeTargets();

    mLeaderboard.addScore(mPlayerName, mScore, mShotsFired, mShotsHit);
    mGui.leaderboard = mLeaderboard.top10();

    mPhase = ChallengePhase.Results;
    mGui.phase = mPhase;
    mGui.finalScore = mScore;

    // SDL_SetRelativeMouseMode(SDL_FALSE);
    writeln("[challenge] finished for ", mPlayerName, " score=", mScore);
}


bool wantsGameMouseLook()
    {
        return mPhase == ChallengePhase.Live &&
               mCollisionEditor !is null &&
               !mCollisionEditor.isActive();
    }

    bool wantsCursorVisible()
    {
        if (mPhase != ChallengePhase.Live)
            return true;
        if (mCollisionEditor !is null && mCollisionEditor.isActive())
            return true;
        return false;
    }



private void spawnFallingTarget()
{
        writeln("[debug] spawnFallingTarget called");
    auto spawner = mLevelBuilder.getSpawner();
    writeln("[debug] got spawner: ", spawner !is null);
    // auto spawner = mLevelBuilder.getSpawner();

    vec3[] scales = [
        vec3(1.0f, 1.0f, 1.0f),
        vec3(0.75f, 1.35f, 0.75f),
        vec3(1.35f, 0.65f, 0.65f)
    ];

    vec3[] colors = [
        vec3(0.94f, 0.58f, 0.17f),
        vec3(0.45f, 0.85f, 0.38f),
        vec3(0.35f, 0.75f, 1.00f)
    ];

    int idx = uniform(0, cast(int)scales.length);

    float x = uniform(-6.0f, 38.0f);
    float z = uniform(-42.0f, 4.0f);
    float y = uniform(18.0f, 25.0f);

    uint eid = spawner.spawnChallengeBox(
        vec3(x, y, z),
        scales[idx],
        colors[idx],
        "cube.urdf"
    );

    mChallengeTargets ~= ChallengeTarget(eid, kTargetLifetime);
    mActiveTargetIds[eid] = true;
}

private void updateChallengeTargets(double dt)
{
    for (int i = cast(int)mChallengeTargets.length - 1; i >= 0; --i)
    {
        size_t idx = cast(size_t)i;
        mChallengeTargets[idx].ttl -= dt;

        if (mChallengeTargets[idx].ttl <= 0)
        {
            uint eid = mChallengeTargets[idx].entityId;
            mActiveTargetIds.remove(eid);
            destroyEntity(eid);

            if (idx != mChallengeTargets.length - 1)
                mChallengeTargets[idx] = mChallengeTargets[$ - 1];

            mChallengeTargets.length = mChallengeTargets.length - 1;
        }
    }
}

private void removeChallengeTarget(uint entityId)
{
    mActiveTargetIds.remove(entityId);

    foreach (i, t; mChallengeTargets)
    {
        if (t.entityId == entityId)
        {
            if (i != mChallengeTargets.length - 1)
                mChallengeTargets[i] = mChallengeTargets[$ - 1];

            mChallengeTargets.length = mChallengeTargets.length - 1;
            break;
        }
    }
}

private void clearChallengeTargets()
{
    foreach (t; mChallengeTargets)
        destroyEntity(t.entityId);

    mChallengeTargets.length = 0;
    mActiveTargetIds = null;
}

    /// Fully destroy an entity: physics body + scene tree node + entity manager + collision box
    void destroyEntity(uint entityId)
    {
        // 0. Remove any collision editor box bound to this entity (e.g. soldiers)
        if (mCollisionEditor !is null)
            mCollisionEditor.removeBoxForEntity(entityId);

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


