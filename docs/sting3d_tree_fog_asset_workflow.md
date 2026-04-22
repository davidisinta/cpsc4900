# Sting3D Engine Notes: Tree Rendering, Fog Integration, and Asset Workflow

## Overview

This document summarizes the two main rendering tasks we worked through:

1. Getting tree assets to render reliably in Sting3D
2. Adding basic linear fog to improve depth and atmosphere

It also documents the major bugs encountered, how they were diagnosed, the fixes applied, and a practical reference for common 3D asset file formats and how to inspect them.

---

# Task 1: Rendering Trees Reliably in Sting3D

## Goal

The original goal was to add tree props to the FPS environment in a way that matched the current state of the engine:

- D language
- OpenGL renderer
- Assimp-based model import
- existing `LitTexturedMaterial` pipeline
- relatively simple material assumptions

The immediate requirement was not full foliage rendering, but getting a stable, visually acceptable tree or tree trunk prop into the game world.

## Initial Situation

Several candidate tree assets were explored, but many were more complex than the engine’s current rendering path wanted to support.

### The engine’s practical assumptions at this stage

The engine was happiest when a model looked like:

- static mesh
- simple UVs
- one diffuse/base-color texture
- limited material switching
- no skeleton/animation
- no advanced PBR material graph requirements

The more an asset deviated from that, the more fragile the pipeline became.

## Problem 1: Complex assets were not a good fit for the current renderer

Several asset formats and assets were evaluated:

- complicated FBX tree
- glTF tree with multiple meshes/materials
- OBJ tree pack with multiple separate tree objects

The earlier glTF tree turned out to be structured like this:

- 8 mesh objects
- 3 materials
- 2 textures + 1 flat color material
- double-sided materials
- node hierarchy

That was a valid asset, but not a simple one for the current stage of the engine.

### Why this mattered

Supporting the glTF tree properly would require reliable handling of:

- multiple primitives/submeshes
- per-submesh material assignment
- textured and non-textured materials
- double-sided handling
- scene/node hierarchy traversal

That was possible, but it meant pushing more complexity into the engine instead of using an asset that matched the engine’s current assumptions.

### Decision taken

Instead of making the engine smarter immediately, we chose the simpler engineering path:

**adapt the asset choice to the engine.**

That led to searching for simpler tree assets.

## Problem 2: Understanding whether the OBJ tree pack was actually usable

A “4 linden trees” OBJ pack was examined.

At first glance, it looked messy because the directory contained:

- `linden.obj`
- `linden.mtl`
- several JPG textures
- several bump map PNGs

That raised the question: was this one complicated multi-material model, or several separate simple models packed together?

### Inspection process

The `.mtl` file showed four materials, each with:

- one `map_Kd` diffuse texture
- one `map_Bump` bump map

That alone did not prove whether the geometry was mixed or nicely separated.

The key inspection step was looking at the OBJ object declarations and material usage.

### What the inspection revealed

The OBJ contained separate object names such as:

- `linden_1`
- `linden_2`
- `linden_3`
- `linden_4`

And material usage counts showed four distinct bark materials.

This was excellent news, because it meant the file was effectively:

- four separate tree objects
- each with its own material/texture

### Why that was much better

That meant we did not have one chaotic tree with materials switching constantly.

Instead, we had something much cleaner:

- separate tree objects
- one diffuse bark texture per tree
- bump maps that could be ignored for now

This made the asset usable.

## Problem 3: Whether to write a custom OBJ parser or use Assimp

The engine was already using Assimp in `GameApplication` for other imported assets. That meant there was no strong reason to write a custom OBJ parser for this tree pack.

### Why Assimp was the right choice

The current codebase already imported assets with Assimp and created renderable surfaces from imported meshes.

That made the best approach:

- keep Assimp
- keep existing loader flow
- selectively render only the object/mesh of interest

This avoided unnecessary complexity and stayed aligned with the engine’s architecture.

## Problem 4: Crashes when introducing the new linden bark material

Once the linden bark texture was added through `LitTexturedMaterial`, the program crashed after logging that the texture had loaded.

At first this looked confusing, because the log said the texture loaded successfully.

### Key clue

The bark texture dimensions were:

- width: `1273`
- height: `1600`
- channels: `3`

For RGB data, each row is:

`1273 * 3 = 3819 bytes`

OpenGL’s default unpack alignment is 4, which means it expects rows to start on 4-byte boundaries unless told otherwise.

But `3819` is not divisible by 4.

### What that causes

If `GL_UNPACK_ALIGNMENT` is left at the default value of `4`, OpenGL may assume row padding that does not exist. That can produce:

- corrupted textures
- misread rows
- unstable uploads
- crashes, depending on the driver and code path

### Fix applied

In `LitTexturedMaterial.loadTexturePNG`, the texture upload path was updated so that before `glTexImage2D(...)`, the code set:

```cpp
glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
```

and after upload, restored it:

```cpp
glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
```

### Why this fixed it

This told OpenGL to treat the texture rows as tightly packed rather than assuming 4-byte alignment.

That matched the memory layout provided by `stb_image`, so the odd-width RGB texture uploaded safely.

### Lesson learned

A texture can appear to load in CPU memory and still break during GPU upload because of row alignment rules.

This bug was specifically exposed by a texture whose width and channel count made its row stride non-4-aligned.

## Final tree-rendering result

After the texture upload fix, the tree trunks rendered successfully in the world.

### What worked

- OBJ asset
- Assimp import
- bark texture via `LitTexturedMaterial`
- spawn function for linden tree visual placement
- multiple trunks could now be scattered in the environment

### Practical artistic note

These were trunk-only assets, so they read more like:

- dead trees
- war-zone props
- environmental set dressing

rather than lush vegetation.

That still fit the FPS environment well.

---

# Task 2: Adding Basic Fog

## Goal

The goal of fog was not to build a full atmospheric rendering system. It was to add a simple, useful depth cue that would:

- soften distant geometry
- improve atmosphere
- reduce harsh horizon transitions
- make the scene look less empty and abrupt

The chosen starting point was linear fog.

## Why linear fog was the right first choice

Fog systems vary in complexity:

- linear fog
- exponential fog
- exponential squared fog
- height fog
- volumetric fog

For the current engine stage, linear fog was ideal because it is:

- easy to understand
- easy to tune
- easy to integrate into existing shaders
- sufficient to get an immediate visual improvement

## Problem 1: Estimating the amount of work

At first, fog sounded like a lot of work because there are many possible extensions and tuning considerations.

### The reality

A useful first version of fog is small.

The minimum viable version only required:

1. adding fog uniforms
2. passing world position into the fragment shader
3. computing distance from camera to fragment
4. blending the lit result with a fog color

So the code was not large. The harder part was choosing good values.

## Problem 2: Matching fog to the current shader setup

The existing `lit_textured` shaders already had most of the required pieces:

- `FragPos`
- `Normal`
- `TexCoord`
- `uLightPos`
- `viewpos`
- `uTexture`

This made fog integration straightforward.

### Core idea

After normal lighting was computed, fog was applied as a final color blend:

```glsl
finalColor = mix(fogColor, litColor, fogFactor);
```

Where the fog factor is based on distance to the camera.

## Fog implementation workflow

### Step 1: Ensure world position is available in the fragment shader

The vertex shader already computed `FragPos` from the model matrix.

That is exactly what is needed for distance-based fog.

### Step 2: Add fog uniforms

Three uniforms were added conceptually:

- `uFogColor`
- `uFogStart`
- `uFogEnd`

These control the linear fog behavior.

### Step 3: Compute fragment distance

In the fragment shader, distance from the camera to the fragment is computed with:

```glsl
distance(viewpos, FragPos)
```

### Step 4: Compute linear fog factor

The formula used is:

```glsl
fogFactor = clamp((uFogEnd - dist) / (uFogEnd - uFogStart), 0.0, 1.0);
```

Interpretation:

- closer than `uFogStart` → mostly clear
- farther than `uFogEnd` → fully fogged
- between them → linearly blended

### Step 5: Blend lit color with fog color

The final lit result is mixed toward the fog color.

This ensures that fog affects the final visual output without replacing lighting entirely.

## Initial fog values chosen

A reasonable starting set of values was:

- `uFogColor = (0.55, 0.68, 0.78)`
- `uFogStart = 80.0`
- `uFogEnd = 180.0`

These were intended as first-pass values and expected to require tuning based on:

- scene scale
- sky color
- map size
- visual density

## Why only `lit_textured` was done first

The terrain was using a different shader pipeline (`textured_simple`), while trees and soldier-type props were using `lit_textured`.

So the low-risk way to integrate fog was:

- first add fog to `lit_textured`
- verify the result on props and enemies
- later port the same idea to the terrain shader

This was the correct staged approach because it limited the scope of change while still giving immediate feedback.

## Remaining fog follow-up work

The basic fog implementation is only the first stage.

Future improvements could include:

- applying fog to terrain shader
- tuning fog start/end against engagement distance
- matching fog color more tightly to skybox/horizon
- adding UI controls for fog tuning
- switching to exponential fog if a softer falloff is desired
- adding time-of-day dependent fog color

---

# Deep Dive: File Types, What They Give You, and How to Inspect Them

A major part of this work involved deciding which file types fit the current engine state and how to inspect them before committing to an integration path.

## 1. OBJ

### What OBJ gives you

OBJ is a straightforward geometry format for static meshes.

Typical contents:

- vertex positions (`v`)
- texture coordinates (`vt`)
- normals (`vn`)
- faces (`f`)
- object names (`o`)
- group names (`g`)
- material usage (`usemtl`)
- reference to a material library (`mtllib`)

### Strengths

- simple and human-readable
- easy to inspect in a text editor or terminal
- good for static props
- easier to debug than FBX
- material use is explicit through `.mtl`

### Weaknesses

- not great for modern rich material workflows
- no strong built-in support for complex scene semantics
- poor fit for animation/skinning
- can still become annoying if one file mixes many materials and groups

### Why it was useful here

The linden tree pack was OBJ-based, and that made it easy to inspect:

- how many objects existed
- which materials were used
- whether the geometry was separable

### Useful inspection commands for OBJ

Show object declarations:

```bash
grep "^o " linden.obj
```

Show material usage counts:

```bash
grep "^usemtl " linden.obj | sort | uniq -c
```

Show material library reference:

```bash
grep "^mtllib" linden.obj
```

Show object/group/material structure:

```bash
grep -E "^o |^g |^usemtl" linden.obj
```

Count approximate complexity:

```bash
grep -c "^v " linden.obj
grep -c "^vt " linden.obj
grep -c "^vn " linden.obj
grep -c "^f " linden.obj
```

These commands tell you whether the model is:

- one object
- many objects
- one material
- many materials
- large or small

before you even render it.

## 2. MTL

### What MTL gives you

The `.mtl` file is the material companion to OBJ.

Typical contents include:

- `newmtl` → start of a new material
- `map_Kd` → diffuse/base color map
- `map_Bump` or `bump` → bump map
- sometimes specular or other maps

### Strengths

- easy to inspect
- easy to see how many materials exist
- easy to know which textures matter first

### Weaknesses

- material model is relatively old/simple
- exporters vary
- may include maps your engine ignores

### Useful inspection command

```bash
grep -E "newmtl|map_Kd|map_Bump|bump|map_Ka|map_Ks" linden.mtl
```

## 3. glTF

### What glTF gives you

glTF is a modern real-time asset format designed for transmission and engine use.

It can include:

- meshes
- nodes
- transforms
- materials
- textures
- animations
- skinning
- cameras
- scenes

### Strengths

- modern and well-specified
- good for engine pipelines
- excellent for static and animated real-time assets
- often cleaner than FBX

### Weaknesses

- still more structured/complex than OBJ
- commonly expects PBR-style materials
- may contain multiple meshes/primitives/nodes
- requires a more capable importer/render path

### Why it mattered here

The glTF tree that was examined was valid and modern, but it had:

- multiple mesh parts
- multiple materials
- texture + non-texture material combinations
- double-sided materials
- scene hierarchy

That made it less attractive than the simpler OBJ pack for the current engine stage.

### How to inspect glTF

If you have a `.gltf` text file, inspect:

- `materials`
- `meshes`
- `nodes`
- `images`
- `textures`

Things to look for:

- how many materials exist
- whether `baseColorTexture` is present
- whether multiple primitives exist
- whether `doubleSided` is used
- whether there is a node hierarchy

## 4. FBX

### What FBX gives you

FBX is a powerful interchange format often used in DCC tools.

It can store:

- meshes
- transforms
- skeletons
- animation
- materials
- scene hierarchies
- many exporter-specific features

### Strengths

- widely supported by tools
- can store rich scenes and animation
- common in content creation pipelines

### Weaknesses

- inconsistent exporter behavior
- harder to inspect directly
- less transparent than OBJ
- often annoying for custom engine integration
- can contain much more than you want

### Why it was troublesome here

FBX was useful in some asset cases, but it often introduced more uncertainty:

- hidden complexity
- material ambiguity
- exporter quirks
- fragile assumptions inside importer code

For a custom engine still solidifying its content pipeline, FBX is often more effort than OBJ for simple static props.

## 5. RAR archives and asset packaging

A practical obstacle encountered was receiving assets packaged inside `.rar` files.

### Why that matters

An asset that looks messy at the folder level may just be compressed and not yet inspected properly.

The correct workflow was:

1. extract the archive
2. inspect the actual model files
3. inspect material references
4. inspect texture references
5. decide whether the asset is really simple or not

### Practical lesson

Never judge asset usability from a packaged folder alone. Extract it first and inspect the real contents.

---

# Recommended Asset Workflow for Sting3D (Current Stage)

Based on everything encountered here, the current best workflow for adding new static environmental props is:

## 1. Prefer simple static assets
Choose models that are:

- static
- unanimated
- simple UVs
- low material count
- one diffuse texture if possible

## 2. Prefer OBJ over FBX for very simple props
For straightforward props like trunks, rocks, crates, barriers, etc.:

- OBJ + MTL + texture is often easiest to reason about

## 3. Inspect before integrating
Before writing any code, inspect:

- object count
- material count
- texture references
- mesh complexity

## 4. Ignore non-essential maps at first
If the goal is “get it rendered,” often you can ignore:

- bump maps
- specular maps
- advanced PBR maps

and start with diffuse/base color only.

## 5. Watch texture dimensions
Odd-width RGB textures can expose OpenGL unpack alignment issues.

Texture upload code should be robust enough to handle:

```cpp
glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
```

when needed.

## 6. Stage shader changes
When adding effects like fog:

- first apply to the main lit textured shader
- validate result
- then port to terrain/other pipelines

This avoids changing too many systems at once.

---

# Key Engineering Lessons

## 1. Choose the simplest asset that proves the feature
Do not force a complex asset through a young pipeline if a simpler one proves the same thing.

## 2. Inspect asset structure before coding
A few terminal commands can save hours of engine-side debugging.

## 3. Texture load success does not guarantee texture upload success
CPU-side image decode and GPU-side upload are different failure points.

## 4. Add effects incrementally
Fog did not need to become a giant rendering system. The right move was to add a minimal useful version first.

## 5. Diagnose crashes by narrowing scope
The checkpoint/print strategy was essential in separating real causes from apparent causes.

---

# Suggested Next Steps

## Tree / Prop Pipeline
- keep using the linden trunks as war-zone props
- expose tree scale as a parameter
- add support for choosing which linden object to spawn
- optionally scatter all four variants around the map
- later add foliage assets when alpha/double-sided rendering is in a better place

## Fog
- tune fog color to match the skybox better
- port fog to terrain shader
- expose fog settings in ImGui for live tweaking
- optionally test exponential fog later

## Asset Tooling
- keep a terminal-based inspection checklist for all new assets
- document standard acceptable asset constraints for Sting3D
- create a small asset intake workflow:
  - inspect
  - simplify
  - test one asset
  - then scale placement

---

# Closing Note

The important part of this work was not just making trees render or adding fog. It was building a better sense of how to choose assets, inspect them, diagnose failures, and integrate features incrementally in a custom engine.

That is exactly the kind of workflow maturity that makes future rendering work faster and more reliable.
