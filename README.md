<!-- # senior-project


# inspo: https://krunker.io/?game=NY:noru3


# game for aiming: https://store.steampowered.com/app/714010/Aimlabs/ 


# graphics course: https://www.mshah.io/module?t=sp&y=25&n=Graphics&m=9


# dlang gui: https://buggins.github.io/dlangui/


# rifle animation pack: https://sketchfab.com/3d-models/animated-fps-hands-rifle-animation-pack-5f2d0ed780a94724b36ab505f7564057

# https://www.mixamo.com/#/?page=1&query=gun&type=Character

# https://sketchfab.com/barcodegames/models

# audio engine: https://docs.google.com/presentation/d/1QgJVSWqatjWddNBmk1fK_hyFIXsAoMNYJSL-AxIBv2c/edit?slide=id.g31012e81b67_0_701#slide=id.g31012e81b67_0_701 

# gui and gameplay systems: https://docs.google.com/presentation/d/1DVZI1yKOU6VGJQg_ASB5ySa4DjUIUyMscYiJ926fmQE/edit?slide=id.g314961c46bd_1_559#slide=id.g314961c46bd_1_559


# physics engine: https://github.com/gecko0307/dmech/blob/master/tutorials/001.%20Basic%20Usage.md


# game engines course: https://www.mshah.io/comp?t=fa&y=25&n=GameEngines

# game architecture book: https://www.youtube.com/watch?v=O8PHxh7gidE 


# 3d engine with editor: https://www.reddit.com/r/gamedev/comments/nye42e/my_own_3d_game_enigne_with_editor_c_and_opengl/




 -->


# Senior Project — Fly With Tai

## Table of Contents

1. [Overview](#overview)
2. [Product Spec](#product-spec)
3. [Wireframes](#wireframes)
4. [Schema](#schema)
5. [Useful Links](#useful-links)

---

## Overview

### Description

This project is a **real-time 3D game engine developed for first-person shooter gameplay**, written in **D programming language** and **Modern OpenGL**. The engine is designed with a strong focus on **performance, architecture, and frame-time optimization**, targeting stable **60+ FPS** under realistic gameplay workloads.

A small FPS-style demo game is built on top of the engine to evaluate rendering, physics, audio, and gameplay systems under stress. The demo is used as a controlled environment to measure how different engine-level design decisions impact performance.

### App Evaluation

#### Engine Motivation
- Built from scratch to understand **how modern game engines work internally**
- Focus on **systems-level tradeoffs** rather than only visual output
- Emphasis on **measurable optimization**, not just features

#### Core Value
- Demonstrates practical engine architecture
- Serves as a research vehicle for:
  - Rendering optimization
  - Spatial data structures
  - CPU/GPU workload reduction
  - Gameplay-system performance

#### Scope
- Engine-first project
- Game exists to **drive and evaluate the engine**
- Clear separation between engine systems and gameplay logic

---

## Product Spec

### 1. Core Engine Features (Must-Have)

- [x] Windowing and render loop (SDL + OpenGL)
- [x] FPS camera and input system
- [x] Scene and transform system
- [x] Mesh + shader + material pipeline
- [x] Resource manager (models, textures, audio)
- [x] Model loading via Assimp
- [x] Texture mipmapping
- [x] Frustum culling
- [x] Octree spatial partitioning
- [x] Raycasting for gameplay
- [x] Physics integration
- [x] Audio system with attenuation
- [x] Debug visualizations

### 2. Gameplay Systems

- [x] FPS player controller
- [x] Hitscan shooting system
- [x] Target objects and collision
- [x] Accuracy / scoring system
- [x] HUD (crosshair, stats)
- [x] Game state machine
  - MENU
  - PLAYING
  - PAUSED
  - RESULTS

### 3. Optional / Stretch Goals

- [ ] Weapon switching
- [ ] Data-driven weapon configs
- [ ] Occlusion culling experiments
- [ ] Runtime performance toggles
- [ ] In-engine editor GUI
- [ ] Profiling overlays

---

## Wireframes

> Engine-focused UI mockups and editor-style layouts

```
[ Viewport | Inspector | Scene Hierarchy ]
```

```
[ Game Running | GUI Collapsed ]
```

---

## Schema

### Engine Modules

| Module | Responsibility |
|------|----------------|
| Renderer | OpenGL draw pipeline |
| Scene | Entity and transform hierarchy |
| ResourceManager | Asset loading and caching |
| Physics | Collision and raycasting |
| Audio | Playback and attenuation |
| Input | Keyboard and mouse handling |
| Camera | FPS camera logic |
| Gameplay | Shooting and scoring |
| Debug | Visualization and toggles |

---

## Useful Links

### Inspiration
- https://krunker.io/?game=NY:noru3  
- https://store.steampowered.com/app/714010/Aimlabs/

### Graphics & Game Engine Courses
- https://www.mshah.io/module?t=sp&y=25&n=Graphics&m=9  
- https://www.mshah.io/comp?t=fa&y=25&n=GameEngines

### GUI
- https://buggins.github.io/dlangui/

### Assets & Animation
- https://sketchfab.com/3d-models/animated-fps-hands-rifle-animation-pack-5f2d0ed780a94724b36ab505f7564057  
- https://www.mixamo.com/#/?page=1&query=gun&type=Character  
- https://sketchfab.com/barcodegames/models

### Engine Systems References
- Audio Engine Slides:  
  https://docs.google.com/presentation/d/1QgJVSWqatjWddNBmk1fK_hyFIXsAoMNYJSL-AxIBv2c/edit

- GUI & Gameplay Systems:  
  https://docs.google.com/presentation/d/1DVZI1yKOU6VGJQg_ASB5ySa4DjUIUyMscYiJ926fmQE/edit

- Physics Engine (DMech):  
  https://github.com/gecko0307/dmech/blob/master/tutorials/001.%20Basic%20Usage.md

### Architecture & References
- Game Architecture Talk:  
  https://www.youtube.com/watch?v=O8PHxh7gidE

- 3D Engine with Editor Discussion:  
  https://www.reddit.com/r/gamedev/comments/nye42e/my_own_3d_game_enigne_with_editor_c_and_opengl/

---

## Author

**David Nyakawa**  
Senior Project — Computer Science  
Yale University  
Advisor: Michael Shah
