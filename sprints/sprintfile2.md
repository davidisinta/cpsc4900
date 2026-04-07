# Next Steps — FPS Game Engine

## 1. FMOD Audio System

### Overview

FMOD is a professional audio engine used in games like Fortnite, Celeste, and Hollow Knight. It ships as a prebuilt dylib with a C API — no compilation needed. You download it, drop the dylib in your project, and write D bindings.

### What FMOD Gives You

- **3D spatial audio** — sounds have a position in the world. A gunshot to your left sounds louder in your left ear. FMOD handles the math (attenuation, panning, doppler) automatically.
- **Channel management** — you can play dozens of sounds simultaneously without worrying about mixing. FMOD handles priority, voice stealing, and volume balancing.
- **Streaming** — background music and ambient loops are streamed from disk, not loaded entirely into memory.
- **DSP effects** — reverb, low-pass filters, echo. You can make indoor areas sound different from outdoor areas with a single parameter change.

### Integration Plan

#### Setup (Day 1 morning)

```
1. Download FMOD Core API from fmod.com (free for development < $200k revenue)
2. Copy libfmod.dylib to third_party/fmod/lib/
3. Copy fmod.h and fmod_common.h to third_party/fmod/include/ (for reference)
4. Add dylib to your linker flags in dub.json
```

#### D Bindings — Core Functions Needed

```d
// source/audio/fmod_c_api.d
module fmod_c_api;

// Handle types
alias FMOD_SYSTEM*  = void*;
alias FMOD_SOUND*   = void*;
alias FMOD_CHANNEL* = void*;

// The ~20 functions you actually need:
extern(C) {
    // System lifecycle
    int FMOD_System_Create(FMOD_SYSTEM** system, uint version_);
    int FMOD_System_Init(FMOD_SYSTEM* system, int maxchannels, uint flags, void* extradriverdata);
    int FMOD_System_Update(FMOD_SYSTEM* system);  // MUST call every frame
    int FMOD_System_Release(FMOD_SYSTEM* system);

    // Sound loading
    int FMOD_System_CreateSound(FMOD_SYSTEM* system, const(char)* filename, uint mode, void* exinfo, FMOD_SOUND** sound);
    int FMOD_Sound_Release(FMOD_SOUND* sound);

- [X] Wire mouse click to raycast from camera position along forward vector
- [X] On hit, destroy target entity (remove from Bullet, EntityManager, SceneTree)
  - Bind `b3InitRemoveBodyCommand` in `bullet_c_api.d`
  - Add `removeBody(uint entityId)` to `PhysicsWorld`
- [X] Spawn 10 cubes at various positions as targets
- [X] Add crosshair (ImGui overlay or OpenGL screen-space quad)
- [X] Add hit counter: track shots fired, shots hit
- [X] Print accuracy to console on each shot

    // 3D audio
    int FMOD_System_Set3DListenerAttributes(FMOD_SYSTEM* system, int listener,
        const(float)* pos, const(float)* vel, const(float)* forward, const(float)* up);
    int FMOD_Channel_Set3DAttributes(FMOD_CHANNEL* channel, const(float)* pos, const(float)* vel);
    int FMOD_Sound_Set3DMinMaxDistance(FMOD_SOUND* sound, float min, float max);
}
```

#### AudioEngine Struct

```d
// source/audio/audioengine.d
struct AudioEngine {
    FMOD_SYSTEM* mSystem;

    // Sound cache — avoid loading the same file twice
    FMOD_SOUND*[string] mSounds;

    void init() { /* create system, init with 64 channels */ }
    void shutdown() { /* release all sounds, release system */ }
    void update() { /* call FMOD_System_Update — do this every frame */ }

    // Load a sound (cached)
    FMOD_SOUND* loadSound(string path, bool is3D, bool loop);

    // Play a sound at a position
    FMOD_CHANNEL* play(string soundName, vec3 position);

    // Play background music (2D, looping)
    FMOD_CHANNEL* playMusic(string path);

    // Update listener position (call each frame with camera pos/fwd/up)
    void setListener(vec3 pos, vec3 forward, vec3 up);
}
```

#### Sound Design for the Game

| Sound | Type | Notes |
|-------|------|-------|
| Background music | 2D, looping, streamed | Low volume, sets mood |
| Pistol shot | 3D, one-shot | Short, punchy, fast decay |
| Rifle shot | 3D, one-shot | Louder, longer tail |
| Shotgun blast | 3D, one-shot | Wide, bassy |
| Sniper shot | 3D, one-shot | Sharp crack + echo |
| SMG shot | 3D, one-shot | Rapid, lighter |
| Bullet impact | 3D, one-shot | Play at hit position |
| Enemy hit | 3D, one-shot | Meaty thud + feedback |
| Footsteps | 3D, one-shot | Timed to movement speed |
| Reload | 2D, one-shot | Click-clack mechanical |
| Empty magazine | 2D, one-shot | Dry click |
| Combo sound | 2D, one-shot | Pitch increases with combo |
| Miss buzzer | 2D, one-shot | Subtle negative feedback |
| Round start | 2D, one-shot | Countdown beep |
| Round end | 2D, one-shot | Whistle or horn |

#### Where to Get Free Sounds

- **freesound.org** — CC0 gun sounds, impacts, ambient
- **kenney.nl/assets** — Free game audio packs (CC0)
- **mixkit.co** — Free sound effects
- Search for "game gun sound effect free" — plenty of CC0 options

#### Complexity Assessment

FMOD integration is **moderate difficulty, 2-3 days**. The dylib approach is identical to what you did with Bullet. The C API is simpler than Bullet's command/status pattern — most FMOD calls are direct "do this thing" functions that return an error code. The hardest part is getting the 3D listener attributes right (position, forward, up must match your camera), but you already understand your coordinate system.

---

## 2. Gameplay — Weapons + Shooting Mechanics + Enemies

### Weapon System Architecture

```d
struct WeaponStats {
    string name;
    float fireRate;          // seconds between shots
    float reloadTime;        // seconds to reload
    int   magazineSize;      // bullets per magazine
    float baseDamage;
    float baseSpread;        // radians of cone inaccuracy
    float spreadPerShot;     // how much spread increases per consecutive shot
    float spreadRecovery;    // spread decrease per second when not firing
    float maxSpread;         // spread cap
    float recoilKick;        // visual camera kick per shot
    int   bulletsPerShot;    // 1 for most, 8+ for shotgun
    string fireSound;        // sound asset path
    string reloadSound;
    string modelPath;        // weapon .obj/.fbx path
}
```

### The 5 Weapons

| Weapon | Fire Rate | Mag | Spread | Damage | Personality |
|--------|-----------|-----|--------|--------|-------------|
| Pistol | 0.4s | 12 | Low, slow growth | 25 | Reliable starter, accurate tap fire |
| Rifle | 0.1s | 30 | Medium, fast growth | 15 | Full auto workhorse, spray gets wild |
| Shotgun | 0.8s | 6 | Wide cone, 8 pellets | 8×8 | Devastating up close, useless at range |
| Sniper | 1.5s | 5 | Tiny base, huge per-shot | 100 | One-shot kill, punishes spam |
| SMG | 0.06s | 40 | High, very fast growth | 10 | Bullet hose, accuracy degrades fast |

### Shooting Mechanics — Spread System (Fortnite-style)

The key insight: accuracy is not random. It follows a predictable pattern that rewards trigger discipline.

```
currentSpread starts at baseSpread

On each shot:
    1. Generate random offset within cone of currentSpread
    2. Apply offset to ray direction
    3. currentSpread += spreadPerShot
    4. Clamp to maxSpread
    5. Apply recoil kick to camera (visual only, recovers)

When NOT shooting:
    currentSpread -= spreadRecovery * frameDt
    Clamp to baseSpread (never goes below base)
```

#### Pseudocode for spread raycast

```d
void shootWithSpread(WeaponStats weapon) {
    vec3 from = camera.eyePosition;
    vec3 dir  = camera.forwardVector * -1.0;  // your convention

    // Apply spread — random point in a cone
    float angle = uniform(0, currentSpread);
    float spin  = uniform(0, 2 * PI);
    vec3 offset = (camera.rightVector * cos(spin) + camera.upVector * sin(spin)) * sin(angle);
    dir = Normalize(dir + offset);

    // For shotgun: loop bulletsPerShot times, each with independent spread
    vec3 to = from + dir * 1000.0;
    auto result = physics.raycast(from, to);

    // Increase spread
    currentSpread = min(currentSpread + weapon.spreadPerShot, weapon.maxSpread);
}
```

#### Recoil (Camera Kick)

```d
// On shoot:
cameraRecoilPitch += weapon.recoilKick;

// Each frame:
cameraRecoilPitch = lerp(cameraRecoilPitch, 0, frameDt * 8.0);
// Apply to camera forward vector as a pitch offset
```

This makes the camera jerk up slightly with each shot and smoothly recover. Fast firing = camera climbs = hard to aim. The player learns to fire in bursts.

#### Weapon Switching

```d
// In GameApplication
WeaponStats[5] mWeapons;    // all 5 weapon definitions
int mCurrentWeapon = 0;
float mSwitchTimer = 0;     // can't fire during switch
float mSwitchTime = 0.5;    // seconds to switch

// Number keys 1-5 switch weapons
// During switch: play animation (lower current, raise new), can't fire
```

### Enemies

#### Static Enemies (Start Here)

Start simple — enemies are static humanoid models standing in the scene. They don't move, don't shoot back. They're target practice dummies with health bars.

```d
struct Enemy {
    uint entityId;
    float health;
    float maxHealth;
    bool alive;
    vec3 spawnPosition;
}
```

- [ ] Load a humanoid .fbx model via Assimp
- [ ] Spawn 5-10 enemies at fixed positions around the scene
- [ ] On raycast hit, reduce health
- [ ] At health <= 0, play death animation (or ragdoll with physics impulse)
- [ ] Respawn after 5 seconds at the same position

#### Animated Enemies (Stretch Goal)

This requires skeletal animation support through Assimp:

- [ ] Load bone/skeleton data from .fbx
- [ ] Implement bone matrix palette (array of mat4 uploaded to vertex shader)
- [ ] Blend between idle/hit/death animations
- [ ] Vertex shader applies bone weights to vertex positions

**Honest assessment:** Skeletal animation is 3-5 days of work minimum. It requires modifying your vertex shader, adding bone weight attributes to your VBO format, and building an animation interpolation system. If time is tight, rigid-body ragdoll (just apply physics impulse on death and let Bullet handle it) looks almost as good and takes 30 minutes.

#### Enemy Placement for Visual Impact

- Enemies on rooftops at different heights (tests vertical aiming)
- Enemies behind partial cover (tests precision)
- Enemies at varying distances (tests weapon range differences)
- Group clusters that reward shotgun/explosive choice

---

## 3. Asset Pipeline — Model Loading + Animation with Assimp

### Assimp Overview

Assimp (Open Asset Import Library) reads 40+ 3D file formats and normalizes them into a common in-memory structure. The C API is what you'll bind to.

### Key Assimp Structures

```
aiScene (root)
├── mMeshes[]          — vertex data, normals, UVs, bone weights
├── mMaterials[]       — diffuse color, texture paths, specular
├── mAnimations[]      — keyframe data for bones
├── mRootNode          — scene hierarchy (transform tree)
│   ├── mTransformation  — local transform matrix
│   ├── mMeshes[]        — which meshes this node uses
│   └── mChildren[]      — child nodes
└── mTextures[]        — embedded textures (optional)
```

### Building the Dylib

```bash
# Clone assimp
git clone https://github.com/assimp/assimp.git
cd assimp

# Build with only the formats you need
cmake -B build \
  -DBUILD_SHARED_LIBS=ON \
  -DASSIMP_BUILD_TESTS=OFF \
  -DASSIMP_BUILD_ASSIMP_TOOLS=OFF \
  -DASSIMP_BUILD_ALL_IMPORTERS_BY_DEFAULT=OFF \
  -DASSIMP_BUILD_OBJ_IMPORTER=ON \
  -DASSIMP_BUILD_FBX_IMPORTER=ON \
  -DASSIMP_BUILD_GLTF_IMPORTER=ON \
  -DCMAKE_BUILD_TYPE=Release

cmake --build build
# Output: build/lib/libassimp.dylib
```

### D Bindings — Core Functions

```d
// source/assimp/assimp_c_api.d

alias aiScene = void;   // opaque for now, we'll access via helper functions

extern(C) {
    // Import a file — returns aiScene*
    const(aiScene)* aiImportFile(const(char)* path, uint flags);

    // Free the scene
    void aiReleaseImport(const(aiScene)* scene);

    // Error string
    const(char)* aiGetErrorString();
}

// Post-processing flags (combine with |)
enum aiProcess {
    Triangulate        = 0x8,
    FlipUVs            = 0x800000,
    GenNormals         = 0x20,
    GenSmoothNormals   = 0x40,
    CalcTangentSpace   = 0x1,
    JoinIdenticalVertices = 0x2,
    LimitBoneWeights   = 0x200,
}
```

### Loading Pipeline

```
File (.obj/.fbx/.gltf)
    → aiImportFile(path, Triangulate | FlipUVs | GenNormals)
    → Walk aiScene.mMeshes[]
        → For each mesh:
            → Extract positions (aiVector3D[])
            → Extract normals (aiVector3D[])
            → Extract UVs (aiVector3D[] from mTextureCoords[0])
            → Extract indices (aiFace[])
            → Pack into your ISurface VBO format
            → Extract material index → look up aiMaterial → get texture path
    → Return MeshNode (or array of MeshNodes for multi-mesh scenes)
```

### Complexity Breakdown

| Feature | Difficulty | Time | Notes |
|---------|-----------|------|-------|
| Static mesh loading (OBJ/FBX) | Easy | 1 day | Just vertex/normal/UV extraction |
| Material + texture extraction | Easy | 0.5 day | Read diffuse texture path from aiMaterial |
| Multi-mesh scenes | Medium | 0.5 day | Walk node tree, apply parent transforms |
| Skeletal animation loading | Hard | 2 days | Bone hierarchy, weights, keyframes |
| Animation playback (CPU skinning) | Hard | 2 days | Interpolate keyframes, build bone matrices |
| Animation playback (GPU skinning) | Very Hard | 3 days | Shader modification, bone palette upload |

### Recommendation

Start with static mesh loading only. Get textured enemies standing in the scene. If you have time after gameplay is done, add skeletal animation. Ragdoll physics (apply impulse on death) is a perfectly good substitute for death animations and takes minutes instead of days.

---

## 4. ImGui Game GUI

### Current State

You have `cimgui.dylib` in your project root. The `editor/imgui_layer.d` file is empty. You need to write D bindings for cimgui and wire it into your render loop.

### What You Need from ImGui

| Element | Use |
|---------|-----|
| Main menu | Play, Settings, Quit buttons |
| HUD overlay | Health bar, ammo, score, combo multiplier, round timer |
| Pause menu | Resume, Settings, Quit |
| Results screen | Final score, accuracy, weapon stats |
| Settings panel | Mouse sensitivity, volume, weapon selection |
| Debug overlay (F3) | FPS, entity count, physics step time, draw calls |

### Integration Steps

- [ ] Write D bindings for cimgui (~30 core functions)
- [ ] Init ImGui context + SDL2 backend + OpenGL3 backend
- [ ] In AdvanceFrame: call ImGui_NewFrame before Input, ImGui_Render after your scene render
- [ ] HUD elements use `igSetNextWindowPos` with `ImGuiCond_Always` to pin to screen corners
- [ ] Use `igSetNextWindowBgAlpha(0.0)` for transparent HUD windows
- [ ] Use `igProgressBar` for health bar
- [ ] Use `igText` for score, ammo, timer

### D Bindings for cimgui

cimgui is already a C wrapper around C++ ImGui, so your bindings are straightforward:

```d
extern(C) {
    // Context
    void* igCreateContext(void* shared_font_atlas);
    void  igDestroyContext(void* ctx);

    // Frame
    void igNewFrame();
    void igRender();
    void* igGetDrawData();

    // Windows
    bool igBegin(const(char)* name, bool* p_open, int flags);
    void igEnd();

    // Widgets
    void igText(const(char)* fmt, ...);
    bool igButton(const(char)* label, float size_x, float size_y);
    bool igSliderFloat(const(char)* label, float* v, float v_min, float v_max, const(char)* format, int flags);
    void igProgressBar(float fraction, float size_x, float size_y, const(char)* overlay);

    // Positioning
    void igSetNextWindowPos(float x, float y, int cond, float pivot_x, float pivot_y);
    void igSetNextWindowBgAlpha(float alpha);
    void igSetNextWindowSize(float x, float y, int cond);

    // SDL2 + OpenGL3 backend
    bool ImGui_ImplSDL2_InitForOpenGL(void* window, void* sdl_gl_context);
    bool ImGui_ImplOpenGL3_Init(const(char)* glsl_version);
    void ImGui_ImplSDL2_NewFrame();
    void ImGui_ImplOpenGL3_NewFrame();
    void ImGui_ImplOpenGL3_RenderDrawData(void* draw_data);
    void ImGui_ImplSDL2_Shutdown();
    void ImGui_ImplOpenGL3_Shutdown();
}
```

---

## Priority Order / TODO Checklist

### Phase 1: Core Gameplay (Days 1-4)
- [ ] Spawn system — timer-based falling objects with difficulty ramp
- [ ] Weapon stats struct with 5 weapon definitions
- [ ] Spread system (cone inaccuracy, grows with continuous fire, recovers)
- [ ] Recoil (camera kick + recovery)
- [ ] Weapon switching (1-5 keys, switch animation delay)
- [ ] Reload mechanic (R key, magazine depletion, reload timer)
- [ ] Combo system (consecutive hits multiply score)
- [ ] Round system (60s timer, waves with escalating difficulty)
- [ ] Score penalties for objects hitting the ground

### Phase 2: Audio (Days 4-5)
- [ ] FMOD dylib integration + D bindings
- [ ] AudioEngine struct with sound cache
- [ ] 3D listener tied to camera position each frame
- [ ] Per-weapon fire sounds (5 different sounds)
- [ ] Impact sound at hit position
- [ ] Reload sound
- [ ] Footstep sounds timed to movement
- [ ] Background music (looped, streamed)
- [ ] Combo feedback sounds (pitch increases)
- [ ] Round start/end sounds

### Phase 3: Asset Pipeline (Days 5-8)
- [ ] Build Assimp dylib (OBJ + FBX + glTF importers)
- [ ] D bindings for core Assimp C API
- [ ] AssimpLoader — extract vertices/normals/UVs into ISurface
- [ ] Texture loading from material data + mipmapping
- [ ] Resource cache (no duplicate mesh/texture loads)
- [ ] Load enemy models (humanoid .fbx from free asset packs)
- [ ] Load weapon models (attach to camera view)
- [ ] Load environment pieces (ground, walls, crates)
- [ ] Skybox or gradient background

### Phase 4: GUI (Days 8-9)
- [ ] cimgui D bindings
- [ ] ImGui SDL2 + OpenGL3 backend init
- [ ] Main menu (Play, Settings, Quit)
- [ ] HUD overlay (health, ammo, score, combo, timer)
- [ ] Pause menu
- [ ] Results screen
- [ ] Settings (sensitivity, volume)
- [ ] Debug overlay (F3 toggle: FPS, entity count, physics time)

### Phase 5: Polish + Optimization (Days 9-11)
- [ ] Particle effects on hit
- [ ] Frustum culling with bounding spheres
- [ ] Octree spatial acceleration
- [ ] Runtime toggles (F1/F2/F3 for culling/mipmaps/octree)
- [ ] Stress test scenes (100, 500, 1000 objects)

### Phase 6: Evaluation + Report (Days 12-14)
- [ ] Performance measurements (FPS across stress scenes)
- [ ] Before/after data for each optimization
- [ ] Screenshots + debug visualizations
- [ ] Demo video recording
- [ ] Final report data

---

## Free Asset Sources

| Source | What | License |
|--------|------|---------|
| kenney.nl | Low-poly models, textures, audio | CC0 |
| freesound.org | Sound effects | CC0/CC-BY |
| sketchfab.com | 3D models (filter by free + downloadable) | Various |
| mixkit.co | Sound effects, music | Free |
| quaternius.com | Low-poly character packs | CC0 |
| opengameart.org | Sprites, models, audio | CC0/CC-BY |
| ambientcg.com | PBR textures | CC0 |