# Projectile System – Logic-Driven Trajectory with Bullet Queries (Option A)

This document describes **Option A** for weapons and projectiles:

> **The game logic owns projectile motion and intent. Bullet is used only for collision queries.**

This is the most common approach in FPS and action games because it is **predictable, tunable, and engine-friendly**.

---

## 1. What Option A Is (and Is Not)

### Option A **is**:

* Game-driven projectile motion
* Deterministic trajectories
* Bullet used for raycasts and sweeps
* Explicit control over gameplay behavior

### Option A **is not**:

* Fully physics-simulated bullets
* Bullet-controlled velocity or forces
* Rigid bodies for every projectile

Think of Bullet as a **collision oracle**, not a projectile simulator.

---

## 2. Why This Model Exists

Fully simulated bullets are:

* hard to tune
* non-deterministic
* expensive at scale
* awkward for networking

Logic-driven projectiles allow:

* consistent weapon feel
* exact control over gravity and speed
* easy balancing
* clean separation of concerns

This is why most shooters use this approach.

---

## 3. Core Responsibilities

### 3.1 Game Logic Owns

* Fire direction
* Initial velocity
* Gravity
* Lifetime
* Damage
* Explosion rules
* Visual and audio effects

### 3.2 Bullet Owns

* Collision detection
* Raycasts
* Shape sweeps
* Hit position and normal
* Hit object identity

Bullet never decides *what happens* — only *where contact occurs*.

---

## 4. High-Level Data Model

```text
Projectile
 ├── Position
 ├── Velocity
 ├── Radius (optional)
 ├── Lifetime
 ├── Damage
 ├── Owner
```

This object lives entirely in your engine.

---

## 5. Frame-to-Frame Workflow

Each frame, for every active projectile:

```text
1. Store previous position
2. Integrate velocity
3. Apply gravity
4. Compute new position
5. Query Bullet for collision
6. Resolve hit or continue
```

Bullet is queried **after motion is computed**, not before.

---

## 6. Collision Query Strategies

### 6.1 Hitscan (Zero-Time Projectile)

Used for rifles, pistols, lasers.

* Single raycast
* No persistent projectile entity

```text
origin → direction × range
```

Bullet returns the first hit, if any.

---

### 6.2 Continuous Projectiles (Most Common)

Used for rockets, arrows, grenades.

To avoid tunneling:

* Sweep from previous position to new position
* Use a sphere or capsule sweep

```text
prevPos → newPos
```

This guarantees collision even at high speed.

---

## 7. Why Sweeps Matter

Discrete position checks can miss thin geometry.

Sweeps ensure:

* fast projectiles still collide
* behavior is framerate-independent
* accuracy is consistent

Bullet provides sweep tests specifically for this reason.

---

## 8. Hit Handling (Engine Side)

When Bullet reports a hit:

Your engine decides:

* apply damage
* spawn decals or particles
* play sounds
* destroy projectile
* trigger explosion

Bullet does not resolve damage or effects.

---

## 9. Example Timeline

```text
Frame N:
  Projectile at P0
  Velocity = V

Frame N+1:
  Integrate → P1
  Sweep P0 → P1
  Bullet reports hit at H

Engine:
  Apply damage
  Stop projectile
```

This logic is fully deterministic.

---

## 10. Advantages of Option A

* Predictable gameplay
* Simple debugging
* Easy balancing
* No physics instability
* Clear engine ownership
* Bullet used efficiently

This model scales to thousands of projectiles.

---

## 11. When NOT to Use Option A

Avoid Option A if:

* objects must bounce realistically
* physics interaction is the core mechanic
* simulation accuracy matters more than feel

In those cases, rigid bodies may be appropriate.

---

## 12. Mental Model to Keep

> **Game logic writes the story.
> Bullet checks the world for contradictions.**

Projectiles move because *you* say so.
They stop because *geometry* says so.

---

## 13. Summary

* Option A = logic-driven trajectory + Bullet queries
* Bullet is queried, not obeyed
* Sweeps prevent tunneling
* Gameplay remains deterministic
* Engine retains full control

This is the recommended approach for most custom engines.
