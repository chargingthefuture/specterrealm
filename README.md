# DeadRun

First-person endless runner survival shooter built with Godot 4.x — inspired by Into the Dead 2.

## Getting Started (Godot Web Editor)

1. Open [https://editor.godotengine.org](https://editor.godotengine.org) in your browser
2. Click **"Import"** and select the `game/` folder from this repository
3. Godot will import all scenes and scripts automatically
4. Press **F5** (or the ▶ Play button) to run from `scenes/main.tscn`

> The web editor works on low-end hardware. Use Chrome or Firefox for best performance.

## Controls

| Action | Key |
|---|---|
| Switch lane left | A / ← |
| Switch lane right | D / → |
| Shoot | Left mouse button |
| Reload | R |
| Pause | Escape |
| Mouse look | Move mouse (vertical aim only) |

## Project Structure

```
game/
├── project.godot          # Godot project config + input map + autoloads
├── scenes/
│   ├── main.tscn          # Root scene — entry point
│   ├── player/
│   │   └── player.tscn    # FPS CharacterBody3D with camera + weapon
│   ├── enemies/
│   │   └── zombie.tscn    # Basic zombie enemy
│   └── ui/
│       └── hud.tscn       # In-run HUD (health, ammo, score, game over)
├── scripts/
│   ├── game_manager.gd    # Autoload singleton: score, state, high score save
│   ├── main.gd            # Root scene controller, wires all systems
│   ├── player/
│   │   ├── player.gd      # Lane switching, mouse look, head bob, damage
│   │   └── weapon.gd      # Fire rate, raycast hit, reload, muzzle flash
│   ├── world/
│   │   ├── world_spawner.gd     # Procedural chunk spawning + speed ramp
│   │   └── environment_props.gd # Side atmosphere props (dead trees etc.)
│   ├── enemies/
│   │   └── zombie.gd      # Zombie AI: chase, attack, die + score emit
│   └── ui/
│       └── hud.gd         # HUD controller, connects to player + GameManager
└── assets/
    ├── textures/           # Drop .png/.jpg textures here
    ├── sounds/             # Drop .ogg/.wav audio here
    └── models/             # Drop .glb/.gltf meshes here
```

## Core Systems

### World Scrolling
The world moves toward the player rather than the player moving forward. `WorldSpawner` spawns ground chunks ahead and recycles them once they pass behind. Run speed increases every 10 seconds up to a configurable maximum.

### Lane System
Three lanes at X positions `-3`, `0`, `+3`. The player smoothly lerps between them on A/D input. Enemies and obstacles are placed per-lane at spawn time.

### Weapon
Raycast-based hitscan. Configurable damage, fire rate, ammo, and reload time via `@export` vars in `weapon.gd`. Swap values in the Godot Inspector without touching code.

### Scoring
`GameManager` (autoload singleton) accumulates score from enemy kills and persists the high score to `user://save.cfg`.

## Next Steps

- Replace placeholder box meshes with `.glb` character/weapon models
- Add `AudioStreamPlayer3D` nodes for gunshots, zombie groans, footsteps
- Add obstacle scene (`StaticBody3D` with collision) and assign it in `WorldSpawner`
- Add a start/title screen scene
- Tune `WorldSpawner` exports (speed, chunk density, enemy count) in the Inspector
- Add more enemy types by extending `zombie.gd`
