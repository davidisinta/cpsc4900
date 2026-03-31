module physics_sim;

//standard library files
import std.stdio;
import std.datetime.stopwatch : StopWatch, AutoStart;
import std.datetime : dur;
import core.thread : Thread;

//project libraries
import physicsworld;

/**
 * Minimal URDF-based physics smoke test.
 *
 * Validates:
 *  - PhysicsWorld initializes (connect/reset/params/search path)
 *  - addURDF loads URDFs and populates entity<->body mappings
 *  - updatePhysics steps repeatedly without throwing
 *
 * Notes:
 *  - This does not verify collisions via contact queries yet.
 *  - Requires that PhysicsWorld.setSearchPath() points to a directory
 *    containing plane.urdf and cube.urdf (your default ../bullet3/data).
 */
bool runPhysicsSimSmokeTestURDF(
    double secondsToRun = 5.0,
    double fps = 60.0,
    string planeUrdf = "plane.urdf",
    string cubeUrdf  = "cube.urdf")
{
    writeln("[physics_sim] starting URDF smoke test...");

    PhysicsWorld world = PhysicsWorld("physics-sim-urdf");

    enum uint PLANE_ENTITY = 1;
    enum uint CUBE_ENTITY  = 2;

    // Spawn plane at origin
    world.addURDF(
        PLANE_ENTITY,
        planeUrdf,
        0.0, 0.0, 0.0,      // position
        0.0, 0.0, 0.0, 1.0  // orientation (identity quat)
    );

    // Spawn cube above plane so it falls
    world.addURDF(
        CUBE_ENTITY,
        cubeUrdf,
        0.0, 0.0, 1.5,      // position
        0.0, 0.0, 0.0, 1.0  // orientation
    );

    // Mapping sanity checks
    auto pPlane = PLANE_ENTITY in world.entityToBody;
    auto pCube  = CUBE_ENTITY  in world.entityToBody;

    if (pPlane is null)
        throw new Exception("[physics_sim] entityToBody missing PLANE_ENTITY after addURDF");
    if (pCube is null)
        throw new Exception("[physics_sim] entityToBody missing CUBE_ENTITY after addURDF");

    int planeBodyId = *pPlane;
    int cubeBodyId  = *pCube;

    writeln("[physics_sim] mapping ok:");
    writeln("  plane entity=", PLANE_ENTITY, " -> bodyId=", planeBodyId);
    writeln("  cube  entity=", CUBE_ENTITY,  " -> bodyId=", cubeBodyId);

    const double frameDt = 1.0 / fps;
    const long heartbeatEvery = cast(long)(fps); // once per second

    StopWatch sw = StopWatch(AutoStart.yes);
    long frames = 0;

    while (sw.peek.total!"seconds" < secondsToRun)
    {
        world.updatePhysics(frameDt);
        frames++;

        // cheap invariants once per second
        if (frames % heartbeatEvery == 0)
        {
            auto pPlaneNow = PLANE_ENTITY in world.entityToBody;
            auto pCubeNow  = CUBE_ENTITY  in world.entityToBody;

            if (pPlaneNow is null || pCubeNow is null)
                throw new Exception("[physics_sim] mapping disappeared during stepping");

            if (*pPlaneNow != planeBodyId || *pCubeNow != cubeBodyId)
                throw new Exception("[physics_sim] mapping changed unexpectedly during stepping");

            writeln("[physics_sim] stepped ", frames, " frames...");
        }

        // Avoid busy-spin
        Thread.sleep(dur!"msecs"(cast(int)(1000.0 / fps)));
    }

    writeln("[physics_sim] done. total frames=", frames);
    return true;
}
