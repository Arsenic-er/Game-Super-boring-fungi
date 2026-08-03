[**English**](README.en.md) | [简体中文](README.zh-Hans.md) | [繁體中文](README.zh-Hant.md) | [日本語](README.ja.md) | [Español](README.es.md) | [Deutsch](README.de.md) | [Русский](README.ru.md)

# Game: Super boring fungi

An idle evolution and expansion game about growing from a microscopic spore into a force capable of reshaping ecosystems, societies, nations, and eventually the planet.

The project is currently an early Windows prototype, version `0.44.0`. Chapter 1 is a top-down laboratory microculture where the player controls only the fungus, grows a mycelial network, collects nutrients, evolves new abilities, and commands mobile expedition spores. Version 0.40 adds role-safe commands so units no longer gather or attack targets that do not match their specialization.

Version 0.41 shows the seven-language selector on the first launch of a new installation and provides Simplified Chinese, Traditional Chinese, English, Japanese, Spanish, German, and Russian text for the resource HUD, core radial actions, core status and common hover tooltips, expedition status, bacterial descriptions, and all ten unit names; the upgrade shop and full long-term-goal descriptions are not yet fully localized.

Version 0.42 localizes all 22 long-term goals, the evolution-shop shell, node and survival upgrades, structure upgrades, the general barracks page, the lower barracks status panel, and detailed text for three specialist units in all seven languages. Diet detail pages, bacterial components, diet-exclusive unit pages, purchase and barracks interaction toasts, and chapter guidance, ecology-event, and Rival Sporefall text remain for later localization.

Version 0.43 adds a six-page illustrated gameplay guide to the Esc pause menu. It explains germination, nutrients and DNA, evolution, barracks commands, exploration and goals, and colony survival in all seven interface languages, with a dedicated coarse-pixel image beside every topic.
Version 0.44 completes seven-language diet detail, bacterial-component and diet-specialist pages, and localizes evolution purchases, unlocks and failure feedback. Long labels now scale inside their pixel UI controls, including Spanish, German and Russian.

## Download and play

Open the repository's [latest Release](https://github.com/Arsenic-er/Game-Super-boring-fungi/releases/latest), download the Windows ZIP, extract it, and double-click `FungiMicroculture.exe`.

- Platform: Windows 10/11, 64-bit
- Installation: none; game data is embedded in the executable
- Save data: stored separately in the current Windows user's application-data directory
- Windows may show a SmartScreen warning because this hobby build is not code-signed

## Core gameplay

- Explore a large, zoomable laboratory culture containing clustered organic nutrients, mineral ions, bacterial colonies, rival fungi, and persistent fog of war.
- Germinate from one spore core, extend primary hyphae, and grow fine absorbing branches that accumulate resources slowly with fractional precision.
- Spend nutrients to produce DNA, buy reversible evolution, structure, survival, adaptation, and diet upgrades, and complete long-term goals with distinct rewards.
- Manage three-decimal biomass, toxin damage, gradual recovery, repair retreats, and the decay or reconnection of isolated hyphae.
- Build barracks cores and produce specialized spores for gathering, transport, mineral collection, scouting, bacteria combat, fungi combat, and area deployment.
- Assign persistent square defense, harvesting, or bacteria-purge zones; compatible units resume their missions after unloading, repair, replenishment, and capped offline progress.
- Version 0.40 permits only compatible roles to gather or attack a target. Incompatible units in a mixed group move near the destination and hold position, while the command receipt reports exact, fallback, and unavailable counts.
- Face bacterial blooms, toxin zones, recurring rival sporefall, resource anomalies, fog-limited exploration, long idle progress, and an original multi-channel pixel-laboratory soundscape.

## Controls summary

- Core DNA: click for 1, Shift-click for 5, or Ctrl-click for 10
- Left click: inspect a core, choose an action, or select expedition spores
- Left drag: select units with a rectangle
- Right click: issue movement, gathering, combat, hypha-severing, or deployment orders
- `Z`: define a square defense zone
- `X`: define a square harvesting zone
- `V`: define a square bacteria-purge zone
- `C`: clear selected units' manual or persistent orders and return healthy units to role-appropriate automatic behavior
- `R`: return selected expedition spores to their barracks
- Right drag / middle drag: move the camera
- Mouse wheel: zoom
- `E`: open the evolution shop
- `G`: open long-term goals
- `F5`: save immediately
- `Esc`: close a panel, cancel an action, or pause/resume

## Planned scale progression

The microculture is only the beginning. Future independent chapters are intended to move through microorganisms and cells, small organisms and objects, ecosystems, human society, cities, countries, and the modern Earth. Traits evolved at earlier scales are intended to influence later spreading and conquest strategies.

## Development

The project uses Godot `4.7` with GDScript. Open `project.godot` in Godot to run the source project. Automated smoke tests live in `tests/`; the Windows export preset embeds the game data into one executable.

## Rights

Copyright © 2026 koko. All rights reserved.

The source code, visual assets, audio, game design, text, and other repository contents are publicly viewable for evaluation only. **No permission is granted to copy, reuse, modify, redistribute, create derivative works from, or commercially exploit them.** The official compiled release may only be downloaded and run for personal play and evaluation. See [LICENSE](../../LICENSE).
