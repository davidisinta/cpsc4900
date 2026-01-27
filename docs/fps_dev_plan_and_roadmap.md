# FPS Aim Trainer – Development Plan, Requirements & Roadmap

## 1. Project Overview
A simple 3D FPS aim-training game inspired by Aimlabs, built fully from scratch using **Dlang** and **OpenGL**, with a lightweight custom engine.  
The focus is **mechanical skill training**, performance, and clean engine architecture rather than content scale.

You will:
- Build a minimal but extensible **3D game engine**
- Import (not create) assets
- Implement a configurable FPS training experience with a unique twist

---

## 2. Technology Stack

### Language & Core
- **Dlang** – core engine and gameplay logic
- **CMake / dub** – build system

### Rendering

# FPS Player Models, Animations, and Asset Strategy

This document summarizes the key design decisions, workflows, and recommendations discussed for implementing **first-person shooter (FPS) player models and animations** in this engine.

---

## 1. Core Concept: Two Player Representations

Modern FPS games use **two separate models per player**.

### First-Person View Model (local only)
- Arms + weapon only
- Rendered from the player camera
- High detail
- Often uses a different FOV
- Usually rendered in a separate pass

Used for:
- Weapon recoil
- Reload animations
- Visual feedback

### Third-Person World Model (for opponents)
- Full body or simplified body
- Exists in world space
- Used for:
  - Visibility to enemies
  - Hit detection
  - Networking replication
  - Shadows

Opponents never see your arms model — they see your world model.

---

## 2. How Opponents Shoot You

Damage is not based on your FPS arms mesh.

Instead:
- Weapons fire rays or projectiles in world space
- Intersect with hitboxes or colliders
- Apply damage on hit

This enables clean gameplay logic and simple networking.

---

## 3. Recommended Player Architecture

Each player entity should contain:
- World transform (position, rotation)
- Collision capsule or hitboxes
- World render model (3P)
- View model (1P, local only)

---

## 4. Asset Strategy

You do not need to model FPS arms yourself initially.

Professional workflow:
- placeholder assets first
- engine systems first
- art polish later

---

## 5. Where to Get FPS Arms and Guns

### Mixamo (Adobe)
- Rigged characters and animations
- Shooting, idle, reload animations
- Free for personal and commercial use

https://www.mixamo.com

Often used to extract arms-only models.

---

### Kenney Assets (CC0)
- Free and permissive license
- Excellent for prototyping

https://kenney.nl/assets

---

### itch.io Free Assets
- Many indie FPS packs
- Arms, guns, animations

https://itch.io/game-assets/free/tag-3d

---

### Sketchfab (Downloadable Models)
- High-quality FPS arms and guns
- Always check license

https://sketchfab.com/search?features=downloadable&q=fps%20arms

---

## 6. Preferred Formats

Recommended:
- glTF (.gltf / .glb)

Acceptable:
- FBX

OBJ does not support animation.

---

## 7. What Assimp Provides

Assimp loads:
- meshes
- bones
- skeleton hierarchy
- animation clips
- skin weights

Assimp does not:
- play animations
- interpolate keyframes
- skin vertices

Those are engine responsibilities.

---

## 8. Minimal Animation System

Required components:
- Skeleton (bone hierarchy)
- AnimationClip (keyframes)
- Animator (time evaluation)
- GPU skinning shader
- Bone uniform array

---

## 9. Weapon Attachment

Weapons should be attached to the hand bone using:
- bone global transform
- weapon offset transform

This allows animation-driven weapon motion.

---

## 10. Suggested Development Order

1. Assimp loading
2. Skeleton parsing
3. GPU skinning
4. Animation playback
5. Weapon attachment
6. Gameplay logic
7. Polish

---

## 11. Blender Learning Reality

Approximate learning curve:
- basic modeling: 1 week
- usable FPS arms: 1–2 months
- high quality: 6+ months

Recommendation:
Do not block engine development on Blender.

---

## 12. Key Takeaway

Focus on engine systems first.
Assets can be replaced.
Architecture cannot.

---

## Useful Links

- Mixamo: https://www.mixamo.com
- Kenney Assets: https://kenney.nl/assets
- itch.io Assets: https://itch.io/game-assets/free/tag-3d
- Sketchfab FPS Search: https://sketchfab.com/search?features=downloadable&q=fps%20arms

---

This file is intended to live in project documentation as a long-term reference.
- **OpenGL 4.x**
- GLSL shaders (vertex, fragment)
- Forward rendering (no deferred in MVP)

### Assets
- **Assimp** – mesh & animation importing
- Supported formats: FBX, OBJ, GLTF

### Physics & Collision
- **Bullet Physics**
  - Rigid bodies (static & kinematic)
  - Raycasts for hitscan weapons

### Audio
- SDL_Audio or OpenAL
- Non-blocking, asynchronous playback

### Windowing & Input
- SDL2
- Raw mouse input

---

## 3. Engine Requirements

### 3.1 Core Systems
- Application lifecycle (init → run → shutdown)
- Game loop with fixed update + variable render
- Time system (delta time, fixed timestep)
- Logging & debug output

### 3.2 Rendering Engine
- Shader abstraction
- Mesh abstraction
- Material system
- Camera system (FPS camera)
- Basic lighting (Phong or Blinn-Phong)
- Debug wireframe mode

### 3.3 Scene System
- Scene graph or flat ECS-style container
- Transform hierarchy
- Entity creation / destruction

### 3.4 Asset Pipeline
- Model loading via Assimp
- Texture loading (stb_image)
- Asset cache (avoid reloading)

### 3.5 Physics System
- Bullet world initialization
- Collision shapes
- Raycasting API
- Sync physics → transforms

### 3.6 Input System
- Keyboard actions
- Mouse movement (relative mode)
- Input mapping abstraction

### 3.7 Audio System
- Fire-and-forget sounds
- Looping background music
- Volume control (master / SFX / music)

---

## 4. Game Requirements (MVP)

### 4.1 Player
- First-person camera
- Hitscan shooting
- No reload / recoil initially
- Configurable sensitivity & FOV

### 4.2 Weapons
- Hitscan raycast
- Fire rate parameter
- Sound + muzzle flash
- Weapon switching

### 4.3 Targets
- Static targets
- Moving targets (linear paths)
- One-hit destruction
- Configurable size & speed

### 4.4 Scoring
- Hits
- Misses
- Accuracy
- Score formula
- Optional streak multiplier

### 4.5 Game Modes
- Timed round (30s / 60s)
- Endless mode (optional)
- Difficulty scaling

---

## 5. Configuration & Customization
- Mouse sensitivity
- FOV
- Target behavior
- Weapon selection
- Round duration
- Difficulty presets

All configurable via **menu UI**.

---

## 6. Roadmap

### Phase 1 – Engine Foundations (Week 1–2)
- Window + OpenGL context
- Game loop
- Camera & input
- Basic rendering

### Phase 2 – Core Engine Systems (Week 3–4)
- Asset loading (Assimp)
- Scene management
- Physics integration
- Audio system

### Phase 3 – Gameplay MVP (Week 5–6)
- FPS shooting
- Target spawning
- Scoring system
- Round logic

### Phase 4 – UI & Menus (Week 7)
- Main menu
- Settings menu
- In-game HUD

### Phase 5 – Polish & Twist (Week 8)
- Unique gameplay mechanic
- Balancing
- Bug fixing

---

## 7. Non-Goals (Explicitly Out of Scope)
- Networking / multiplayer
- AI enemies
- Large maps
- Story or progression systems

---

## 8. Success Criteria
- Stable 60+ FPS
- Accurate input handling
- Clean separation between engine & game logic
- Fully playable aim-training session
