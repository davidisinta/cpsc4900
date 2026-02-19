module bullet_c_api;

extern(C)
{
    //this is saying b3PhysicsClientHandle is another name for void*
    // that is i can use the name b3PhysicsClient handle instead of void*
    alias b3PhysicsClientHandle = void*;
    alias b3SharedMemoryCommandHandle = void*;

    // --- Connection/lifecycle ---
    // Note: collision.d uses alias b3PhysicsClientHandle = void*;
    b3PhysicsClientHandle b3ConnectPhysicsDirect();
    void b3DisconnectSharedMemory(b3PhysicsClientHandle physClient);

    // --- Command submission / status ---
    void* b3SubmitClientCommandAndWaitStatus(b3PhysicsClientHandle physClient, b3SharedMemoryCommandHandle commandHandle);
    int b3GetStatusType(void* statusHandle);
    int b3GetStatusBodyIndex(void* statusHandle);

    // --- Reset / physics params ---
    b3SharedMemoryCommandHandle b3InitResetSimulationCommand(b3PhysicsClientHandle physClient);

    b3SharedMemoryCommandHandle b3InitPhysicsParamCommand(b3PhysicsClientHandle physClient);
    int b3PhysicsParamSetGravity(b3SharedMemoryCommandHandle cmd, double gx, double gy, double gz);
    int b3PhysicsParamSetTimeStep(b3SharedMemoryCommandHandle cmd, double dt);

    // --- Search path + URDF loading ---
    b3SharedMemoryCommandHandle b3SetAdditionalSearchPath(b3PhysicsClientHandle physClient, const(char)* path);

    b3SharedMemoryCommandHandle b3LoadUrdfCommandInit(b3PhysicsClientHandle physClient, const(char)* urdfFileName);
    int b3LoadUrdfCommandSetStartPosition(b3SharedMemoryCommandHandle cmd, double x, double y, double z);
    int b3LoadUrdfCommandSetStartOrientation(b3SharedMemoryCommandHandle cmd, double x, double y, double z, double w);

    // --- Step simulation ---
    b3SharedMemoryCommandHandle b3InitStepSimulationCommand(b3PhysicsClientHandle physClient);
}
