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

class GameApplication : IGame
{
    //----------------------------------------------------------------
    // Engine refs
    //----------------------------------------------------------------
    PhysicsWorld  mPhysicsWorld;
    EntityManager mEntityManager;
    Camera        mCamera;
    SceneTree     mSceneTree;
    AudioEngine*  mAudio;

    //----------------------------------------------------------------
    // Game-specific state
    //----------------------------------------------------------------
    string  gameName;
    uint    mGroundEntity;
    uint    mCubeEntity;
    int     mShotsFired;
    int     mShotsHit;
    bool    mShootRequested;

    // Crosshair
    GLuint  mCrosshairVAO;
    GLuint  mCrosshairVBO;
    bool    mCrosshairReady = false;

    // Environment
    GameGUI       mGui;
    Light         gLight;
    GLuint        mSkyBoxVAO;
    GLuint        mSkyBoxVBO;
    GLuint        mCubemapTexture;
    LevelBuilder  mLevelBuilder;

    //----------------------------------------------------------------
    // Weapon
    //----------------------------------------------------------------
    int mCurrentAmmo = 30;
    int mMaxAmmo     = 30;

    //----------------------------------------------------------------
    // Challenge state
    //----------------------------------------------------------------
    ChallengePhase     mPhase = ChallengePhase.Intro;
    LeaderboardStore   mLeaderboard;
    double             mRoundTimer = kChallengeDuration;
    string             mPlayerName = "Player";
    int                mScore = 0;

    // Cubes
    ChallengeTarget[]  mChallengeTargets;
    bool[uint]         mActiveTargetIds;
    double             mTargetSpawnAccumulator = 0.0;
    double             mCurrentSpawnInterval   = kCubeSpawnIntervalStart;
    int                mCubesHit = 0;

    // Jackpot enemies
    ChallengeEnemy[]   mEnemies;
    bool[uint]         mSoldierIds;        // fast lookup: is this entity a live enemy?
    size_t[uint]       mEnemyBoxIndexByEid;// entity id -> index into mEnemies (for O(1) removal)
    bool[size_t]       mEnemyPoolInUse;    // which spawn-pool slots are currently taken
    double             mEnemySpawnTimer = 0.0;
    double             mNextEnemySpawnIn = 2.5;
    int                mEnemiesKilled = 0;

    // Combo
    int    mCombo = 0;
    float  mComboMultiplier = 1.0f;
    double mComboTimer = 0.0;

    // Movement flags (drive spread)
    bool  mIsMoving = false;
    bool  mIsSprinting = false;
    float mCurrentSpread = 0.0f;

    //----------------------------------------------------------------
    // Sub-systems owned by the game
    //----------------------------------------------------------------
    AudioController   mAudioController;
    CollisionEditor   mCollisionEditor;
    MaterialRegistry  mMaterialRegistry;
    ResourceManager   mResourceManager;

    //----------------------------------------------------------------
    this(string name, PhysicsWorld physics, EntityManager em, Camera cam,
         SceneTree tree, IMaterial mat)
    {
        this.gameName   = name;
        mPhysicsWorld   = physics;
        mEntityManager  = em;
        mCamera         = cam;
        mSceneTree      = tree;
        mGui            = new GameGUI("topshoota-game-gui");
        mAudioController = new AudioController();

        mMaterialRegistry = new MaterialRegistry(cam);
        mMaterialRegistry.setup();

        mResourceManager = new ResourceManager();

        mLevelBuilder = new LevelBuilder(cam, tree, em, physics,
            mMaterialRegistry, mResourceManager);

        mLeaderboard = new LeaderboardStore("./data/topshoota_leaderboard.txt");
        mGui.leaderboard = mLeaderboard.top10();
        mGui.phase = mPhase;
    }

    //================================================================
    // Input
    //================================================================
    override void Input()
    {
        if (mGui.consumeStartPressed())
            startChallengeRound();

        if (mGui.consumeRestartPressed())
        {
            mPhase = ChallengePhase.Intro;
            mGui.phase = mPhase;
            mGui.leaderboard = mLeaderboard.top10();
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

    //================================================================
    // Update
    //================================================================
    override void Update(double frameDt)
    {
        checkCollisions();

        if (mPhase == ChallengePhase.Live)
        {
            mRoundTimer -= frameDt;
            if (mRoundTimer < 0) mRoundTimer = 0;

            // Combo decay
            if (mComboTimer > 0)
            {
                mComboTimer -= frameDt;
                if (mComboTimer <= 0)
                    resetCombo();
            }

            // Cube spawn (ramping interval)
            mCurrentSpawnInterval = rampedSpawnInterval();
            mTargetSpawnAccumulator += frameDt;
            while (mTargetSpawnAccumulator >= mCurrentSpawnInterval)
            {
                mTargetSpawnAccumulator -= mCurrentSpawnInterval;
                spawnFallingCube();
            }
            updateChallengeCubes(frameDt);

            // Enemy spawn (random intervals, capped at kMaxAliveEnemies alive)
            mEnemySpawnTimer += frameDt;
            if (mEnemySpawnTimer >= mNextEnemySpawnIn)
            {
                mEnemySpawnTimer = 0.0;
                mNextEnemySpawnIn = uniform(kEnemySpawnMinInterval, kEnemySpawnMaxInterval);

                if (mEnemies.length < kMaxAliveEnemies)
                    trySpawnEnemy();
            }
            updateEnemies(frameDt);

            if (mRoundTimer <= 0)
                finishChallengeRound();
        }

        mCurrentSpread = computeWeaponSpread();

        //----------------------------------------------------------------
        // Push state to GUI
        //----------------------------------------------------------------
        mGui.phase              = mPhase;
        mGui.score              = mScore;
        mGui.finalScore         = mScore;
        mGui.shotsFired         = mShotsFired;
        mGui.shotsHit           = mShotsHit;
        mGui.playerName         = mPlayerName;
        mGui.accuracy           = mShotsFired > 0
            ? cast(float)mShotsHit / mShotsFired * 100.0f
            : 0.0f;
        mGui.currentAmmo        = mCurrentAmmo;
        mGui.maxAmmo            = mMaxAmmo;
        mGui.roundTimeSeconds   = cast(int)mRoundTimer;
        mGui.roundTimeRemaining = mRoundTimer;
        mGui.roundTimeTotal     = kChallengeDuration;
        mGui.leaderboard        = mLeaderboard.top10();
        mGui.movementState      = mIsSprinting ? "SPRINTING"
                                                : (mIsMoving ? "MOVING" : "STOPPED");
        mGui.currentSpread      = mCurrentSpread;
        mGui.comboCount         = mCombo;
        mGui.comboMultiplier    = mComboMultiplier;
        mGui.cubesHit           = mCubesHit;
        mGui.enemiesKilled      = mEnemiesKilled;
        mGui.enemiesAlive       = cast(int)mEnemies.length;

        mGui.tick(frameDt);

        //----------------------------------------------------------------
        // Sun (lightbox) follow
        //----------------------------------------------------------------
        MeshNode lightNode = cast(MeshNode)mSceneTree.FindNode("light");
        if (lightNode !is null)
        {
            GLfloat x = gLight.mPosition[0];
            GLfloat y = gLight.mPosition[1];
            GLfloat z = gLight.mPosition[2];
            lightNode.mModelMatrix = MatrixMakeTranslation(vec3(x, y, z))
                                   * MatrixMakeScale(vec3(15.0f, 15.0f, 15.0f));
        }

        MeshNode terrain = cast(MeshNode)mSceneTree.FindNode("terrain");
        if (terrain is null)
            writeln("[terrain] ERROR: terrain node not found in scene tree!");
        else
            terrain.mModelMatrix = MatrixMakeTranslation(vec3(-256.0f, 0.0f, -256.0f));
    }

    //================================================================
    // Render
    //================================================================
    void Render()
    {
        if (mPhase == ChallengePhase.Live)
        {
            // Only draw collider boxes when the editor is active.
            if (mCollisionEditor !is null && mCollisionEditor.isActive())
                mCollisionEditor.render();

            drawCrosshair();
        }

        mGui.Render();
    }

    //================================================================
    // Setup
    //================================================================
    override void Setup()
    {
        setUpLights();
        initCrosshair();

        mPhysicsWorld.setGravity(0.0, -1.0, 0.0);

        // Ground plane
        mGroundEntity = mEntityManager.create();
        mPhysicsWorld.addURDF(mGroundEntity, "plane.urdf",
            0, 0, 0,  0, 0, 0, 1);
        mEntityManager.markPhysics(mGroundEntity);
        TransformComponent planeTc;
        mEntityManager.addTransform(mGroundEntity, planeTc);

        // Build map WITHOUT batch-spawning soldiers — challenge mode drip-spawns
        // them as jackpot enemies. Trees still spawn normally.
        mLevelBuilder.SetupMap(false, true);

        mCollisionEditor = new CollisionEditor();
        mCollisionEditor.init(mCamera);

        // Tree collision boxes — static, not tied to entities.
        float th = 1.0f;
        foreach (i, p; mLevelBuilder.mTreePositions)
        {
            mCollisionEditor.addBox(
                p.x - th, p.z - th, p.x + th, p.z + th,
                "tree_" ~ (cast(int)i).to!string);
        }

        // Level geometry collision boxes — keep your existing hand-tuned layout.
        mCollisionEditor.addBox(38.04f, -0.507f, 40.907f, 0.507f, "wall2");
        mCollisionEditor.addBox(-11.61f, -0.207f, -8.643f, 0.293f, "wall1");
        mCollisionEditor.addBox(7.82179f, -10.4576f, 12.3838f, -9.55355f, "sandbag1");
        mCollisionEditor.addBox(17.013f, -15.391f, 23.187f, -14.659f, "sandbag2");
        mCollisionEditor.addBox(2.477f, -29.664f, 7.573f, -29.086f, "sandbag3");
        mCollisionEditor.addBox(-12.17f, -41.914f, -8.228f, -41.414f, "cornerwall");
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

        // Initial GUI state
        mRoundTimer = kChallengeDuration;
        mGui.phase = mPhase;
        mGui.playerName = mPlayerName;
        mGui.roundTimeSeconds = cast(int)mRoundTimer;
        mGui.roundTimeRemaining = mRoundTimer;
        mGui.roundTimeTotal = kChallengeDuration;
        mGui.leaderboard = mLeaderboard.top10();
        mGui.setDefaultName("Player");
        mGui.mCollisionEditor = mCollisionEditor;
    }

    //================================================================
    // Misc engine plumbing
    //================================================================
    void attachAudio(AudioEngine* audio)
    {
        mAudio = audio;
        mAudioController.attach(audio);
        mAudioController.startBackground();
    }

    void setUpLights()
    {
        GLuint shaderProgramID = Pipeline.sPipeline["basic"];
        glUseProgram(shaderProgramID);

        GLint field1 = glGetUniformLocation(shaderProgramID, "uLight1.mColor");
        GLint field2 = glGetUniformLocation(shaderProgramID, "uLight1.mPosition");
        GLint field3 = glGetUniformLocation(shaderProgramID, "uLight1.mAmbientIntensity");
        GLint field4 = glGetUniformLocation(shaderProgramID, "uLight1.mSpecularIntensity");
        GLint field5 = glGetUniformLocation(shaderProgramID, "uLight1.mSpecularExponent");
        GLint field6 = glGetUniformLocation(shaderProgramID, "viewpos");

        foreach (value; [field1, field2, field3, field4, field5])
            if (value < 0) writeln("Failed to find: ", value);

        static float inc = 0.0f;
        float radius = 560.0f;
        float speed  = 0.1f;
        inc += 0.0002 * speed;

        gLight.mPosition = [
            radius * cos(inc),
            radius,
            radius * sin(inc)
        ];

        glUniform1fv(field1, 3, gLight.mColor.ptr);
        glUniform1fv(field2, 3, gLight.mPosition.ptr);
        glUniform1f (field3, gLight.mAmbientIntensity);
        glUniform1f (field4, gLight.mSpecularIntensity);
        glUniform1f (field5, gLight.mSpecularExponent);
        glUniform3f(field6,
            mCamera.mEyePosition.x, mCamera.mEyePosition.y, mCamera.mEyePosition.z);

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

    //================================================================
    // Shooting
    //================================================================
    void requestShoot()
    {
        if (mPhase != ChallengePhase.Live) return;
        if (mCollisionEditor !is null && mCollisionEditor.isActive()) return;
        mShootRequested = true;
    }

    void reload()
    {
        if (mPhase != ChallengePhase.Live) return;
        mCurrentAmmo = mMaxAmmo;
        writeln("[reload] ammo restored to ", mMaxAmmo);
    }

    private void shoot()
    {
        if (mPhase != ChallengePhase.Live) return;

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
                registerHit(false);
                int awarded = cast(int)(kPointsPerHit * mComboMultiplier + 0.5f);
                mScore += awarded;
                mCubesHit++;
                mGui.pushScorePopup(awarded, mCombo, /*isEnemy=*/false);
                mAudioController.playCubeHit();

                writeln("[challenge] CUBE hit eid=", result.entityId,
                    " +", awarded, " combo=x", mCombo, " score=", mScore);

                removeChallengeCube(result.entityId);
                destroyEntity(result.entityId);
            }
            else if ((result.entityId in mSoldierIds) !is null)
            {
                registerHit(true);
                int awarded = cast(int)(kPointsPerEnemy * mComboMultiplier + 0.5f);
                mScore += awarded;
                mEnemiesKilled++;
                mGui.pushScorePopup(awarded, mCombo, /*isEnemy=*/true);
                mAudioController.playHumanHit();

                writeln("[challenge] ENEMY hit eid=", result.entityId,
                    " +", awarded, " combo=x", mCombo, " score=", mScore);

                // Free up that pool slot so a new enemy can appear there later.
                if (auto idxPtr = result.entityId in mEnemyBoxIndexByEid)
                {
                    size_t i = *idxPtr;
                    if (i < mEnemies.length)
                        mEnemyPoolInUse.remove(mEnemies[i].positionIndex);
                }
                removeEnemyByEntity(result.entityId);
                mSoldierIds.remove(result.entityId);
                destroyEntity(result.entityId);
            }
            else
            {
                writeln("[shoot] hit non-target eid=", result.entityId);
                breakCombo();
            }
        }
        else
        {
            writeln("[shoot] MISS");
            breakCombo();
        }
    }

    private void registerHit(bool isEnemy)
    {
        mShotsHit++;
        mCombo++;
        mComboTimer = kComboWindow;

        float m = 1.0f + 0.5f * (mCombo - 1);
        if (m > kComboMaxMultiplier) m = kComboMaxMultiplier;
        mComboMultiplier = m;

        mGui.onComboAdvanced(mCombo);
    }

    private void breakCombo()
    {
        if (mCombo > 1)
            writeln("[combo] broken at x", mCombo);
        resetCombo();
    }

    private void resetCombo()
    {
        mCombo = 0;
        mComboMultiplier = 1.0f;
        mComboTimer = 0.0;
    }

    //================================================================
    // Cubes
    //================================================================
    private double rampedSpawnInterval()
    {
        // t: 0 at start, 1 at end
        double t = 1.0 - (mRoundTimer / kChallengeDuration);
        if (t < 0) t = 0;
        if (t > 1) t = 1;
        return kCubeSpawnIntervalStart * (1.0 - t)
             + kCubeSpawnIntervalEnd   * t;
    }

    private void rampedSpawnY(out float yMin, out float yMax)
    {
        float t = cast(float)(1.0 - (mRoundTimer / kChallengeDuration));
        if (t < 0) t = 0;
        if (t > 1) t = 1;
        yMin = kCubeSpawnYMinStart * (1.0f - t) + kCubeSpawnYMinEnd * t;
        yMax = kCubeSpawnYMaxStart * (1.0f - t) + kCubeSpawnYMaxEnd * t;
    }

    private void spawnFallingCube()
    {
        auto spawner = mLevelBuilder.getSpawner();
        if (spawner is null) return;

        vec3[] scales = [
            vec3(1.00f, 1.00f, 1.00f),
            vec3(0.75f, 1.35f, 0.75f),
            vec3(1.35f, 0.65f, 0.65f)
        ];

        vec3[] colors = [
            vec3(0.94f, 0.58f, 0.17f),
            vec3(0.45f, 0.85f, 0.38f),
            vec3(0.35f, 0.75f, 1.00f)
        ];

        int idx = uniform(0, cast(int)scales.length);

        float yMin, yMax;
        rampedSpawnY(yMin, yMax);

        float x = uniform(-6.0f, 38.0f);
        float z = uniform(-42.0f, 4.0f);
        float y = uniform(yMin, yMax);

        uint eid = spawner.spawnChallengeProjectile(
            vec3(x, y, z),
            scales[idx],
            colors[idx],
            "cube.urdf"
        );

        mChallengeTargets ~= ChallengeTarget(eid, kTargetLifetime);
        mActiveTargetIds[eid] = true;
    }

    private void updateChallengeCubes(double dt)
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

    private void removeChallengeCube(uint entityId)
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

    private void clearAllCubes()
    {
        foreach (t; mChallengeTargets)
            destroyEntity(t.entityId);
        mChallengeTargets.length = 0;
        mActiveTargetIds = null;
    }

    //================================================================
    // Jackpot enemies
    //================================================================
    private void trySpawnEnemy()
    {
        if (mLevelBuilder.mEnemySpawnPool.length == 0)
        {
            writeln("[enemy] no spawn pool positions available");
            return;
        }

        // Find an unused pool slot. Up to 20 tries to avoid infinite loops
        // when the pool is small and mostly full.
        size_t chosen = size_t.max;
        foreach (attempt; 0 .. 20)
        {
            size_t idx = uniform(0, mLevelBuilder.mEnemySpawnPool.length);
            if ((idx in mEnemyPoolInUse) is null)
            {
                chosen = idx;
                break;
            }
        }
        if (chosen == size_t.max) return;

        vec3 pos = mLevelBuilder.mEnemySpawnPool[chosen];

        auto spawner = mLevelBuilder.getSpawner();
        if (spawner is null) return;

        uint eid = spawner.spawnEnemyAt(pos);

        // Register enemy
        ChallengeEnemy e;
        e.entityId = eid;
        e.positionIndex = chosen;
        e.aliveTime = 0;
        mEnemies ~= e;
        mEnemyBoxIndexByEid[eid] = mEnemies.length - 1;
        mSoldierIds[eid] = true;
        mEnemyPoolInUse[chosen] = true;

        // Collision box for the enemy — bumped to 1.0 half-size so shots feel fair.
        float sh = 1.0f;
        mCollisionEditor.addBoxForEntity(eid,
            pos.x - sh, pos.z - sh, pos.x + sh, pos.z + sh,
            "enemy_" ~ eid.to!string);

        writeln("[enemy] spawned eid=", eid,
            " at (", pos.x, ",", pos.z, ") alive=", mEnemies.length);
    }

    private void updateEnemies(double dt)
    {
        foreach (ref e; mEnemies)
            e.aliveTime += dt;
    }

    private void removeEnemyByEntity(uint eid)
    {
        auto idxPtr = eid in mEnemyBoxIndexByEid;
        if (idxPtr is null) return;
        size_t idx = *idxPtr;
        if (idx >= mEnemies.length) return;

        // Swap-and-pop
        size_t last = mEnemies.length - 1;
        if (idx != last)
        {
            mEnemies[idx] = mEnemies[last];
            // fix up the swapped element's index
            mEnemyBoxIndexByEid[mEnemies[idx].entityId] = idx;
        }
        mEnemies.length = mEnemies.length - 1;
        mEnemyBoxIndexByEid.remove(eid);
    }

    private void clearAllEnemies()
    {
        foreach (e; mEnemies)
            destroyEntity(e.entityId);
        mEnemies.length = 0;
        mEnemyBoxIndexByEid = null;
        mSoldierIds = null;
        mEnemyPoolInUse = null;
    }

    //================================================================
    // Phase transitions
    //================================================================
    private void startChallengeRound()
    {
        clearAllCubes();
        clearAllEnemies();

        mPlayerName = mGui.enteredName();
        if (mPlayerName.length == 0) mPlayerName = "Player";

        mShotsFired = 0;
        mShotsHit   = 0;
        mCubesHit   = 0;
        mEnemiesKilled = 0;
        mScore      = 0;
        mCurrentAmmo = mMaxAmmo;
        mRoundTimer  = kChallengeDuration;
        mTargetSpawnAccumulator = 0.0;
        mEnemySpawnTimer = 0.0;
        mNextEnemySpawnIn = uniform(kEnemySpawnMinInterval, kEnemySpawnMaxInterval);
        resetCombo();

        mPhase = ChallengePhase.Live;
        mGui.phase = mPhase;
        mGui.playerName = mPlayerName;

        writeln("[challenge] started for ", mPlayerName);
    }

    private void finishChallengeRound()
    {
        if (mPhase != ChallengePhase.Live) return;

        clearAllCubes();
        clearAllEnemies();

        mLeaderboard.addScore(mPlayerName, mScore, mShotsFired, mShotsHit);
        mGui.leaderboard = mLeaderboard.top10();

        mPhase = ChallengePhase.Results;
        mGui.phase = mPhase;
        mGui.finalScore = mScore;

        writeln("[challenge] finished for ", mPlayerName, " score=", mScore);
    }

    //================================================================
    // Cursor / input gating
    //================================================================
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

    //================================================================
    // Spread
    //================================================================
    private float computeWeaponSpread()
    {
        if (mIsSprinting) return 0.055f;
        if (mIsMoving)    return 0.030f;
        return 0.008f;
    }

    //================================================================
    // Crosshair
    //================================================================
    void drawCrosshair()
    {
        if (!mCrosshairReady) return;

        glDisable(GL_DEPTH_TEST);
        glUseProgram(Pipeline.sPipeline["crosshair"]);
        glBindVertexArray(mCrosshairVAO);
        glLineWidth(2.0f);
        glDrawArrays(GL_LINES, 0, 8);
        glBindVertexArray(0);
        glEnable(GL_DEPTH_TEST);
    }

    void initCrosshair()
    {
        new Pipeline("crosshair",
            "./pipelines/crosshair/crosshair.vert",
            "./pipelines/crosshair/crosshair.frag");

        float size = 0.03f;
        float gap  = 0.008f;

        float[] verts = [
            -size, 0.0f,  -gap,  0.0f,
             gap,  0.0f,   size, 0.0f,
             0.0f, size,   0.0f, gap,
             0.0f, -gap,   0.0f, -size
        ];

        glGenVertexArrays(1, &mCrosshairVAO);
        glGenBuffers(1, &mCrosshairVBO);

        glBindVertexArray(mCrosshairVAO);
        glBindBuffer(GL_ARRAY_BUFFER, mCrosshairVBO);
        glBufferData(GL_ARRAY_BUFFER,
            verts.length * float.sizeof,
            verts.ptr, GL_STATIC_DRAW);
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, null);
        glBindVertexArray(0);

        mCrosshairReady = true;
    }

    //================================================================
    // Physics/collision queries
    //================================================================
    private void checkCollisions()
    {
        if ((mCubeEntity in mPhysicsWorld.entityToBody) is null) return;
        if ((mGroundEntity in mPhysicsWorld.entityToBody) is null) return;

        b3ContactInformation contactInfo;
        mPhysicsWorld.getContacts(mCubeEntity, mGroundEntity, contactInfo);
    }

    void printSpawnPoint(string type)
    {
        auto pos = mCamera.mEyePosition;
        writeln("[spawn-marker] ", type, " at <", pos.x, ",", pos.y, ",", pos.z, ">");
    }

    //================================================================
    // Entity destruction — also drops any collision box bound to the entity
    //================================================================
    void destroyEntity(uint entityId)
    {
        // Collision box first
        if (mCollisionEditor !is null)
            mCollisionEditor.removeBoxForEntity(entityId);

        // Physics body
        if (entityId in mPhysicsWorld.entityToBody)
            mPhysicsWorld.removeBody(entityId);

        // Scene graph nodes
        if (auto nodes = entityId in mEntityManager.renderables)
        {
            foreach (node; *nodes)
            {
                auto parent = node.GetParentSceneNode();
                if (parent !is null)
                {
                    ISceneNode[] remaining;
                    foreach (child; parent.mChildren)
                        if (child !is node) remaining ~= child;
                    parent.mChildren = remaining;
                }
            }
        }

        // Entity manager
        mEntityManager.destroy(entityId);
        writeln("[destroy] entity=", entityId);
    }
}