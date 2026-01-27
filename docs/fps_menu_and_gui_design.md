# FPS Aim Trainer – Menu, GUI & UX Design

## 1. UI Philosophy
- Minimal
- Fast
- Low visual noise
- Keyboard + mouse friendly
- No blocking gameplay logic

---

## 2. GUI Technology Options

### Recommended
- **Immediate Mode GUI**
  - Dear ImGui (C/C++ binding via D)
  - Or custom lightweight IMGUI

Advantages:
- Fast iteration
- Minimal state management
- Ideal for tools & settings

---

## 3. Menu Structure

### 3.1 Main Menu
- Start Training
- Game Mode Select
- Weapon Select
- Settings
- Quit

---

### 3.2 Game Mode Menu
- Timed (30s / 60s)
- Endless
- Difficulty preset

---

### 3.3 Weapon Select Menu
Each weapon shows:
- Fire rate
- Accuracy modifier
- Score multiplier

Weapons share core logic; stats are data-driven.

---

### 3.4 Settings Menu

#### Controls
- Mouse sensitivity
- Invert Y-axis
- ADS sensitivity (future)

#### Graphics
- Resolution
- Fullscreen / windowed
- VSync
- FOV slider

#### Audio
- Master volume
- SFX volume
- Music volume

---

## 4. In-Game HUD

- Crosshair
- Timer
- Score
- Accuracy
- Current weapon

HUD should:
- Be toggleable
- Use simple text + shapes

---

## 5. Menu Architecture

### 5.1 State Machine
- MENU
- PLAYING
- PAUSED
- RESULTS

### 5.2 UI Flow
Menus should:
- Modify a shared `GameConfig` struct
- Apply changes before round start
- Avoid reinitializing engine systems

---

## 6. Data-Driven Configuration

Use config files (JSON / TOML):

```json
{
  "mouse_sensitivity": 0.8,
  "fov": 90,
  "weapon": "rifle",
  "round_time": 60
}
```

---

## 7. Implementation Strategy

1. Integrate IMGUI with OpenGL
2. Build static menus first
3. Bind menu widgets to config variables
4. Apply config on game start
5. Add polish last

---

## 8. UX Rules
- No nested menus deeper than 2 levels
- All sliders show numeric values
- Escape key always goes back
- Changes preview instantly where possible

---

## 9. Future Enhancements
- Preset profiles
- Saved loadouts
- Performance graphs
- Training history

---

## 10. Success Criteria
- Menu loads instantly
- No noticeable FPS impact
- User can fully configure a session without restarting the game
