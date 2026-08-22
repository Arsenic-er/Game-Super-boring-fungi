# Development Log / 开发日志

This log preserves the major implementation milestones and the final server-archive state. It is a curated development record rather than a raw chat transcript or a copy of transient runtime logs.

本文记录主要开发里程碑与服务器归档状态，不保存聊天原文、凭证或无长期价值的运行时日志。

## 2026-07-14 — Initial playable prototype / 初始可玩原型

- Created the Godot Chapter 1 laboratory microculture.
- Added primary/fine hyphae, clustered nutrients, fractional uptake, DNA production, upgrades and the first Windows build.
- Established the bilingual repository, pixel-art visual direction and all-rights-reserved distribution policy.

## 2026-07-24 — Exploration, ecology and rival colony / 探索、生态与竞争菌落

- Added fog of war, scout spores, anomaly discovery and expedition rewards.
- Added bounded offline settlement and return reports.
- Added bacterial ecology events, barracks commands and the first rival-fungus simulation.

## 2026-07-27 — Combat roles and sound / 战斗兵种与声音

- Added chapter guidance, session controls, expedition attrition and recurring Rival Sporefalls.
- Added enemy-hypha severing, bacterial suppression pods, ranged lytic dispersers, antifungal pods and rival guard spores.
- Added the procedural “pixel laboratory nebula” soundscape and interaction sound routing.

## 2026-07-27 to 2026-08-01 — Persistent RTS zones / 持久区域指令

- Added square defense, harvesting and bacterial purge zones.
- Added per-barracks persistent directives inherited by automatic replacements.
- Added the long-term goal tracker and batch DNA production.

## 2026-08-02 to 2026-08-05 — Seven-language UI and developer tools / 七语界面与开发工具

- Added role-safe expedition commands and exact command receipts.
- Expanded the repository and game UI to Simplified Chinese, Traditional Chinese, English, Japanese, Spanish, German and Russian.
- Added the illustrated Esc gameplay guide.
- Localized goals, upgrades, barracks, diet workflows, chapter guidance, ecology events and rival combat.
- Made save loading responsive through frame-sliced offline settlement.
- Added an isolated developer sandbox with entity placement and freely adjustable upgrade levels.
- Fixed fine feeder branches detaching from animated parent hyphae.
- Replaced the barracks unit-cycle control with a square production roster and atomic 1/5/10 batches.

## Unreleased working tree archived on 2026-08-22 / 2026-08-22 归档的未发布工作树

The server contained valid development work after public version `0.49.0`. This archive commits that state without presenting it as a new finished release.

服务器在公开版本 `0.49.0` 后仍有有效开发内容。本次把该工作树归档，但不把它标记为新的正式发行版。

### Startup and save reliability / 开局与存档可靠性

- Added a mobile founder spore with rest/elongated/contracted frames, limited movement energy and a germination sequence.
- Added save validation plus primary, temporary and backup recovery through `scripts/save_store.gd`.
- Added first-launch language selection artwork using the infected Earth-and-Moon pixel logo.

### Pixel scale and production sprites / 像素尺度与正式贴图

- Added dedicated main-core and barracks 24 px / 12 px LOD sprites with an equal 48-world-unit footprint.
- Added full and simplified evolution atlases for all ten expedition-spore roles.
- Added early, middle and mature visual stages while preserving unit footprint.
- Changed distant rendering to projected-pixel LOD and coarse markers instead of shrinking complex concept art.

### Economy and balance model / 经济与平衡模型

- Slowed base DNA production and reduced the per-node speed bonus.
- Added shared production throughput so parallel jobs do not multiply output without limit.
- Added per-core feeder bandwidth and node-level bandwidth bonuses.
- Reduced bacterial prey conversion into carried organic nutrients.
- Added diet-license accounting and penalized reversible diet respec.
- Limited simultaneous attackers around an enemy core.
- Extended and refactored offline simulation steps; the public README still needs a final product decision before these values are advertised.

### Interaction and fixes / 交互与修复

- Right-click now cancels hypha-extension targeting without losing the current selection.
- Strategic-zoom zone dragging now uses a zoom-aware threshold, fixing purge/hunt zones that were impossible to set at minimum zoom.
- Purge-mode feedback now explicitly explains the bacterial-diet requirement.
- Added seven-language toast severity and additional narrow-layout handling.

### Server tooling / 服务器工具

- Added `tools/server-test.sh` for isolated full verification.
- Added `tools/web_preview.sh` for reproducible headless web export and loopback-only preview serving.
- Added bilingual instructions in `docs/SERVER_TESTING.md`.

## Archive exclusions / 归档排除项

The following remain local build/runtime products and are intentionally not committed:

- `.godot/` import and editor cache.
- `build/` Windows and Web exports.
- `.web-preview/` PID, lock and server logs.
- Godot-generated `*.uid` and `*.import` metadata.
- Temporary `*.orig`, `*.tmp` and `*.log` files.
- Tokens, private keys, server credentials and connection details.

## Repositories / 仓库分工

- Public game repository: source, automated tests, build instructions and only the runtime assets required by the game.
- Private development-assets repository: source artwork, candidate boards, production-asset mirrors, fonts and their licenses, prompts, audio and design history.
