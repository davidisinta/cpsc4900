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

    // Engine mapping
    // This is very important because Bullet only knows about physics body IDs, while your engine operates on game entities, so you need a fast way to link the two worlds.
    // When a collision or physics update happens, this lets you instantly convert a Bullet body ID → engine entity (and vice versa) so you can apply gameplay logic, rendering updates, or events to the correct game object.
    int[uint] entityToBody;   // Entity -> bodyId
    uint[int] bodyToEntity;   // bodyId -> Entity

    this(string worldName){
        mClient = b3ConnectPhysicsDirect();
        resetSim();
    }

    // --------------------------------------------------------
    // Bullet setup helpers
    // --------------------------------------------------------
    void resetSim()
    {
        auto cmd = b3InitResetSimulationCommand(mClient);
        auto st  = b3SubmitClientCommandAndWaitStatus(mClient, cmd);
        auto ty  = b3GetStatusType(st);
        if (ty != CMD_RESET_SIMULATION_COMPLETED){
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
        if (ty != CMD_STEP_FORWARD_SIMULATION_COMPLETED)
            throw new Exception("stepPhysics failed: statusType=" ~ ty.to!string);
    }

    void setGravity(float x, float y, float z) {
        // wrapper around command API
    }

    void shutdown() {
        if (mClient !is null) {
            b3DisconnectSharedMemory(mClient);
            mClient = null;
        }
    }

} //end struct