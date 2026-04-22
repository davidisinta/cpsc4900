module audioengine;

import std.stdio;
import std.string : toStringz;
import fmod_c_api;

struct AudioEngine
{
    FMOD_SYSTEM* mSystem;
    FMOD_SOUND*[string] mSoundCache;

    void init()
    {
        auto result = FMOD_System_Create(&mSystem, FMOD_VERSION);
        if (result != FMOD_OK)
        {
            writeln("[audio] FMOD_System_Create failed: ", result);
            return;
        }

        result = FMOD_System_Init(mSystem, 64, 0, null);
        if (result != FMOD_OK)
        {
            writeln("[audio] FMOD_System_Init failed: ", result);
            return;
        }

        writeln("[audio] FMOD initialized successfully");
    }

    /// Call every frame
    void update()
    {
        if (mSystem !is null)
            FMOD_System_Update(mSystem);
    }

    /// Load a sound file (cached — won't reload if already loaded)
    FMOD_SOUND* loadSound(string path, bool is3D = false, bool loop = false)
    {
        if (auto cached = path in mSoundCache)
            return *cached;

        uint mode = FMOD_DEFAULT;
        if (is3D)
            mode |= FMOD_3D | FMOD_3D_WORLDRELATIVE | FMOD_3D_INVERSEROLLOFF;
        else
            mode |= FMOD_2D;

        if (loop)
            mode |= FMOD_LOOP_NORMAL;
        else
            mode |= FMOD_LOOP_OFF;

        FMOD_SOUND* sound;
        auto result = FMOD_System_CreateSound(mSystem, path.toStringz(), mode, null, &sound);
        if (result != FMOD_OK)
        {
            writeln("[audio] Failed to load sound '", path, "': ", result);
            return null;
        }

        if (is3D)
            FMOD_Sound_Set3DMinMaxDistance(sound, 1.0f, 100.0f);

        mSoundCache[path] = sound;
        writeln("[audio] Loaded: ", path);
        return sound;
    }

    /// Play a 2D sound (music, UI)
    FMOD_CHANNEL* play(string path)
    {
        auto sound = loadSound(path);
        if (sound is null) return null;

        FMOD_CHANNEL* channel;
        FMOD_System_PlaySound(mSystem, sound, null, 0, &channel);
        return channel;
    }

    /// Play a 3D sound at a world position
    FMOD_CHANNEL* play3D(string path, float x, float y, float z)
    {
        auto sound = loadSound(path, true);
        if (sound is null) return null;

        FMOD_CHANNEL* channel;
        FMOD_System_PlaySound(mSystem, sound, null, 1, &channel);  // start paused

        FMOD_VECTOR pos = FMOD_VECTOR(x, y, z);
        FMOD_VECTOR vel = FMOD_VECTOR(0, 0, 0);
        FMOD_Channel_Set3DAttributes(channel, &pos, &vel);

        // Unpause
        import core.stdc.string;
        FMOD_Channel_SetVolume(channel, 1.0f);
        // Resume by re-playing — actually just unpause via a small trick:
        // We started paused=1, now we need to unpause. FMOD doesn't have
        // a direct "unpause" in C API, so we use setPaused:
        // For now, start unpaused instead:
        FMOD_System_PlaySound(mSystem, sound, null, 0, &channel);
        FMOD_Channel_Set3DAttributes(channel, &pos, &vel);

        return channel;
    }

    /// Update 3D listener (call each frame with camera position)
    void setListener(float px, float py, float pz,
                     float fx, float fy, float fz,
                     float ux, float uy, float uz)
    {
        FMOD_VECTOR pos = FMOD_VECTOR(px, py, pz);
        FMOD_VECTOR vel = FMOD_VECTOR(0, 0, 0);
        FMOD_VECTOR fwd = FMOD_VECTOR(fx, fy, fz);
        FMOD_VECTOR up  = FMOD_VECTOR(ux, uy, uz);
        FMOD_System_Set3DListenerAttributes(mSystem, 0, &pos, &vel, &fwd, &up);
    }

    void shutdown()
    {
        foreach (sound; mSoundCache.values)
            FMOD_Sound_Release(sound);
        mSoundCache.clear();

        if (mSystem !is null)
        {
            FMOD_System_Release(mSystem);
            mSystem = null;
        }
        writeln("[audio] FMOD shut down");
    }
}
