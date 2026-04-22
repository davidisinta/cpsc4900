module fmod_c_api;

extern(C)
{
    // Opaque handle types
    alias FMOD_SYSTEM = void;
    alias FMOD_SOUND = void;
    alias FMOD_CHANNEL = void;
    alias FMOD_CHANNELGROUP = void;
    alias FMOD_RESULT = int;

    // Version constant — must match the dylib version
    enum FMOD_VERSION = 0x00020300;  // 2.03.xx

    // FMOD_RESULT values
    enum FMOD_OK = 0;

    // FMOD_MODE flags
    enum : uint
    {
        FMOD_DEFAULT         = 0x00000000,
        FMOD_LOOP_OFF        = 0x00000001,
        FMOD_LOOP_NORMAL     = 0x00000002,
        FMOD_2D              = 0x00000008,
        FMOD_3D              = 0x00000010,
        FMOD_CREATESTREAM    = 0x00000080,
        FMOD_3D_WORLDRELATIVE = 0x00000040,
        FMOD_3D_INVERSEROLLOFF = 0x00000100,
    }

    // 3D vector for positions/velocity
    struct FMOD_VECTOR
    {
        float x, y, z;
    }

    // System lifecycle
    FMOD_RESULT FMOD_System_Create(FMOD_SYSTEM** system, uint headerversion);
    FMOD_RESULT FMOD_System_Init(FMOD_SYSTEM* system, int maxchannels, uint flags, void* extradriverdata);
    FMOD_RESULT FMOD_System_Update(FMOD_SYSTEM* system);
    FMOD_RESULT FMOD_System_Release(FMOD_SYSTEM* system);

    // Sound loading
    FMOD_RESULT FMOD_System_CreateSound(FMOD_SYSTEM* system, const(char)* name_or_data, uint mode, void* exinfo, FMOD_SOUND** sound);
    FMOD_RESULT FMOD_Sound_Release(FMOD_SOUND* sound);
    FMOD_RESULT FMOD_Sound_Set3DMinMaxDistance(FMOD_SOUND* sound, float min, float max);

    // Playback
    FMOD_RESULT FMOD_System_PlaySound(FMOD_SYSTEM* system, FMOD_SOUND* sound, FMOD_CHANNELGROUP* channelgroup, int paused, FMOD_CHANNEL** channel);

    // Channel control
    FMOD_RESULT FMOD_Channel_Stop(FMOD_CHANNEL* channel);
    FMOD_RESULT FMOD_Channel_SetVolume(FMOD_CHANNEL* channel, float volume);
    FMOD_RESULT FMOD_Channel_IsPlaying(FMOD_CHANNEL* channel, int* isplaying);
    FMOD_RESULT FMOD_Channel_Set3DAttributes(FMOD_CHANNEL* channel, const(FMOD_VECTOR)* pos, const(FMOD_VECTOR)* vel);

    // 3D listener
    FMOD_RESULT FMOD_System_Set3DListenerAttributes(FMOD_SYSTEM* system, int listener, const(FMOD_VECTOR)* pos, const(FMOD_VECTOR)* vel, const(FMOD_VECTOR)* forward, const(FMOD_VECTOR)* up);
}
