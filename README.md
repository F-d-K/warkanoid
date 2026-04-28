# Warkanoid

A retro breakout game built with Godot 4.5, featuring hand-crafted pixel-art levels inspired by iconic 80s/90s game sprites, a neon wireframe aesthetic, and a built-in level editor.

![Godot 4.5](https://img.shields.io/badge/Godot-4.5.1-blue) ![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey)

## Features

- **5 hand-crafted levels** — each level is a pixel-art silhouette of a classic arcade character:
  - Level 1 — Space Invader
  - Level 2 — Pac-Man
  - Level 3 — Mushroom (Super Mario)
  - Level 4 — Ghost
  - Level 5 — Galaga fighter

- **Animated perspective grid** — a scrolling 3D wireframe background that pulses on ball bounces and brick hits

- **Enemies** — up to 3 roaming violet diamond entities that deflect the ball on contact and score 25 × level points when destroyed

- **Power-ups** — wide paddle, multi-ball, fireball, and slow-ball, dropped randomly (20% chance) by destroyed bricks

- **Level editor** — paint your own 11 × 12 levels with 4 brick HP tiers + indestructible bricks, save and test instantly

- **Screen shake & explosion particles** — camera shake and colorful particle bursts on brick hits, power-up pickups, and ball loss

- **Ball speed scaling** — ball gets faster each level (+20 px/s per level)

- **Scanline overlay** — configurable CRT scanline effect (intensity and spacing)

- **Options screen** — fullscreen toggle plus scanline intensity and spacing controls

- **Top-5 leaderboard** — best five scores saved between sessions; game-over screen highlights your new entry

## How to play

| Action | Control |
|---|---|
| Move paddle | Mouse |
| Launch ball | Left click |
| Pause / menu | ESC |

Destroy all non-indestructible bricks to advance to the next level. Indestructible bricks (grey, marked **X** in the editor) cannot be broken.

## Power-ups

| Label | Name | Effect | Duration |
|---|---|---|---|
| WIDE | Wide paddle | Paddle width ×1.5 | 8 s |
| MULTI | Multi-ball | Spawns 2 extra balls | — |
| FIRE | Fireball | Ball passes through bricks | 8 s |
| SLOW | Slow ball | Ball speed ×0.6 | 8 s |

Power-ups fall as pulsing hexagons; catch them with the paddle before they exit the bottom of the screen.

## Level editor

Accessible from the main menu. Paint bricks with left click, erase with right click, drag to fill. HP values 1–4 set brick color and toughness; **X** places an indestructible brick. Use **<<** / **>>** to navigate levels, **SAVE** to persist, and **TEST** to play the level immediately.

Custom levels are stored in `user://levels/` and cycle with the built-in ones beyond level 5.

## Building from source

Requires **Godot 4.5.1** with Windows Desktop export templates installed.

```bash
# Run in editor
godot --path Warkanoid/

# Export Windows executable
godot --headless --path Warkanoid/ --export-release "Windows Desktop" build/warkanoid.exe
```

## Project structure

```
Warkanoid/
├── levels/          # Built-in JSON level definitions
├── scenes/          # .tscn scene files
├── scripts/         # GDScript source files
├── shaders/         # GLSL shaders (grid, plasma, scanlines)
└── project.godot
build/               # Exported executable (not tracked in git)
```

## Credits

Built with [Godot Engine](https://godotengine.org) 4.5.1.
