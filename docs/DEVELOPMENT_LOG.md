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

## 2026-08-25 — New-server recovery baseline / 新服务器恢复基线

- Verified the restored game and development-assets repositories against their Git remotes before resuming development.
- Created the isolated `codex/fungi-next` worktree at `/home/ubuntu/fungi/worktrees/codex-fungi-next`; the archived `main` checkout remains untouched.
- Re-ran resource import, all 60 smoke tests and the real main-scene startup on Godot `4.7.stable.official.5b4e0cb0f`; all gates passed from a clean source tree.
- Re-exported fresh Windows and Web builds, then created repository bundles, a manifest and SHA-256 checksums under `/home/ubuntu/fungi/releases/recovery-20260825T1115JST-6c8886d/`.
- Browser-tested save loading, visible frame-sliced offline settlement, right-click extension cancellation, developer upgrade controls, bacterial-diet hunt-zone entry, equal main-core/barracks scale and far-zoom pixel LOD.

- 在恢复开发前，先把新服务器上的游戏仓库和素材仓库逐一与 Git 远端核对。
- 在 `/home/ubuntu/fungi/worktrees/codex-fungi-next` 建立隔离的 `codex/fungi-next` 工作树；归档后的 `main` 检出保持不变。
- 使用 Godot `4.7.stable.official.5b4e0cb0f` 从干净源码重新执行资源导入、全部 60 项冒烟测试和真实主场景启动，全部通过。
- 重新导出 Windows 与 Web 构建，并在 `/home/ubuntu/fungi/releases/recovery-20260825T1115JST-6c8886d/` 保存仓库 bundle、构建清单和 SHA-256 校验值。
- 通过实际浏览器复核读取存档、分帧离线结算进度、右键取消延伸、开发者升级控制、细菌食性猎区入口、主基地与兵营等比例，以及远景粗像素 LOD。

## 2026-08-28 — Portable split Windows package / Windows 便携拆包

- Changed the Windows export from one embedded executable to `FungiMicroculture.exe` plus an external `FungiMicroculture.pck` resource pack. The two files remain portable and must stay in the same extracted folder.
- Added `tools/package_windows_portable.sh` so future Windows ZIPs are built through one repeatable command and replace older archives atomically only after validation.
- Added real Godot export and ZIP-content smoke gates. They reject an embedded-only export, a missing PCK, empty files, nested paths or unexpected archive entries.
- Added a Windows PowerShell runtime gate that extracts the finished ZIP, launches the EXE against its adjacent PCK in headless mode, and requires a clean bounded exit. Its gate logic is self-tested with a temporary fixture; the actual game build remains a separate final Windows-machine gate.
- Updated the package instructions and all seven repository-language introductions to describe the split layout.
- Verified resource import, all 60 game smoke tests and the real main-scene startup after the packaging change.

- Windows 导出由资源内嵌的单一 EXE 改为 `FungiMicroculture.exe` 加独立资源包 `FungiMicroculture.pck`；两者仍可便携运行，但解压后必须保留在同一文件夹。
- 新增 `tools/package_windows_portable.sh`，今后的 Windows ZIP 可通过一条可重复执行的命令生成；新包校验通过后才会原子替换旧包。
- 新增真实 Godot 导出与 ZIP 内容门禁；若仍为单文件、缺少 PCK、存在空文件、嵌套路径或意外文件，测试会直接失败。
- 新增 Windows PowerShell 运行门禁：解压最终 ZIP，以无界面模式启动使用同目录 PCK 的 EXE，并要求在限定时间内正常退出。门禁逻辑已用临时测试程序自测，真实游戏构建仍须在最终 Windows 机器上单独执行。
- 同步更新包内说明和七种仓库语言介绍。
- 修改后重新通过资源导入、全部 60 项游戏冒烟测试及真实主场景启动。

## 2026-09-13 — 48-hour offline progress / 48 小时离线结算

- Applied the user's confirmed 48-hour gathering/queued-production cap at the settlement entry point. Existing two-hour bacteria, combat, hazard, recovery and orphan-decay windows remain unchanged.
- Localized the return report in all seven supported languages, fitted long strings to their columns, and corrected stale offline rules in repository introductions.
- Added controlled 20-minute / 2-hour / 24-hour / 48-hour / 72-hour tests for finite resources, prepaid DNA, exact-cap behavior and direct-call clamping. These fixtures do not claim to represent a normal new player's progression.
- Expanded the asynchronous save-load fixture to 420 bacteria, 28 feeders and 64 expedition units without relaxing its 750 ms load-return and 30 s settlement gates.
- Fixed missing resource ID `-1` unnecessarily scanning the world, pruned exhausted offline search indexes, and added transient empty-world idle caching with exploration, resource and command invalidation.
- Final server verification passed resource import, all 63 smoke tests and main-scene startup in 101 seconds. Summary: `/home/ubuntu/fungi/test-logs/20260912T160609Z-2700278/summary.txt`.

- 按用户确认，将离线采集及排队生产封顶改为 48 小时，在内部入口也执行截断；细菌、战斗、毒素、恢复和断联衰败保留既有 2 小时窗口。
- 离线报告补齐七种语言，长译文适配列宽，并纠正仓库介绍中的旧离线规则。
- 新增长时间受控产速、有限资源、预付 DNA、上限边界测试；这些样本不等同于正常玩家完整成长路线，未宣称整章平衡已经完成。
- 密集读取样本扩大至 420 细菌、28 条吸收丝和 64 孢子，未放宽原性能门槛。
- 修复无资源目标时遍历全图的开销，并优化已耗尽资源索引和无事可做的离线采集单位；缓存不写入存档，探索变化、资源出现和指令变化会使其失效。
- 最终资源导入、63 项冒烟测试及主场景启动全部通过，用时 101 秒；详细数值与范围见 [离线记录](OFFLINE_PROGRESS_48H.zh-CN.md)。本轮未发布新的 Windows 包。

## 2026-09-13 — One local test installation and opening progression / 单份本地测试版与开局路线

- Changed daily testing to one fixed Windows installation at `%USERPROFILE%\Documents\战舰\fungi-test`. The executable and external resource pack remain separate; later updates replace the managed files in place and remove the downloaded ZIP. Browser preview is optional, not the default delivery route.
- Added a checksum-verified updater that runs the real executable/PCK startup gate before replacement, refuses to overwrite a running game, preserves unrelated files and saves, and rolls back partial replacement failures. A build manifest records the source commit, ZIP hash and installation time.
- The updater self-test passed two successive replacements, archive/backup cleanup, preservation checks, running-process/hash/root/missing-PCK rejection and an actual locked-file rollback scenario.
- Added a deterministic normal-map 20-minute opening regression without developer grants or price changes. The scripted route reached the first DNA at 398.75 seconds, the bacterial diet at 800 seconds, a barracks at 815 seconds and the first forager at 845 seconds; resource accounting passed.
- This is scripted reachability, not a human playtest or a claim of complete chapter balance. Cargo return income and normal-route 2/24/72-hour progression remain unverified; queued DNA still requires prepaid resources and does not refill itself.

- 日常测试改为本机固定目录，每次只保留一份当前版本，继续采用 EXE 与 PCK 拆分布局。更新成功后删除下载 ZIP，不覆盖用户存档或无关文件；浏览器预览改为可选工具。
- 新增带 SHA-256 校验、真实 EXE 启动检查、运行中拒绝覆盖和失败回滚的更新工具；构建记录包含源码提交号、压缩包校验值和安装时间。
- 更新器已通过连续两次覆盖、旧包清理、保留用户文件、错误输入拒绝，以及锁定文件造成中途失败后的真实回滚自测。
- 新增普通地图前 20 分钟脚本回归，不补资源、不改价格；首份 DNA 约 6 分 39 秒、食性 13 分 20 秒、兵营 13 分 35 秒、首个游猎孢子 14 分 05 秒，收支守恒通过。
- 不将脚本路线当作真人平均体验；返巢收益、普通路线 2/24/72 小时进展及整章平衡仍待验证。具体路线和限制见 [开局验证](CHAPTER1_OPENING_PROGRESS.zh-CN.md)。
- Final server verification passed resource import, all 64 smoke tests and headless main-scene startup in 125 seconds. Summary: `/home/ubuntu/fungi/test-logs/20260912T173403Z-2708159/summary.txt`. The Windows installer separately runs the actual downloaded executable before replacing the current local version.
- 最终服务器回归通过资源导入、全部 64 项冒烟测试与无界面主场景启动，用时 125 秒。本地安装器还会在覆盖前单独启动实际下载的 Windows EXE；该启动检查不等同于人工画面验收。

## 2026-09-13 — Chapter 1 closing loop and composite victory / 第一章收尾与复合通关

- Audited the actual existing chapter chain, long-term rewards, failure flow and teaching text before adding features. The old nine-step ending/report already existed; the missing evidence was normal long-term reachability, not the absence of a report.
- Added a finite-resource expedition-cycle regression: paid production, natural travel/gathering, three unloads (3.000 / 3.000 / 2.250), automatic departure, manual-order priority, exhausted-zone behavior and per-step conservation. It is explicitly a prebuilt-barracks mechanism fixture, not a normal opening-time estimate.
- Added an optional two-hour diagnostic that reuses the paid normal opening and then issues no new player orders. Its completed run retained two living cores, but lost the barracks; DNA had no queued jobs and local feeder uptake stopped increasing after about one hour. This is not a natural victory or a 24/72-hour balance sign-off.
- Added seven-language last-DNA-job feedback, persistent idle wording in core status, and an option to reopen the chapter report from the completed chapter card. Offline production no longer emits individual completion toasts.
- Corrected seven-language Esc guidance for founder movement/germination and prepaid DNA. Report copy now states the actual achievement and warns that continued cultivation can face further rival sporefalls.
- The user confirmed a combined economic/expansion/combat ending. Added supply and expansion tasks, making an eleven-step chain: 500 organic and 25 mineral absorbed by hyphae, 6 organic returned by expeditions, three living cores, 1 mm of mature non-orphaned hyphae belonging to living cores, and one defeated rival colony.
- Added live-condition checks so an in-progress save cannot bypass economic goals with a stale task index. Saved rule version 2 preserves earned legacy completions, rechecks unfinished old saves, and retains developer-mode manual stage controls. New target values are a first testable baseline, not an artificial three-day wait or proven final balance.

- 先审计已有目标、报告、奖励和失败流程，避免把“尚未自然通关验收”误说成“报告机制没做”。
- 真实有限资源的三趟采集返巢回归通过，包含不足满载的尾批、手动优先和耗尽后不重复入账。
- 两小时无人继续操作的诊断完成：没有全灭，但兵营死亡，DNA 队列为空，菌丝吸收停滞。它不能替代主动经营到通关、24/72 小时节奏或真实玩家体验验证。
- 补齐七语 DNA 队列结束提示、核心停产状态、重看章节报告和准确的通关后威胁说明；Esc 指引不再误导开局与资源扣费方式。
- 用户正式确认复合通关，章节引导由 9 步扩展至 11 步。实际吸收、返巢交付、存活核心、有效菌丝和竞争菌落击败共同构成第一版条件。
- 存档增加规则版本；旧已完成不撤销，旧未完成重核新条件，开发者跳转保留。具体门槛、诊断结果和未完事项见 [收尾审计](CHAPTER1_FINISH_AUDIT.zh-CN.md)。
- Independent review caught a coupling between the now-reversible chapter index and forager auto-attacks. Combat target selection now depends on unit capability, visibility and range; losing a core no longer silently revokes automatic attacks. Regression coverage includes that retreat and fog-of-war boundary.
- Persisted the rules under which a save earned completion, so resaving an old completed run does not imply it met the new economy thresholds; the report uses a separate seven-language legacy notice.
- 独立审查修复了目标回退会误关自动进攻的问题，并加入“战中失核后重新寻敌”和黑幕边界回归。另保存通关规则来源，旧完成档二次存读后仍显示旧版说明。
- Final gameplay verification passed resource import, all 68 smoke tests and main-scene startup in 129 seconds: `/home/ubuntu/fungi/test-logs/20260912T183227Z-2736783/summary.txt`. Windows and Web exports exclude developer-only tools, including the optional long-session probe.
- 最终资源导入、68 项冒烟测试及主场景启动全部通过，用时 129 秒；导出排除仅用于开发的工具和长诊断脚本。完整第一章自然通关、24/72 小时经营曲线与 Windows 图形试玩仍未宣称完成。

## 2026-09-13 — Work feedback and normal supply route / 工作反馈与普通补给路线

- Added seven-language per-resource core uptake states and contextual expedition work hints in hover/selection UI. The text distinguishes growing connections, gathering, cargo awaiting delivery, patrols, manual holds and recovery. A failed local search does not imply global resource depletion.
- Feedback only reads existing bounded feeder data and unit states. The harvest search flag is transient, populated by the existing search, cleared on zone removal/re-entry and not saved. No new map search runs from the unit HUD, and no automatic orders, resource costs or per-unit toasts were added.
- Extended the paid normal-map opening through a persistent harvest zone and four additional paid hypha segments. Supply and expansion completed at 1385.5 simulated seconds with three healthy cores; the rival remains alive. This is reachability, not a natural victory, a human timing estimate or a 24/72-hour balance sign-off.
- The natural second delivery exposed a floating-point total of 5.99999999999996 instead of 6. Goal comparisons and display now share a 1e-8 normalization tolerance, while 5.999 remains insufficient. Test fixtures cover this boundary and the real route reproduces it without injecting cargo.

- 核心状态/悬停分别说明有机与矿物的连接情况；孢子选择框/悬停显示实际工作原因。未设采区仍可自动采集，不误报成故障；没有可用兵营的负伤待援不误报为缺营养。
- 新增普通地图补给扩张回归：四段菌丝实际花费 46.000 有机，两趟各带回 3.000；23 分 05.5 秒满足补给和扩张，竞争菌落仍存活。保留三条小数收支与完整坐标记录，见 [路线验证](CHAPTER1_SUPPLY_EXPANSION.zh-CN.md)。
- 由真实交付检出并修复浮点目标卡住，未改价格或降低门槛。新增反馈测试覆盖七语、连接有效性、采区搜索结果失效、无副作用及 1280/640 布局绘制路径；无界面测试不能替代 Windows 画面试玩。
- Final server verification passed resource import, all 70 smoke tests and headless main-scene startup in 161 seconds: `/home/ubuntu/fungi/test-logs/20260912T190449Z-2752689/summary.txt`. Read-only review found no blocking issues with selection-panel spacing, transient feedback state or the numeric tolerance.
- 最终服务器回归通过资源导入、70 项冒烟测试和主场景启动，共 161 秒。独立只读审查未发现选择框间距、临时提示字段或浮点容差的阻断问题；Windows 人工图形验收仍待完成。
