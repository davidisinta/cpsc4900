module physicsworld;

//standard library files
import std.stdio;
import std.string : toStringz;
import std.datetime.stopwatch : StopWatch, AutoStart;
import core.thread : Thread;
import std.conv : to;
import std.datetime : dur;
import std.file : exists;
import std.path : buildPath;
import std.process : environment;

//project libraries
import bullet_c_api;
import types;
import statuscodes;

//------------------------------------------------------------------------
// Main Physics World:
//------------------------------------------------------------------------
struct PhysicsWorld{

    b3PhysicsClientHandle mClient;
    // fixed timestep
    double mFixedDt = 1.0 / 60.0;
    string mWorldname;
    double mAccumulator = 0.0;
    string mDataPath = "assets/urdf";

    // Engine mapping
    // This is very important because Bullet only knows about physics body IDs, while your engine operates on game entities, so you need a fast way to link the two worlds.
    // When a collision or physics update happens, this lets you instantly convert a Bullet body ID → engine entity (and vice versa) so you can apply gameplay logic, rendering updates, or events to the correct game object.
    int[uint] entityToBody;   // Entity -> bodyId
    uint[int] bodyToEntity;   // bodyId -> Entity

    this(string worldName){

        mWorldname = worldName;
        mClient = b3ConnectPhysicsDirect();

        if (mClient is null){
            throw new Exception("b3ConnectPhysicsDirect returned null");
        }

        resetSim();
        setSearchPath();
        setPhysicsParams();
    }

    // --------------------------------------------------------
    // Bullet setup helpers
    // --------------------------------------------------------

    // clears simulation state inside bullet
    void resetSim()
    {
        auto cmd = b3InitResetSimulationCommand(mClient);
        auto st  = b3SubmitClientCommandAndWaitStatus(mClient, cmd);
        auto ty  = b3GetStatusType(st);
        if (ty != EnumSharedMemoryServerStatus.CMD_RESET_SIMULATION_COMPLETED){
            throw new Exception("resetSim failed: statusType=" ~ ty.to!string);
        }    
    }

    void setSearchPath(){
        string dataPath = "assets/urdf";

        // Print current working directory (cwd)
        auto cwd = environment.get("PWD", "<unknown>");
        writeln("[PhysicsWorld] PWD = ", cwd);
        writeln("[PhysicsWorld] searchPath = ", dataPath);

        // Probe expected file
        string probe = buildPath(dataPath, "plane.urdf");
        writeln("[PhysicsWorld] probe: ", probe, " exists=", exists(probe));

        auto cmd = b3SetAdditionalSearchPath(mClient, dataPath.toStringz());
        b3SubmitClientCommandAndWaitStatus(mClient, cmd);
    }

    void setPhysicsParams()
    {
        auto cmd = b3InitPhysicsParamCommand(mClient);
        b3PhysicsParamSetGravity(cmd, 0.0, 0.0, -9.81);
        b3PhysicsParamSetTimeStep(cmd, mFixedDt);
        b3SubmitClientCommandAndWaitStatus(mClient, cmd);
    }

    /**
    * Physics must advance using a FIXED timestep rather than render frame dt.
    *
    * Rendering runs at variable frequency (FPS fluctuates), but numerical
    * integration used by physics solvers assumes a constant Δt.
    *
    * If we step physics directly using frame dt:
    *   - simulation becomes non-deterministic
    *   - collisions become unstable or tunnel
    * Instead:
    *   1. Accumulate real elapsed frame time.
    *   2. Advance physics in multiple fixed-size steps (mFixedDt).
    *   3. Consume accumulated time gradually.
    * This decouples:
    *      Render Rate  ≠  Simulation Rate
    */
    void updatePhysics(double frameDt)
    {
        // Clamp to avoid huge dt after pause/debug
        if (frameDt > 0.25) frameDt = 0.25;

        mAccumulator += frameDt;

        // Step with fixed dt
        int maxSubSteps = 8;
        int steps = 0;

        while (mAccumulator >= mFixedDt && steps < maxSubSteps)
        {
            stepOnce();
            mAccumulator -= mFixedDt;
            steps++;
        }

        // if steps == maxSubSteps, drop remainder to avoid spiral
        if (steps == maxSubSteps) mAccumulator = 0.0;
    }

    /**
    * Executes exactly ONE deterministic physics simulation step.
    *
    * This represents advancing the physics world forward by mFixedDt
    * seconds using Bullet's internal solver pipeline:
    *
    *   Broadphase  →  Narrowphase  →  Contact generation
    *   → Constraint solving → Integration → State update
    *
    * Important:
    *   - This function MUST NOT depend on frame timing.
    *   - It performs a single authoritative world update.
    *
    * updatePhysics() decides HOW MANY times this runs;
    * stepOnce() defines WHAT a single simulation advance means.
    */
    private void stepOnce()
    {
        auto cmd = b3InitStepSimulationCommand(mClient);
        auto st  = b3SubmitClientCommandAndWaitStatus(mClient, cmd);
        auto ty  = b3GetStatusType(st);
        if (ty != EnumSharedMemoryServerStatus.CMD_STEP_FORWARD_SIMULATION_COMPLETED)
            throw new Exception("stepPhysics failed: statusType=" ~ ty.to!string);
    }

    void setGravity(double gx, double gy, double gz) {
        // wrapper around command API

        //allocate a command
        auto cmd = b3InitPhysicsParamCommand(mClient);

        //write parameters into allocated command
        auto ok  = b3PhysicsParamSetGravity(cmd, gx, gy, gz);

        // if Bullet returns 0 on failure for this setter, guard it.
        if (ok == 0)
            throw new Exception("b3PhysicsParamSetGravity failed (returned 0)");

        //submit command and wait for status
        auto st = b3SubmitClientCommandAndWaitStatus(mClient, cmd);

        //Validate status type
        auto status_type = b3GetStatusType(st);
        if (!isPhysicsParamSuccess(status_type))
        throw new Exception("setGravity failed: statusType=" ~ status_type.to!string);
    }

    bool isPhysicsParamSuccess(int status_type){

        return status_type == EnumSharedMemoryServerStatus.CMD_REQUEST_PHYSICS_SIMULATION_PARAMETERS_COMPLETED
            || status_type == EnumSharedMemoryServerStatus.CMD_CLIENT_COMMAND_COMPLETED;
    }

    //---------------------------------------------------------------------
    // Body Creation and Removal functions
    //---------------------------------------------------------------------
    private void bindEntityToBody(uint entityId, int bodyId)
    {
        entityToBody[entityId] = bodyId;
        bodyToEntity[bodyId] = entityId;
    }

    private void unbindEntity(uint entityId)
    {
        if (auto p = entityId in entityToBody)
        {
            int bodyId = *p;
            entityToBody.remove(entityId);
            bodyToEntity.remove(bodyId);
        }
    }

    private void requireClient()
    {
        if (mClient is null)
            throw new Exception(mWorldname ~ ": PhysicsWorld client is null (disconnected?)");
    }
    
    uint addURDF(uint entityId, string urdfFile, double px = 0, double py = 0,double pz = 0, double qx = 0, double qy = 0, double qz = 0, double qw = 1.0){
        requireClient();

        auto cmd = b3LoadUrdfCommandInit(mClient, urdfFile.toStringz());

        if (cmd is null){
            throw new Exception(mWorldname ~ ": b3LoadUrdfCommandInit failed");
        }
    
        b3LoadUrdfCommandSetStartPosition(cmd, px, py, pz);
        b3LoadUrdfCommandSetStartOrientation(cmd, qx, qy, qz, qw);

        auto st = b3SubmitClientCommandAndWaitStatus(mClient, cmd);
        int ty = b3GetStatusType(st);

        if (ty != EnumSharedMemoryServerStatus.CMD_URDF_LOADING_COMPLETED){
            throw new Exception( mWorldname ~ ": URDF load failed status=" ~ ty.to!string);
        }

        int bodyId = b3GetStatusBodyIndex(st);

        if (bodyId < 0){
            throw new Exception(mWorldname ~ ": invalid bodyId");
        }
        
        bindEntityToBody(entityId, bodyId);
        return entityId;
    }

    //---------------------------------------------------------------------
    // 
    //---------------------------------------------------------------------

    void shutdown() {
        if (mClient !is null) {
            b3DisconnectSharedMemory(mClient);
            mClient = null;
        }
    }

    ~this(){
        shutdown();

    }

} //end struct