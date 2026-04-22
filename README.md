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

- **Animated perspective grid** — a scrolling 3D wireframe background that reacts to ball bounces and brick hits

- **Enemies** — roaming violet diamond entities that deflect the ball on contact and score points

- **Power-ups** — wide paddle, multi-ball, fireball, and slow-ball, dropped randomly by destroyed bricks

- **Level editor** — paint your own levels with 4 brick HP tiers + indestructible bricks, save and test instantly

- **Scanline overlay** — configurable CRT scanline effect

- **Hi-score persistence** — best score saved between sessions

## How to play

| Action | Control |
|---|---|
| Move paddle | Mouse |
| Launch ball | Left click |
| Pause / menu | ESC |

Destroy all non-indestructible bricks to advance to the next level. Indestructible bricks (grey, marked **X** in the editor) cannot be broken.

## Power-ups

| Icon | Name | Effect |
|---|---|---|
| W | Wide paddle | Paddle width ×1.5 for 8 seconds |
| M | Multi-ball | Spawns 2 extra balls |
| F | Fireball | Ball passes through bricks |
| S | Slow ball | Ball speed ×0.6 |

## Level editor

Accessible from the main menu. Paint bricks with left click, erase with right click, drag to fill. HP values 1–4 set brick color and toughness; **X** places an indestructible brick. Save your level and hit **TEST** to play it immediately.

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
