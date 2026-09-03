# Enemy Detection Demo

A small LÖVE2D (Love2D) demo showcasing stealth & basic enemy detection/navigation: field-of-view detection, line-of-sight blocking via an obstacle, and a simple state machine (idle → chasing → searching).

**[▶ Play in browser](https://dev-bogdan.itch.io/enemy-detection-demo)**

## Features

- Cone-based field of view with line-of-sight blocked by an obstacle
- Enemy state machine: `IDLE` → `CHASING` → `SEARCHING` → back to `IDLE`
- Enemy remembers and moves to the player's last known position when it loses sight
- Idle/searching head sweep animation
- Circle vs. rectangle collision so the enemy can't clip through the obstacle
- Visual feedback: color-coded state (green/yellow/red), on-screen status text, "spotted" alert icon, and a brief screen shake when the player is detected

## Controls

- **Arrow keys** — move the player

## Tech

Built with [LÖVE2D](https://love2d.org/) (Lua). Web build exported using [love.js](https://github.com/Davidobot/love.js).