module physicsworld;

//standard library files
import std.stdio;
import std.string : toStringz;
import std.datetime.stopwatch : StopWatch, AutoStart;
import core.thread : Thread;
import std.conv : to;
import std.datetime : dur;

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

    void setSearchPath()
    {
        string dataPath = "../bullet3/data";
        auto cmd = b3SetAdditionalSearchPath(mClient, dataPath.toStringz());
        // Not all commands return a special status code; we just submit.
        b3SubmitClientCommandAndWaitStatus(mClient, cmd);
    }

    void setPhysicsParams()
    {
        auto cmd = b3InitPhysicsParamCommand(mClient);
        b3PhysicsParamSetGravity(cmd, 0.0, 0.0, -9.81);
        b3PhysicsParamSetTimeStep(cmd, mFixedDt);
        b3SubmitClientCommandAndWaitStatus(mClient, cmd);
    }

    // Advance the world forward by Δt seconds and update all physics
    void updatePhysics()
    {
        auto cmd = b3InitStepSimulationCommand(mClient);
        auto st  = b3SubmitClientCommandAndWaitStatus(mClient, cmd);
        auto ty  = b3GetStatusType(st);
        if (ty != EnumSharedMemoryServerStatus.CMD_STEP_FORWARD_SIMULATION_COMPLETED)
            throw new Exception("stepPhysics failed: statusType=" ~ ty.to!string);
    }

    void setGravity(float gx, float gy, float gz) {
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