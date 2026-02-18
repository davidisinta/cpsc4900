module sound;

//Standard libraries
import std.string;
import std.stdio;

// Third Party libraries
import bindbc.sdl;

interface ISound {

    void playSound();
    void stopSound();
}

// to do: add fmod sound layer
class Sound : ISound {
    private:
        alias SDL_AudioDeviceID = uint;
        
        SDL_AudioDeviceID m_device;

        SDL_AudioSpec m_audioSpec;
        ubyte* m_waveStart;
        uint m_waveLength;

    public:

        this(string filepath) {
            setupDevice(filepath);
        }

        ~this() {
            stopSound();
        }

        void playSound() {
            int status = SDL_QueueAudio(m_device, m_waveStart, m_waveLength);
            SDL_PauseAudioDevice(m_device,false);
        }

        void stopSound() {
            SDL_PauseAudioDevice(m_device, true);
        }

        private void setupDevice(string filepath) {
            if (SDL_LoadWAV(filepath.toStringz(), &m_audioSpec, &m_waveStart, &m_waveLength) == null) {
                throw new Exception("Failed to load WAV file");
            }

            m_device = SDL_OpenAudioDevice(null, 0, &m_audioSpec, null, 0);
            if (m_device == 0) {
                throw new Exception("Failed to open audio device");
            }
        }
}
