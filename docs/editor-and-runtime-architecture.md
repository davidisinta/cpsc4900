# Editor Mode vs Game Runtime Mode in a 3D Game Engine

This document explains the architecture behind a **3D game engine that includes both an editor and a playable game**, using:

* **SDL3** (windowing + input)
* **OpenGL** (rendering)
* **ImGui** (editor UI)
* **D language** (engine implementation)

The goal is to clearly explain:

* How editor mode and game mode coexist
* How everything still runs in one executable
* How ECS fits naturally into this design
* How play/stop works safely
* How data flows through the engine

---

## 1. One Engine, One Executable, One Main Loop

Even though the engine has multiple modes (editor and play), **there is still only one executable and one main loop**.

You do NOT run a separate program for the editor and the game.

Instead:

* The engine runs continuously
* A mode flag determines *what systems are executed*

```d
void main()
{
    Engine engine;
    engine.init();
    engine.run();
}
```

Everything happens inside `engine.run()`.

---

## 2. Engine Modes

Most engines use a simple state machine:

```d
enum EngineMode
{
    Edit,
    Play,
    Pause
}
```

### Meaning of each mode

| Mode  | What happens                                 |
| ----- | -------------------------------------------- |
| Edit  | Scene editing, object placement, no gameplay |
| Play  | Game simulation running                      |
| Pause | Runtime frozen but still visible             |

Switching modes does **not restart the program**.

It only changes **which world and which systems are updated**.

---

## 3. Two Worlds: Editor World vs Runtime World

This is one of the most important concepts.

### Editor World

* Used for authoring
* Modified by ImGui
* Saved to disk
* Never mutated by gameplay

### Runtime World

* Created only when Play is pressed
* Simulates physics, movement, AI
* Destroyed when Stop is pressed

```
Editor World  ----clone---->  Runtime World
     |                             |
     |<-----------discard----------|
```

This prevents bugs like:

> “I pressed Play and my scene got permanently modified.”

Unity, Unreal, and Godot all follow this model.

---

## 4. High-Level Engine Loop

```d
while (running)
{
    pollSDLEvents();

    imgui.beginFrame();

    if (mode == Edit)
    {
        editor.update(editorWorld, dt);
        renderer.render(editorWorld);
    }
    else if (mode == Play)
    {
        game.update(runtimeWorld, dt);
        renderer.render(runtimeWorld);
    }

    editor.drawUI();

    imgui.endFrame();

    SDL_GL_SwapWindow(window);
}
```

Key ideas:

* OpenGL scene renders first
* ImGui draws on top
* Same window, same context
* Only behavior changes

---

## 5. What the Editor Actually Does

The editor is just **tools operating on ECS data**.

Typical editor responsibilities:

* Create entities
* Add/remove components
* Modify component fields
* Select entities
* Display hierarchy
* Show inspector

Example ImGui button:

```d
if (ImGui.Button("Create Cube"))
{
    Entity e = world.createEntity();
    world.transforms.add(e);
    world.meshRenderers.add(e);
}
```

The editor does NOT know how rendering works.
It only manipulates data.

---

## 6. ECS: Entity–Component–System

ECS is the backbone that makes editor + runtime coexist cleanly.

### Entity

An entity is just an ID.

```d
alias Entity = uint;
```

No logic. No data.

---

### Components

Components are plain data structs.

```d
struct Transform
{
    Vec3 position;
    Vec3 rotation;
    Vec3 scale = Vec3(1,1,1);
}

struct Velocity
{
    Vec3 value;
}

struct MeshRenderer
{
    uint mesh;
    uint material;
}
```

No behavior inside components.

---

### Component Storage

Each component type has its own storage.

```d
struct Storage(T)
{
    T[Entity] data;

    bool has(Entity e)
    {
        return (e in data) !is null;
    }

    ref T add(Entity e)
    {
        data[e] = T.init;
        return data[e];
    }
}
```

---

### World

The world groups all component storages.

```d
struct World
{
    Entity next = 1;

    Storage!Transform transforms;
    Storage!Velocity velocities;
    Storage!MeshRenderer renderers;

    Entity createEntity()
    {
        return next++;
    }
}
```

---

## 7. Systems

Systems are functions that operate on entities that have required components.

### Movement system

```d
void movementSystem(ref World w, float dt)
{
    foreach (e, vel; w.velocities.data)
    {
        auto t = e in w.transforms.data;
        if (t is null) continue;

        t.position.x += vel.value.x * dt;
        t.position.y += vel.value.y * dt;
        t.position.z += vel.value.z * dt;
    }
}
```

### Render system

```d
void renderSystem(ref World w, ref Renderer r)
{
    foreach (e, mr; w.renderers.data)
    {
        auto t = e in w.transforms.data;
        if (t is null) continue;

        r.drawMesh(mr.mesh, mr.material, *t);
    }
}
```

Systems do not care *what the entity is*.
Only what components it has.

---

## 8. Why ECS Works Perfectly With Editors

Because:

* Editor = modifies components
* Game = runs systems
* Renderer = reads components

Everything talks through shared data.

No inheritance trees.
No massive GameObject classes.

Just data.

---

## 9. Play / Stop Implementation

```d
void startPlay()
{
    runtimeWorld = clone(editorWorld);
    mode = Play;
}

void stopPlay()
{
    runtimeWorld.destroy();
    mode = Edit;
}
```

The editor world is never modified by gameplay.

This is critical.

---

## 10. Things You Haven’t Implemented Yet (But Will)

These usually come later:

* Scene serialization (save/load)
* Prefabs
* Runtime scripting (Lua, Wren, etc.)
* Entity picking (mouse → raycast)
* Gizmos (translate / rotate / scale)
* Render-to-texture viewport
* Asset hot-reload
* Undo/redo command stack

None of these require changing the ECS model.

They build cleanly on top of it.

---

## 11. Final Mental Model

Think of your engine like this:

* **Engine**: owns loop, window, renderer
* **World**: owns data
* **Editor**: edits data
* **Game**: simulates data
* **Renderer**: visualizes data

Everything is just reading or writing components.

That simplicity is the entire power of ECS.

---

## Summary

* Editor and game run in the same executable
* One main loop controls everything
* Mode switching changes which systems run
* Two worlds prevent scene corruption
* ECS cleanly supports editing and simulation
* ImGui is just a UI layer on top of engine data

This architecture is how real engines remain scalable while staying understandable.

Once this foundation is correct, everything else becomes additive rather than fragile.
