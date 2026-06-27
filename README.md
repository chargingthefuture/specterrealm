# SpecterRealm

First-person endless runner survival shooter built with Godot 4.x — inspired by Into the Dead 2.

Ships as an **installable, offline-capable Progressive Web App (PWA)** so you can
play in the browser or "Add to Home Screen" on iOS/Android — no App Store, no
Apple tax, no install fees.

## Play on iOS / Android (PWA — no App Store)

The game is exported to WebAssembly and deployed to **GitHub Pages** by CI on
every push to `main` (see `.github/workflows/deploy-pwa.yml`). Once deployed,
the live URL is:

```
https://chargingthefuture.github.io/specterrealm/
```

**Install it to your home screen (iOS Safari):**

1. Open the URL above in **Safari** (PWA install only works in Safari on iOS).
2. Tap the **Share** button → **Add to Home Screen** → **Add**.
3. Launch it from the home-screen icon — it opens full-screen, with no browser
   chrome, and **works offline** after the first load (the assets are cached by
   the generated service worker).

On Android/Chrome you'll get an **Install app** prompt in the address-bar menu.

> **One-time repo setup:** in **Settings → Pages**, set **Source = GitHub
> Actions**. The `Deploy PWA` workflow handles the rest. The Pages deploy runs
> on pushes to `main`, so merge this branch to publish the live build.

## Controls

### Touch (iOS PWA / any touchscreen)

On-screen buttons appear automatically on touch devices:

| Action | Control |
|---|---|
| Switch lane | **◀ / ▶** buttons (bottom-left) |
| Shoot | **FIRE** button — hold to keep firing (bottom-right) |
| Reload | **RELOAD** button (bottom-right) |

### Keyboard + mouse (desktop / web)

| Action | Key |
|---|---|
| Switch lane left | A / ← |
| Switch lane right | D / → |
| Shoot | Left mouse button (hold to keep firing) |
| Reload | R |
| Pause | Escape |
| Mouse look | Move mouse (vertical aim only) |

### Game controller (gamepad)

Controllers work everywhere the game runs — including the installed iOS PWA,
where Safari exposes paired Bluetooth controllers (PlayStation / Xbox, iOS 14+)
through the browser Gamepad API. Just pair the controller and play; no extra
setup.

| Action | Control |
|---|---|
| Switch lane | D-pad ◀ / ▶ or left stick |
| Aim (vertical) | Right stick |
| Shoot | Right trigger (RT/R2) or A / ✕ — hold to keep firing |
| Reload | X / □ |
| Restart (on game over) | A / ✕ |

## Building the PWA locally (optional)

You need Godot **4.3** with the **Web export templates** installed
(*Editor → Manage Export Templates*).

```bash
cd game
godot --headless --export-release "Web" ../build/web/index.html
```

Then serve `build/web/` over HTTP (PWAs require `http://`/`https://`, not
`file://`):

```bash
python3 -m http.server --directory build/web 8080
# open http://localhost:8080
```

The export is configured (in `export_presets.cfg`) as **single-threaded**, so it
runs on static hosts like GitHub Pages with **no special COOP/COEP headers** and
is compatible with iOS Safari.

## Develop in the Godot Web Editor

1. Open [https://editor.godotengine.org](https://editor.godotengine.org) in your browser
2. Click **"Import"** and select the `game/` folder from this repository
3. Godot will import all scenes and scripts automatically
4. Press **F5** (or the ▶ Play button) to run from `scenes/main.tscn`

> The web editor works on low-end hardware. Use Chrome or Firefox for best performance.

## Project Structure

```
game/
├── project.godot          # Godot project config + input map + autoloads
├── export_presets.cfg     # Web/PWA export preset (offline, single-threaded)
├── icon.svg               # App / editor icon
├── icons/                 # PWA manifest + iOS home-screen icons (144/180/192/512)
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
