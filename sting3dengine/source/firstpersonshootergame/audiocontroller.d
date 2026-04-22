/// Manages all game audio: loading, playing, stopping sounds
module audiocontroller;

import std.stdio;
import std.string : toStringz;
import audiosubsystem;

class AudioController
{
    FMOD_SYSTEM* mSystem;
    AudioEngine* mAudio;

    // Sound handles
    FMOD_SOUND* mWalkingSound;
    FMOD_SOUND* mPistolSound;
    FMOD_SOUND* mBackgroundSound;

    // Channel handles
    FMOD_CHANNEL* mWalkingChannel;
    FMOD_CHANNEL* mPistolChannel;
    FMOD_CHANNEL* mBackgroundChannel;

    // State
    bool mWalkingSoundPlaying = false;
    bool mBackgroundPlaying = false;

    void attach(AudioEngine* audio)
    {
        mAudio = audio;
        mSystem = audio.mSystem;
        loadSounds();
    }

    void loadSounds()
    {
        auto r1 = FMOD_System_CreateSound(mSystem,
            "./assets/sounds/footsteps_walking_gravel_01_loop.wav".toStringz,
            FMOD_LOOP_NORMAL | FMOD_2D, null, &mWalkingSound);
        writeln("[audio] walk sound: ", r1);

        auto r2 = FMOD_System_CreateSound(mSystem,
            "./assets/sounds/gun_22_pistol_04.wav".toStringz,
            FMOD_LOOP_OFF | FMOD_2D, null, &mPistolSound);
        writeln("[audio] pistol sound: ", r2);

        auto r3 = FMOD_System_CreateSound(mSystem,
            "./assets/sounds/war_ambience_01_30_loop.wav".toStringz,
            FMOD_LOOP_NORMAL | FMOD_2D | FMOD_CREATESTREAM, null, &mBackgroundSound);
        writeln("[audio] background sound: ", r3);
    }

    void playGunshot()
    {
        if (mSystem !is null)
            FMOD_System_PlaySound(mSystem, mPistolSound, null, 0, &mPistolChannel);
    }

    void startWalking()
    {
        if (!mWalkingSoundPlaying)
        {
            FMOD_System_PlaySound(mSystem, mWalkingSound, null, 0, &mWalkingChannel);
            mWalkingSoundPlaying = true;
        }
    }

    void stopWalking()
    {
        if (mWalkingSoundPlaying)
        {
            if (mWalkingChannel !is null)
                FMOD_Channel_Stop(mWalkingChannel);
            mWalkingChannel = null;
            mWalkingSoundPlaying = false;
        }
    }

    void startBackground()
    {
        if (!mBackgroundPlaying && mBackgroundSound !is null)
        {
            FMOD_System_PlaySound(mSystem, mBackgroundSound, null, 0, &mBackgroundChannel);
            mBackgroundPlaying = true;
        }
    }

    void stopBackground()
    {
        if (mBackgroundChannel !is null)
        {
            FMOD_Channel_Stop(mBackgroundChannel);
            mBackgroundChannel = null;
            mBackgroundPlaying = false;
        }
    }
}
