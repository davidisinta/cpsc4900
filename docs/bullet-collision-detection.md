# Bullet Collision Detection – High‑Level Guide

This document explains **how collision detection works in general** and **how Bullet Physics fits into a custom game engine** with its own scene graph (e.g. a D + OpenGL engine).

The goal is architectural clarity, not API memorization.

---

## 1. Collision Detection: The Big Picture

At a high level, collision detection answers one question:

> **Which objects intersect, touch, or are about to touch?**

Modern engines split this into **layers**, because brute‑force checking everything against everything is too slow.

### 1.1 The Three Phases of Collision Detection

#### 1️⃣ Broad Phase

* Cheap, approximate tests
* Eliminates most non‑colliding objects
* Examples:

  * AABB overlap tests
  * Spatial partitioning (grids, trees)

> Output: *possible* collision pairs

---

#### 2️⃣ Narrow Phase

* Exact shape‑vs‑shape math
* Computes:

  * contact points
  * surface normals
  * penetration depth

> Output: *actual* collisions

---

#### 3️⃣ Resolution

* Prevents objects from intersecting
* Slides, blocks, steps, or bounces objects
* May apply friction or impulses

> Output: corrected transforms

Bullet handles **all three phases**.

---

## 2. Scene Graph vs Physics World

A key idea:

> **Your engine’s scene graph and Bullet’s physics world are separate systems.**

They run in parallel and synchronize every frame.

### 2.1 Your Scene Graph (Semantic World)

This is where *meaning* lives.

```text
Player
 ├── Transform
 ├── Mesh
 ├── Animator
 ├── Weapon
 └── Health
```

It knows:

* what a human is
* what stairs are
* what can jump, shoot, or die

---

### 2.2 Bullet’s World (Geometric World)

Bullet only sees **math**.

```text
CollisionObject
 ├── Shape: Capsule
 ├── Flags: Character
 ├── Transform
```

Bullet knows:

* shapes
* overlaps
* contact normals
* penetration depth

It does **not** know:

* humans
* stairs
* weapons
* gameplay rules

---

## 3. What Bullet Actually Understands

Bullet’s entire model of the world is built from three concepts.

### 3.1 Collision Shapes

Common shapes:

* Sphere
* Box (AABB / OBB)
* Capsule
* Triangle mesh (static only)
* Heightfield (terrain)

These shapes are **pure geometry**.

---

### 3.2 Collision Object Types

Every object is assigned a behavior role:

| Type      | Meaning                          |
| --------- | -------------------------------- |
| Static    | Never moves (terrain, buildings) |
| Dynamic   | Fully simulated (crates, debris) |
| Kinematic | Moved by code, collides properly |
| Ghost     | Detects overlaps only            |
| Character | Special kinematic controller     |

---

### 3.3 Collision Groups & Masks

These control **who can collide with whom**.

Example:

* Player collides with World
* Projectiles collide with World + Enemies
* Triggers collide with Player only

Meaning is imposed by *how you wire the rules*.

---

## 4. How Bullet “Understands” Gameplay Concepts

Bullet never understands gameplay directly.

Instead, **behavior emerges from geometry + parameters**.

---

### 4.1 Humans (Players, NPCs)

Defined as:

* Shape: Capsule
* Type: Character
* Controller: `btKinematicCharacterController`

This gives:

* smooth sliding
* slope handling
* step climbing

Your engine labels it as a *human*.

---

### 4.2 Stairs

Bullet does not know what stairs are.

You define:

* Static boxes or mesh geometry
* Character controller parameters:

  * step height
  * max slope angle

If geometry fits those constraints, stairs are walkable.

---

### 4.3 Walls, Floors, Slopes

These are inferred from:

* surface normals
* slope angle
* contact depth

Your engine decides:

* what counts as a wall
* what counts as ground
* when falling starts

---

## 5. Bullet’s Role in Your Engine

Bullet acts as a **collision and spatial query subsystem**.

It answers questions like:

* did this move collide?
* where is the contact point?
* what direction is the surface normal?
* is the player grounded?

It never decides:

* whether damage is applied
* whether jumping is allowed
* what animation to play

---

## 6. Typical Frame Workflow

```text
Input
 → Gameplay logic computes desired movement
 → Engine updates Bullet controllers
 → Bullet steps simulation
 → Bullet resolves collisions
 → Engine reads updated transforms
 → Engine updates animations, sounds, logic
 → Render
```

Bullet is a **sensor + constraint solver**, not the game brain.

---

## 7. Why This Separation Matters

This architecture lets you:

* change gameplay rules without touching physics
* swap physics engines later
* special‑case mechanics (ladders, ice, conveyors)
* keep physics deterministic and stable

Your engine owns intent.
Bullet enforces physical reality.

---

## 8. Mental Model to Keep

> **Bullet understands shapes and math.
> Your engine understands meaning and behavior.**

Humans, stairs, guns, and enemies exist only in *your* code.

Bullet simply ensures they cannot occupy the same space incorrectly.

---

## 9. Recommended Usage Pattern

For custom engines:

* Use Bullet for collision detection
* Use kinematic characters
* Keep gameplay logic outside Bullet
* Sync transforms explicitly
* Enable debug drawing early

This is how many professional engines integrate physics.

---

## 10. Summary

* Collision detection is layered (broad → narrow → resolve)
* Bullet handles math, not meaning
* Scene graph and physics world are separate
* Behavior emerges from shapes + parameters
* Your engine stays in control

This separation is intentional — and powerful.
