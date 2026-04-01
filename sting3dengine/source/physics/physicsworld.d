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
// Body transform result (returned by getBodyTransform)
//------------------------------------------------------------------------
struct BodyTransform{

    double[3] position;     // world-space x, y, z
    double[4] orientation;  // quaternion x, y, z, w
}

//------------------------------------------------------------------------
// Result of a single raycast query
//------------------------------------------------------------------------
struct RaycastResult
{
    bool hit;                // did the ray hit anything?
    uint entityId;           // which engine entity was hit (0 = none)
    double[3] hitPosition;   // world-space hit point
    double[3] hitNormal;     // surface normal at hit point
}

//------------------------------------------------------------------------
// Main Physics World:
//------------------------------------------------------------------------
class PhysicsWorld{

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
    void resetSim(){
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

    void setPhysicsParams(){

        auto cmd = b3InitPhysicsParamCommand(mClient);
        b3PhysicsParamSetGravity(cmd, 0.0,-9.81, 0.0);
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
    void updatePhysics(double frameDt){

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
    private void stepOnce(){

        auto cmd = b3InitStepSimulationCommand(mClient);
        auto st  = b3SubmitClientCommandAndWaitStatus(mClient, cmd);
        auto ty  = b3GetStatusType(st);
        if (ty != EnumSharedMemoryServerStatus.CMD_STEP_FORWARD_SIMULATION_COMPLETED)
            throw new Exception("stepPhysics failed: statusType=" ~ ty.to!string);
    }

    void setGravity(double gx, double gy, double gz){
    
        // allocate a command
        auto cmd = b3InitPhysicsParamCommand(mClient);

        // write parameters into allocated command
        auto ok  = b3PhysicsParamSetGravity(cmd, gx, gy, gz);

        // submit command and wait for status
        auto st = b3SubmitClientCommandAndWaitStatus(mClient, cmd);

        // Validate status type
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
    private void bindEntityToBody(uint entityId, int bodyId){

        entityToBody[entityId] = bodyId;
        bodyToEntity[bodyId] = entityId;
    }

    private void unbindEntity(uint entityId){

        if (auto p = entityId in entityToBody)
        {
            int bodyId = *p;
            entityToBody.remove(entityId);
            bodyToEntity.remove(bodyId);
        }
    }

    private void requireClient(){

        if (mClient is null){
            throw new Exception(mWorldname ~ ": PhysicsWorld client is null (disconnected?)");
        }  
    }
    
    uint addURDF(uint entityId, string urdfFile, double px = 0, double py = 0,double pz=0, double qx = 0, double qy = 0, double qz = 0, double qw = 1.0){
        
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
    // Body state query
    //---------------------------------------------------------------------

    /// Query Bullet for the current world-space transform of a body.
    ///
    /// This calls b3RequestActualStateCommandInit → submit → 
    /// b3GetStatusActualState, and extracts position[3] + quaternion[4]
    /// from the returned actualStateQ array.
    ///
    /// Params:
    ///   entityId = your engine entity ID (looked up in entityToBody)
    ///
    /// Returns:
    ///   BodyTransform with .position and .orientation
    ///
    /// Throws:
    ///   Exception if the entity has no physics body, or the query fails.
    BodyTransform getBodyTransform(uint entityId)
    {
        requireClient();

        auto p = entityId in entityToBody;
        if (p is null){
            throw new Exception(mWorldname ~ ": entity " ~ entityId.to!string ~ " has no physics body");
        }
            

        int bodyId = *p;

        // 1. Build and submit the state query command
        auto cmd = b3RequestActualStateCommandInit(mClient, bodyId);
        auto st  = b3SubmitClientCommandAndWaitStatus(mClient, cmd);
        int ty   = b3GetStatusType(st);

        if (ty != EnumSharedMemoryServerStatus.CMD_ACTUAL_STATE_UPDATE_COMPLETED){
            throw new Exception(mWorldname ~ ": getBodyTransform failed for entity "
                ~ entityId.to!string ~ " statusType=" ~ ty.to!string);
        }
            
        // 2. Extract the state pointer
        const(double)* actualStateQ;
        b3GetStatusActualState(
            st,
            null,             // bodyUniqueId   (don't need)
            null,             // numDofQ         (don't need)
            null,             // numDofU         (don't need)
            null,             // rootLocalInertialFrame (don't need)
            &actualStateQ,    // ← THIS is what we want
            null,             // actualStateQdot (don't need)
            null              // jointReactionForces (don't need)
        );

        if (actualStateQ is null){
            throw new Exception(mWorldname ~ ": actualStateQ is null for entity " ~ entityId.to!string);
        }
            
        // 3. Pack into our return struct
        //    actualStateQ layout for base link:
        //      [0..3]  = position  (x, y, z)
        //      [3..7]  = quaternion (x, y, z, w)
        //      [7..$]  = joint positions (if multi-body)
        BodyTransform bt;
        bt.position    = actualStateQ[0 .. 3];
        bt.orientation = actualStateQ[3 .. 7];
        return bt;
    }



    //---------------------------------------------------------------------
    // Contact queries
    //---------------------------------------------------------------------

    /// Query all contact points between two entities.
    /// Returns the number of contacts found.
    /// contactInfo is filled with the results.
    int getContacts(uint entityIdA, uint entityIdB, ref b3ContactInformation contactInfo)
    {
        requireClient();

        auto pA = entityIdA in entityToBody;
        auto pB = entityIdB in entityToBody;
        if (pA is null)
            throw new Exception(mWorldname ~ ": entity " ~ entityIdA.to!string ~ " has no physics body");
        if (pB is null)
            throw new Exception(mWorldname ~ ": entity " ~ entityIdB.to!string ~ " has no physics body");

        // 1. Build contact query command
        auto cmd = b3InitRequestContactPointInformation(mClient);
        b3SetContactFilterBodyA(cmd, *pA);
        b3SetContactFilterBodyB(cmd, *pB);

        // 2. Submit and validate
        auto st = b3SubmitClientCommandAndWaitStatus(mClient, cmd);
        int ty  = b3GetStatusType(st);

        if (ty != EnumSharedMemoryServerStatus.CMD_CONTACT_POINT_INFORMATION_COMPLETED)
            throw new Exception(mWorldname ~ ": contact query failed, statusType=" ~ ty.to!string);

        // 3. Read results
        b3GetContactPointInformation(mClient, &contactInfo);

        return contactInfo.m_numContactPoints;
    }

    //---------------------------------------------------------------------
    // Raycasting
    //---------------------------------------------------------------------

    RaycastResult raycast(float fromX, float fromY, float fromZ,
                          float toX, float toY, float toZ)
    {
        requireClient();

        auto cmd = b3CreateRaycastCommandInit(mClient,
            fromX, fromY, fromZ,
            toX, toY, toZ);

        auto st = b3SubmitClientCommandAndWaitStatus(mClient, cmd);
        int ty  = b3GetStatusType(st);

        if (ty != EnumSharedMemoryServerStatus.CMD_REQUEST_RAY_CAST_INTERSECTIONS_COMPLETED)
            throw new Exception(mWorldname ~ ": raycast failed, statusType=" ~ ty.to!string);

        b3RaycastInformation rayInfo;
        b3GetRaycastInformation(mClient, &rayInfo);

        RaycastResult result;

        if (rayInfo.m_numRayHits > 0 && rayInfo.m_rayHits !is null)
        {
            auto firstHit = rayInfo.m_rayHits[0];
            int bodyId = firstHit.m_hitObjectUniqueId;

            if (bodyId >= 0)
            {
                result.hit = true;
                result.hitPosition = firstHit.m_hitPositionWorld;
                result.hitNormal   = firstHit.m_hitNormalWorld;

                if (auto p = bodyId in bodyToEntity)
                    result.entityId = *p;
            }
        }

        return result;
    }

    //---------------------------------------------------------------------
    // Shutdown
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
