# FMOD Basics for a Custom Game Engine

## What is FMOD?
FMOD is a **professional audio middleware** used in many commercial games to handle sound playback, mixing, 3D spatialization, streaming, and DSP — without blocking gameplay.

It consists of:
- **FMOD Studio**: Audio authoring tool (design sounds, events, parameters)
- **FMOD Runtime API**: C/C++ API used inside your engine

---

## Why FMOD Is Useful in a Game Engine

- Non-blocking audio (gameplay never stops)
- Built-in audio thread & mixer
- High-quality 3D spatial audio
- Event-based system (clean separation of code & sound design)
- Cross-platform (Windows, macOS, Linux, consoles)
- Used in FPS, AAA, and indie games

For an FPS or Aimlabs-style game, FMOD handles:
- Gunshots
- Reload sounds
- Footsteps
- Spatial awareness (direction + distance)
- Background music

---

## High-Level Architecture

```
Game Code
 ├── WeaponSystem
 ├── PlayerController
 ├── Physics
 └── Render
        |
        v
Engine Audio Layer
 ├── AudioSystem
 ├── AudioEvent
 ├── AudioListener
        |
        v
FMOD Runtime (audio thread)
```

Your engine owns **when & where** sounds happen.  
FMOD owns **how** they sound.

---

## FMOD Runtime Workflow

1. Initialize FMOD
2. Load bank files
3. Play events (non-blocking)
4. Update listener every frame
5. Call `system->update()` once per frame
6. Shutdown on exit

---

## Minimal C++ Example (Engine Side)

### Initialization
```cpp
FMOD::Studio::System* studio = nullptr;

FMOD::Studio::System::create(&studio);
studio->initialize(
    1024,
    FMOD_STUDIO_INIT_NORMAL,
    FMOD_INIT_3D_RIGHTHANDED,
    nullptr
);
```

### Load Banks
```cpp
studio->loadBankFile("Master.bank", FMOD_STUDIO_LOAD_BANK_NORMAL, &master);
studio->loadBankFile("Master.strings.bank", FMOD_STUDIO_LOAD_BANK_NORMAL, &strings);
```

### Play a 3D Event
```cpp
FMOD::Studio::EventInstance* inst = nullptr;
studio->getEvent("event:/Weapons/Gunshot", &desc);
desc->createInstance(&inst);

FMOD_3D_ATTRIBUTES a{};
a.position = { x, y, z };
a.forward  = { 0, 0, 1 };
a.up       = { 0, 1, 0 };

inst->set3DAttributes(&a);
inst->start();
inst->release();
```

### Listener Update (Every Frame)
```cpp
FMOD_3D_ATTRIBUTES listener{};
listener.position = { camX, camY, camZ };
listener.forward  = { fx, fy, fz };
listener.up       = { ux, uy, uz };

studio->setListenerAttributes(0, &listener);
studio->update();
```

---

## How This Maps to a Game Engine

### AudioSystem (Engine-Owned)
- Initializes FMOD
- Loads banks
- Calls `update()`
- Manages shutdown

### AudioEvent
- Wraps FMOD EventInstance
- Play / Stop / SetPosition

### AudioListener
- Bound to camera or player

Game code never directly calls FMOD.

---

## Integrating FMOD with a D Language Project

### Option 1: C ABI Wrapper (Recommended)

1. Write a small C/C++ wrapper around FMOD
2. Expose C-style functions
3. Call from D using `extern(C)`

Example C wrapper:
```c
extern "C" void playGunshot(float x, float y, float z);
```

Example D call:
```d
extern(C) void playGunshot(float x, float y, float z);

playGunshot(px, py, pz);
```

This keeps FMOD isolated and avoids C++ ABI headaches.

---

### Option 2: Direct C++ Binding (Advanced)
- Possible but fragile
- Requires compiler & ABI matching
- Not recommended early

---

## Pros of FMOD

- Rock-solid, production proven
- Non-blocking audio by default
- Excellent 3D spatial audio
- Great tooling (FMOD Studio)
- Easy to scale from MVP → full game

---

## Cons of FMOD

- Closed source
- Licensing required for commercial release
- Adds external dependency
- Slightly heavier than OpenAL/miniaudio

---

## When FMOD Is the Right Choice

- FPS or action game
- Sound design matters
- You want zero audio stalls
- You don’t want to build audio threading yourself

---

## When It’s Overkill

- Very small demos
- Pure learning projects
- Games with minimal sound needs

---

## Final Recommendation

For a custom 3D FPS engine:
- Use FMOD for audio
- Wrap it cleanly behind your own AudioSystem
- Focus engine time on rendering, physics, and gameplay feel

FMOD solves audio so you don’t have to.

---
