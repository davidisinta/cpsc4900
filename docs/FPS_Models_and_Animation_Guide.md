
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
