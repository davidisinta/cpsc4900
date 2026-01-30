# Engine vs Game Architecture

## Core Idea

In modern game engine architecture, **the engine and the game must be cleanly separated**.

- **Engine**: reusable systems that know *how* things work  
- **Game**: project-specific logic that decides *what happens*

The engine must not depend on the game.  
The game depends on the engine.

If the engine knows about your game rules, you are no longer building an engine — you are building a game with rendering.

---

## High-Level Dependency Direction

Correct:

```
Game
 ↓
Engine
 ↓
Platform (SDL / OpenGL / OS)
```

Incorrect:

```
Engine → Game
```

The engine should compile and run without any game code present.

---

## What Belongs in the Engine

The engine owns **infrastructure and systems**.

### Engine Responsibilities

- Window creation
- OpenGL context initialization
- Render loop
- Input polling
- Timing / frame delta
- Rendering system
- Shader management
- Mesh abstraction
- Texture loading
- Resource manager
- Scene graph or ECS
- Camera abstraction
- Physics system
- Audio system
- Debug tools
- Editor UI (optional)

### Engine Does NOT Contain

- Player logic
- Weapons
- Enemies
- Health systems
- Scoring
- Game rules
- Win/lose logic
- Level scripting
- Story logic

If your engine contains files like:

```
Player.d
Gun.d
Enemy.d
```

inside the engine directory — the separation is broken.

---

## Where Does OpenGL Belong?

**OpenGL initialization belongs entirely to the engine.**

The game must never:

- create an OpenGL context
- compile shaders
- bind buffers
- issue raw OpenGL calls

OpenGL is **infrastructure**, not gameplay.

The game communicates using engine-level abstractions:

```d
engine.loadModel("rifle.obj");
engine.spawnEntity();
engine.playSound("shot.wav");
```

Not:

```d
glBindBuffer(...)
glDrawElements(...)
```

---

## Engine Main Loop Ownership

The engine owns the application lifecycle.

Example:

```text
main()
 → engine.run()
     → pollInput()
     → game.onUpdate(dt)
     → engine.render()
```

The game is called *by* the engine.

Never the other way around.

---

## What Is Considered Game Code?

Game code defines **meaning and rules**.

### Examples of Game Code

- Player movement rules
- Shooting behavior
- Damage calculation
- Enemy AI
- Scoring system
- Level logic
- Game states
- Menu flow
- Spawn rules
- Victory conditions

The engine provides tools.  
The game decides how to use them.

---

## Data vs Meaning Principle

One of the most important architectural ideas:

> The engine operates on data.  
> The game assigns meaning to that data.

### Example

Engine:

```d
RaycastHit hit = physics.raycast(origin, direction);
```

Game:

```d
if (hit.entity.has<Enemy>()) {
    enemy.health -= 25;
}
```

The engine does not know what an enemy is.

That knowledge belongs exclusively to the game.

---

## Minimal Directory Structure

```
/engine
    core/
        Application.d
        Time.d
        Input.d

    renderer/
        Renderer.d
        Shader.d
        Mesh.d

    scene/
        Entity.d
        Transform.d

    physics/
        PhysicsWorld.d

    audio/
        AudioSystem.d

/game
    GameApp.d
    Player.d
    Weapon.d
    Enemy.d
    GameState.d
    Levels/
```

The engine directory must be reusable for another game without modification.

---

## How Professional Engines Follow This

### Unity
- Engine written in C++
- Game logic written as C# scripts
- Scripts never touch rendering APIs

### Unreal Engine
- Engine provides all systems
- Game modules define rules and behavior

Both enforce the same boundary:

- Engine = systems
- Game = logic

You are implementing this separation manually.

---

## Where Scripting Fits Later

Scripting languages (Lua, JS, etc.) are used to move **game logic out of compiled code**, not engine code.

Typical evolution:

```
Engine (D + OpenGL)
Game logic (D)
↓
Game logic (Lua / data-driven)
```

Scripting does not replace engine architecture — it sits on top of it.

---

## The One Rule to Remember

> If you can build a completely different game on top of your engine without changing engine code —  
> your architecture is correct.

If not, you have built a game with a renderer.

---

## Summary

### Engine
- Owns OpenGL
- Owns window
- Owns main loop
- Provides reusable systems
- Knows nothing about gameplay

### Game
- Defines rules
- Defines behavior
- Defines meaning
- Uses engine APIs
- Never touches OpenGL

**OpenGL always belongs in the engine.**
