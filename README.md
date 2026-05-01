# Senior Project — Game Engine

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


## Product Spec

### 1. Core Engine Features (Must-Have)

- [X] Windowing and render loop (SDL + OpenGL)
- [X] FPS camera and input system
- [X] Scene and transform system
- [X] Mesh + shader + material pipeline
- [X] Resource manager (models, textures, audio)
- [X] Model loading via Assimp
- [X] Texture mipmapping
- [X] Frustum culling
- [ ] Octree spatial partitioning
- [X] Raycasting for gameplay
- [X] Physics integration
- [ ] Audio system with attenuation
- [X] Debug visualizations

### 2. Gameplay Systems

- [ ] FPS player controller
- [ ] Hitscan shooting system
- [ ] Target objects and collision
- [ ] Accuracy / scoring system
- [ ] HUD (crosshair, stats)
- [ ] Game state machine
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


## Author

**David Nyakawa**  
Senior Project — Computer Science  
Yale University  
Advisor: Michael Shah
