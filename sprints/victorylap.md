# Topshotaa — Remaining Features Priority List

## Current State (What Works)

- D engine with OpenGL 4.1, SDL2, Apple M2
- Bullet physics: gravity, collisions, raycasting, entity destruction
- Assimp model loading: OBJ, FBX, glTF (static geometry + textures)
- FMOD audio: gunshot, footsteps, war ambience background loop
- ImGui HUD: kills, accuracy, ammo, health bar, timer, FPS, player name
- Camera: WASD ground movement, mouse look, 360 rotation
- Shooting: raycast from crosshair, hit detection, entity destruction
- Soldier enemies: glTF model with texture, physics collider (soldier.urdf)
- Map kit: FBX modular pieces with texture atlas, arena built from presets
- Crosshair rendering
- Light system with moving sun

---

## Priority 1 — Quick Wins (Do First, ~2 hours total)

### 1.1 Weapon Spread (15 min)
Add random offset to raycast direction on each shot. Different weapons get different spread.

In `shoot()`, after computing `dir`:
```
float spread = 0.02f; // adjust per weapon
dir.x += (random float -spread to +spread)
dir.y += (random float -spread to +spread)
dir.z += (random float -spread to +spread)
dir = Normalize(dir)
```

### 1.2 Ammo System (15 min)
Track current ammo, decrement on shoot, prevent shooting at 0. Reload on R key.

- `mCurrentAmmo = 30`, `mMaxAmmo = 30`
- In `shoot()`: if `mCurrentAmmo <= 0` return + play empty click sound
- Decrement `mCurrentAmmo--` on each shot
- On R key: set `mCurrentAmmo = mMaxAmmo` + play reload sound
- Update `mGui.currentAmmo` and `mGui.maxAmmo` in `Update()`

### 1.3 Round Timer Countdown (15 min)
Count down from 120 seconds. End round when timer hits 0.

- `mRoundTimer = 120.0` (seconds)
- In `Update()`: `mRoundTimer -= frameDt`
- Update `mGui.roundTimeSeconds = cast(int)mRoundTimer`
- When `mRoundTimer <= 0`: show results or stop game

### 1.4 More Sound Effects (30 min)
Add sounds for: reload, empty magazine click, hit confirmation, enemy death.

- Load WAVs in `loadSounds()`
- Play reload sound on R key
- Play empty click when ammo is 0 and player shoots
- Play hit sound when raycast hits an enemy
- Play death/explosion sound when entity is destroyed

### 1.5 Fix Soldier Texture Flashing (30 min)
The flashing happens because soldier material and map material both use `lit_textured` pipeline but bind different textures. Fix by creating a second pipeline copy.

Option A: Create `lit_textured_2` pipeline (duplicate shader files, different pipeline name) for soldiers.

Option B: Make `LitTexturedMaterial.Update()` always rebind its specific texture:
```d
override void Update() {
    PipelineUse(mPipelineName);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, mTextureID);
    if ("uTexture" in mUniformMap)
        mUniformMap["uTexture"].Set(0);
}
```

### 1.6 Add Soldiers Back Into Arena (15 min)
Uncomment soldier spawns, position them inside the arena layout:
```d
spawnSoldierEnemy(vec3(5.0f, 0.0f, -25.0f));
spawnSoldierEnemy(vec3(25.0f, 0.0f, -25.0f));
spawnSoldierEnemy(vec3(15.0f, 0.0f, -35.0f));
// etc — place them near buildings and behind cover
```

---

## Priority 2 — Gameplay Feel (~2-3 hours total)

### 2.1 Player Physics Body (1-2 hours)
Replace free-flying camera with a physics-driven capsule/box.

Steps:
1. Create `player.urdf` — box 0.5 wide × 1.8 tall × 0.5 deep
2. Add player body to Bullet on startup
3. Each frame: read keyboard input → apply forces/velocity to player body
4. Read player body position from Bullet → update camera position
5. Lock player body rotation (prevent tipping over)

This gives wall collision for free — Bullet handles it.

### 2.2 Jump (30 min, requires 2.1)
On spacebar: apply upward impulse to player physics body.
- Check if player is on ground (raycast downward, check contact with ground)
- If grounded: apply impulse `(0, jumpForce, 0)`
- Gravity brings player back down

### 2.3 Crouch (15 min)
On C key or Ctrl: lower camera Y by 0.5 units.
- Toggle `mCrouching` bool
- If crouching: camera Y offset = -0.5
- If standing: camera Y offset = 0
- Optional: slow movement speed while crouching

### 2.4 Sprint (10 min)
On Shift key: increase movement speed by 1.5x.
- Check `keys[SDL_SCANCODE_LSHIFT]`
- If sprinting: `moveSpeed = mMoveSpeed * 1.5`
- Play faster footstep sound or increase footstep rate

---

## Priority 3 — Visual Polish (~2-3 hours total)

### 3.1 Gradient Sky Background (30 min)
Replace flat clear color with a fullscreen quad that renders a vertical gradient.

- Create `sky` shader pipeline
- Vertex shader: fullscreen triangle/quad in NDC
- Fragment shader: mix(horizon_color, zenith_color, height)
- Render before scene, after clear

### 3.2 Weapon Viewmodel — Static Gun (1-2 hours)
Attach a gun model to the camera.

- Load gun FBX via Assimp (static, no animation)
- Each frame: set gun model matrix = camera transform × offset
- Offset: ~(0.3, -0.3, 0.5) relative to camera — right side, slightly down, forward
- The gun follows the camera automatically

### 3.3 Crosshair Hit Feedback (15 min)
When a shot hits an enemy, briefly change crosshair color to red.

- On hit: set `mCrosshairHitTimer = 0.2`
- Each frame: decrement timer, if > 0 use red color uniform in crosshair shader
- When timer reaches 0: revert to green

### 3.4 More Map Pieces (30 min)
Add more preset pieces to fill out the arena:
- More sandbag cover positions
- Add the base floor preset (child 0)
- Add metal walls around the perimeter
- Add a second building for flanking routes

---

## Priority 4 — Advanced Features (~1-2 days each)

### 4.1 Door Animation (1 hour)
Rigid animation — no bones.

- Identify door mesh in preset (Preset_10)
- Store door MeshNode reference
- On E key near door: lerp Y rotation 0→90° over 0.5s
- Pivot at hinge edge (offset translation before rotation)

### 4.2 Wall/Object Collision Without Player Physics (1 hour)
Simpler alternative to full player physics:

- Before moving camera, raycast in movement direction
- If ray hits something within 0.5 units, block that movement
- Simple but effective — no physics body needed

### 4.3 Gun Hands Animation (3-4 days)
Full skeletal animation pipeline:

1. Load bone data from FBX (bone hierarchy, vertex weights)
2. Load animation keyframes (position/rotation per bone per frame)
3. Build bone matrix palette each frame (interpolate keyframes)
4. New vertex shader with bone uniforms + skinning
5. Upload bone matrices each frame
6. Trigger fire/reload/idle animations on events

### 4.4 Enemy AI (4+ hours)
Basic AI behaviors:

- Patrol: walk between waypoints
- Alert: turn to face player when in range
- Attack: shoot at player (raycast from enemy to player)
- Take cover: move behind nearest cover object
- Death: play death animation or ragdoll

### 4.5 Stair Climbing / Obstacle Vaulting (2-3 hours)
- Step detection: if obstacle < step height, auto-raise player Y
- Vault trigger: if obstacle < vault height and player presses space near it
- Requires player physics body or manual height detection

---

## Priority 5 — Thesis Deliverables

### 5.1 Frustum Culling + Octree (2 days)
Required for thesis evaluation.

- Implement view frustum extraction from VP matrix
- AABB test for each object against frustum planes
- Octree spatial structure for efficient broad-phase
- A/B toggle: culling ON vs OFF
- Performance measurements: FPS, draw calls, objects rendered

### 5.2 Stress Test Scenes (1 day)
Create scenes with 100, 500, 1000 objects.

- Spawn objects in grid pattern
- Measure FPS with and without frustum culling
- Graph results for thesis

### 5.3 Performance Evaluation Document (1 day)
Write up methodology, results, analysis.

- Test hardware specs
- Object counts vs FPS tables
- Frustum culling speedup percentages
- Screenshots of stress test scenes

---

## Recommended Session Plan

### Session 1 (Today, ~3-4 hours)
- [x] 1.1 Weapon spread
- [x] 1.2 Ammo system
- [x] 1.3 Round timer
- [x] 1.5 Fix soldier flashing
- [x] 1.6 Soldiers in arena

### Session 2 (Tomorrow, ~3-4 hours)
- [ ] 1.4 More sounds
- [ ] 2.3 Crouch
- [ ] 2.4 Sprint
- [ ] 3.1 Gradient sky
- [ ] 3.3 Crosshair hit feedback
- [ ] 3.4 More map pieces

### Session 3 (~4-6 hours)
- [ ] 2.1 Player physics body
- [ ] 2.2 Jump
- [ ] 4.2 Wall collision (or skip if 2.1 done)

### Session 4 (~2-3 hours)
- [ ] 3.2 Weapon viewmodel (static gun)
- [ ] 4.1 Door animation

### Session 5+ (Multi-day)
- [ ] 5.1 Frustum culling + octree
- [ ] 5.2 Stress test scenes
- [ ] 5.3 Performance evaluation
- [ ] 4.3 Gun hands animation (if time)
- [ ] 4.4 Enemy AI (if time)