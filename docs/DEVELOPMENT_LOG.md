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

## 2026-09-13 — Real first victory, danger feedback and full-resource reliability / 真实首通、危险反馈与完整资源可靠性

- The user clarified the pacing target: a relatively quick first victory is acceptable; approximately three days refers to continued cultivation and long-term goals after victory. No mandatory three-day first-clear gate or blanket timer increase was added.
- Added a normal-map victory regression extending the unchanged paid opening and supply/expansion routes. It pays for two more DNA jobs, a forward barracks, real hyphae, ten basic foragers, one replacement and the level-one repair upgrade. The original rival dies through ordinary combat at 2243.5 simulated seconds, with current supply and living-network goals still satisfied and the version-two completion report open.
- The route produced twelve units in total, lost one, recorded ten unit-repair completions and defeated four rival guards. All four cores survive, with the front barracks at 81.369 biomass. Final organic/mineral/DNA balances are 633.441 / 92.338 / 1; cumulative payment is 715.000 / 31.000 / 9, checked against actual uptake, delivered cargo and earned rewards throughout combat.
- The final victory test passed in 51.112 seconds under the unchanged 120-second budget, exit code zero and no script/cleanup warnings. This proves fixed-route normal-mode reachability, not human-average timing, all-diet balance or three-day content completion. A default no-op `_after_victory()` hook lets separate long diagnostics continue the real completed world without adding days to ordinary CI.
- Added seven-language endangered-core feedback before severe toxin damage and at half biomass or below. Clicking locates the living core and opens status without automatic repair, spending or repeated query-driven toasts. `tests/core_attention_smoke.gd` passed its threshold, localization, 1280/640 layout-path and side-effect checks.
- Added damaged-network save/load coverage for real toxin death, orphan decay, paid rescue growth, ownership transfer, ordinary/developer save isolation and 48-hour settlement. Keeping all 3147 real deposits harvestable exposed a settlement over the original 30-second limit; the exhausted-resource fixture alone had hidden that workload.
- Replaced repeated full-map feeder-discovery curve projections with bounded spatial candidates while retaining source, range, ordering, resource-kind reservations and capacity rules. Fifty complete ordered-result comparisons against the `5d9e6cc` baseline passed. The default full-resource damaged-network run passed 77 assertions with 6 ms maximum synchronous load and 659 ms / 56 frames for settlement, without weakening the 750 ms / 30000 ms gates or adding warnings.
- A separate review identified abnormally huge saved-coordinate bounds; a fallback guard has been added, but its new boundary regressions are still pending. This pending case is not included in the preceding fifty-comparison claim.
- Nineteen real Windows Intel OpenGL captures were obtained, but the native-input tool is unavailable, so this is not a completed manual interaction playtest. Exit-time cursor GPU-texture cleanup is also still under repair/regression. The strengthened post-victory 72-hour strategy, complete current CI run and final local release remain pending; individual passing tests do not close those gates.

- 用户新确认：允许较快首通，约三天用于通关后继续经营和长期目标，不要求首次通关必须等待三天，不通过统一拉长计时器制造时长。
- 新增普通资源完整首通回归，复用原有前 20 分钟与补给扩张路线；真实付费建前线兵营、排 DNA、伸菌丝、生产游猎孢子、升级修复，再探索并击败最初竞争菌落。37 分 23.5 秒现行 11 步复合通关报告自然打开，供给和有效活网络条件仍满足。
- 全程生产 12 兵、损失 1 兵、付费补员 1 兵、10 次单位修复完成，击败 4 个护卫。四核存活，前沿兵营生物量 81.369；最终有机/矿物/DNA 为 633.441 / 92.338 / 1，累计支付 715.000 / 31.000 / 9，全程逐步核对真实收支。单项 51.112 秒、退出码 0、无警告，未放宽 120 秒预算。脚本不是玩家平均时间；详见 [真实首通](CHAPTER1_VICTORY_PROGRESSION.zh-CN.md)。
- 首通测试提供默认返回的 `_after_victory()`，让独立长诊断接续真实通关世界；默认冒烟不多跑三天，也不手填通关标记。
- 补齐七语核心毒素压力与低生物量提示、点击定位和恢复后的警报切换；无自动花费、自动修复或逐帧提示刷屏。危险反馈单项通过，最终人工交互和图形可读性仍须验收。
- 新增真实损伤网络的死亡、孤立衰败、付费接管、普通/开发者档和 48 小时读取交叉回归。完整 3147 个活资源揭露原 30 秒结算超时，空间候选查询修复后旧算法 50 次有序结果等价对照通过；默认完整资源路径 77 断言通过，最大读取 6 ms、结算 659 ms / 56 帧，无警告且不放宽门槛。保留原失败样本和日志，详见 [损伤网络与性能复验](CHAPTER1_DAMAGED_NETWORK.zh-CN.md)。
- 独立审查另发现异常存档巨大坐标范围的循环风险，已加回退保护，但新增边界测试仍待完成；不能混入此前等价通过的结论。
- Windows 已取得 19 张真实 Intel OpenGL 画面，原生输入工具故障使手工交互试玩尚未完成，退出光标 GPU 纹理释放问题也仍在回归。已有不足经营策略的 72 小时观察只能说明该策略存活但停滞；真实首通后的加强经营策略、本轮整套 CI、最终构建和本机单份覆盖仍待验收，不提前写成发布完成。

## 2026-09-13 — Chapter 1 technical close and local candidate / 第一章技术收尾与本地候选版

- Closed the abnormal-coordinate broad-phase regression with finite-index fallback: 54 ordered comparisons against the old algorithm and seven bounded-rectangle cases passed. The full-resource damaged save settles 48 hours in 651 ms / 56 frames in the focused rerun; the original gates remain unchanged.
- Long-session diagnostics uncovered a real scheduler starvation: a bloom waiting for bacterial population capacity could block Rival Sporefall forever. Capacity-blocked, unspawned bloom warnings no longer monopolize the scheduler; real warnings/active events, the full 90-second Sporefall warning, population limits, enemy strength and offline safety remain unchanged. Thirty-four focused assertions passed, including older saves and no invented rewards.
- Completed seven-language unit-filter abbreviations and the illustrated guide's explanation of combined chapter completion and continued cultivation. Preserved exact feeder-reservation assertions while rebuilding the stale resource-grid test fixture, and updated strict localization key assertions for the added labels.
- Final full verification passed import, **76/76 smoke tests**, and headless main-scene startup in 217 seconds: `/home/ubuntu/fungi/test-logs/20260912T201716Z-2808108/summary.txt`. Previous failed runs remain recorded; final counts do not imply every legacy diagnostic emits no cleanup warnings.
- Windows rendering produced 33 real Intel OpenGL captures. Releasing the custom cursor in `_exit_tree()` eliminated the reproduced exit-time GPU texture leak. The final split EXE/PCK also passed adjacent-pack startup and a 180-frame real OpenGL/default-WASAPI run (48 kHz stereo, exit zero, empty standard error). Native-input tooling remains unavailable, so these checks are not a human interaction or listening-quality sign-off.
- The Windows runtime gate now isolates APPDATA and LOCALAPPDATA and restores them in `finally`. Code commit: `301038f527d111598045e3f16973ee9189e59a84`, authored only by `Arsenic-er <302726993@qq.com>`; no co-author trailer. Package SHA-256: `2e43db7a05d3aea356c82437ac8401f08f59efbb7ef7c8ee72f2e70369db6f1e`.
- Replaced the sole local test installation at `C:\Users\jiang\Documents\战舰\fungi-test\FungiMicroculture.exe`. Kept EXE and PCK separate, preserved player saves, and removed the download, update backups and temporary visual runtime. The public release version is not relabeled; this is a tested development candidate, not a claim that every diet or three-day strategy is finally balanced.

- 异常坐标防护、满额事件互锁、七语筛选与通关后指引均完成；完整回归 76/76 通过，未放宽数值或时间门槛。
- Windows 真实图形与系统音频初始化正常，退出光标贴图泄漏已修复；未把截图当作真人手感验收。原生窗口输入工具故障仍如实记录。
- 本地固定目录已经覆盖，EXE / PCK 分离、存档保留，无第二份可运行测试版或遗留下载包。详见 [实机核验](WINDOWS_CHAPTER1_RENDER_QA.zh-CN.md)。
- 长经营诊断发现的保守策略停滞、恢复、新三天窗口及后续付费升级接入资源区实验分别保留于 [长会话记录](CHAPTER1_MANAGED_LONG_SESSION.zh-CN.md)，不把存活、探索增长或团簇潜在总量冒充已经收到的收入。
- Final bounded recovery demonstration used only existing mechanics: 25 DNA for branching level four and 137 organic for eleven naturally grown bridge segments. The real connection completed at 275 simulated seconds. At twenty minutes, actual new hyphal uptake was 241.898 and delivered cargo 36.000; a separate 25-organic goal reward was accounted independently. All seven cores and fifteen units survived, and explored cells rose from 176 to 220. The process exited zero in 105.195 seconds. This demonstrates a paid growth route after long cultivation, not a claim that sparse visits or every route sustain a positive economy.
- 最后用现有升级与已探索资源进行有界验证：25 DNA 升分枝、137 有机搭 11 段桥，275 秒真实接通；20 分钟新增吸收 241.898、返巢 36.000，目标奖励 25 单列。七核十五兵存活，探索 176→220；进程 105.195 秒、退出 0。未改变资源分布、价格、产速或敌人强度来凑结果。

## 2026-09-14 — Story campaign scope confirmation / 剧情战役范围确认

- The user selected independent mission maps and confirmed a Chapter 1 target of 4–6 hours of active play, approximately 4–6 play days at one hour daily. This replaces the earlier fast-clear/three-day-postgame pacing target; it is a design budget, not a tested player completion time or a mandatory calendar wait.
- Persistent main-nest growth, mission-earned construction materials, and story/challenge unlocks become the new chapter direction while retaining existing RTS controls. Six regular missions and three nest challenges remain a candidate budget, not a fixed or implemented content list.
- Added `CHAPTER1_STORY_CAMPAIGN.zh-CN.md` with phased implementation and eight acceptance gates covering isolated world snapshots, in-mission saves, all return paths, exactly-once rewards/upgrades, bounded offline accounting and legacy-save compatibility. Remaining decisions are explicitly marked rather than inferred from acceptance of the pacing proposal.
- No gameplay code, prices, saves, release assets or Windows installation changed in this planning update. The previous 76-test result belongs to the old technical baseline; it is not certification of the new campaign. No Git push was performed by this entry.

- 用户确认独立任务地图，以及第一章主动游玩 4–6 小时、每天约一小时对应 4–6 天的时间目标；旧“快首通＋通关后约三天经营”改为历史基线，不再作为当前内容目标。
- 更新主计划与旧收尾审计的范围提示，新增剧情战役文档。先实现主巢→独立任务→返回结算→主巢升级的一个闭环，再扩充剧情与全部地图。
- 本次仅修改计划文档，没有修改当前游戏或本地测试包；任务编队/科技继承、任务中主巢结算、失败代价、主巢失活与旧档身份迁移均保留为待明确规则。

## 2026-09-14 — First persistent-nest mission loop / 首个主巢独立任务闭环

- Implemented a persistent nest ledger, an independent fixed-supply mission, victory/retreat/failure return, exactly-once first-win materials, and one nest upgrade with a short story/locked next-challenge preview. This is one playable loop, not the complete 4–6-hour campaign.
- Added seven-language campaign UI, the J shortcut, fractional uptake progress, safe modal handling, scrolling small-window text and existing pixel sound cues. Main-nest identity migrates to a living core without reviving dead cores or changing the all-cores-dead failure rule.
- World snapshots now preserve complete resource/hotspot catalogs, random-generator state and simulation clocks, with atomic home/mission/reward persistence. Active missions pause offline; the home settles the departure interval once, capped at 48 hours. Failed departure, reward settlement or upgrade writes roll back their live state.
- Added structural snapshot validation before destructive restore, backup recovery for damaged nested worlds, and valid pursuit-target restoration. Repaired inactive founder state loss, task-triggered legacy chapter inference and carried-over discovery markers.
- A paid, ordinary-resource route reached the first mission at 845.750 simulated seconds after spending 37 organic on three extensions. Uptake was 360.087 organic / 96.090 mineral and living mature hyphae 792.947 world units. This fixed script is reachability evidence, not average player timing.
- Windows actual OpenGL rendering produced 33 screenshots with isolated test saves and no stderr, including real 640×360 viewport checks. Fixtures are explicitly not economic evidence. See `CHAPTER1_CAMPAIGN_LOOP_QA.zh-CN.md` for scope, procedures and remaining work.
- 已实现一个主巢—出征—返回—升级闭环；七语、旧档兼容、48 小时主巢离线和任务离线暂停同步接入。下一任务仍为预告，不把旧版首通或此次截图等同于完整剧情战役完成。
- Final full-server verification passed resource import, all 81 smoke tests and headless startup in 262 seconds: `/home/ubuntu/fungi/test-logs/20260913T180431Z-2943894/summary.txt`. Existing timing gates were retained. The portable split EXE/PCK archive passed exact-layout validation; SHA-256: `ab6e4855aac15b2a3605ce091151691b3c3ae611c8d5a5455910f7a1c1b04a0d`.

## 2026-09-14 — Real independent world scenes / 主巢与任务独立场景

- Replaced the first loop's shared-world map switch with two actual PackedScenes, `HomeNest.tscn` and `FirstSupply.tscn`, under a common passive WorldHost. Each scene owns a distinct world runtime; shared controls, simulation algorithms and rendering bind to the active runtime. Only one world is attached after a completed transition.
- Moved nest generation and first-mission spawn, resource clusters, starting supplies and objective evaluation into scene-owned definitions. No second mission, balance change, new timer or extra story content was added. The first mission retains the exact paid-route outcome: 845.750 simulated seconds, 37 organic paid, 360.087 / 96.090 uptake and 792.947 living world-length units.
- Added whitelist scene IDs/revisions to world snapshots and legacy inference for metadata-free saves. Loading does not reinitialize a colony or replenish resource catalogs. Departure/return failures preserve the original live scene and runtime; committed transitions release the previous scene. Mission offline pause and once-only, 48-hour home settlement remain unchanged.
- New scene lifecycle regression passes 57 assertions, alongside the existing 121-check campaign flow and 35-check campaign-save regressions. Independent agents reviewed runtime proxy coverage, passive scene ownership, rollback and scene export inclusion. Windows real OpenGL produced 33 captures with empty stderr; five representative images were visually inspected. These fixtures do not prove normal-route economics or human input quality.
- Final server verification passed resource import, 82/82 smoke tests and headless startup in 318 seconds without relaxing gates: `/home/ubuntu/fungi/test-logs/20260913T192634Z-3421526/summary.txt`. The prior full paid victory route retains its simulated timing and final economy/biomass, finishing in 65.741 wall-clock seconds under the existing 120-second limit; this is not a claim of unchanged worst-case frame time.
- Split EXE/PCK archive exact-layout validation passed. SHA-256: `e29400b3edb0114a88223956b1a0deb9107d55d81c6a60a6e6fc09596162a907`. Delivery target remains the sole `C:\Users\jiang\Documents\战舰\fungi-test\FungiMicroculture.exe`; its `build-info.json` records the installed commit/hash after the local isolated-startup gate and managed-file replacement.

- 本次补上真正独立的主巢和首任务场景，不把不同地图数据当作全部场景拆分已完成。每个世界有独立实体、统计和随机状态，任务配置实际驱动地图与目标；公共输入、模拟和绘制继续复用。
- 已验证旧档、任务离线暂停、存读档不刷新世界，以及写盘失败保留原场景实例。首个任务玩法和数值不变；下一任务仍未制作，完整 4–6 小时剧情战役没有完成。
- 详细结构、测试范围与剩余边界见 `CHAPTER1_INDEPENDENT_SCENES.zh-CN.md`。本次不推送 Git。

## 2026-09-17 — Server retirement backup / 服务器到期归档

- The user requested that both repositories be pushed and this server's fungi project files removed only after backup. The latest gameplay commit remains `9547157`; no new mission or gameplay change is made by this archival update.
- Added `SERVER_RETIREMENT_2026-09-17.zh-CN.md` with the exact development branch, current scope, restoration procedure and deletion boundaries. The default source `main` remains an old archive; current development is on `codex/fungi-next`.
- Audited original art/audio against the private asset repository: all production assets were already retained. A content-addressed private recovery archive records 3,033 original paths with 724 new objects (6,391,858 bytes), including 44 unique unarchived QA PNGs, logs, historical drafts and server-only project saves. Existing identical contents are referenced rather than uploaded twice. Credential-pattern checks and all 3,033 recovery references passed locally before pushing.
- Cleanup is gated on both successful pushes, matching remote refs, fresh network clones, Git object integrity and the full recovery-manifest verification. Preserve SSH/Tailscale, shared Godot configuration and all other projects. This log records the archival plan and pre-push evidence, not a premature claim that deletion has already occurred.

- 用户明确要求双库备份后清理旧服务器 fungi；本轮只归档，不改玩法。源码、素材和关键文件哈希已核对，补存未归档资料时按内容去重，服务器存档仅进入私有库。
- 恢复时使用源码 `codex/fungi-next`、素材 `main`，以及两库的同名 `server-retirement-2026-09-17-verified` 标签。本机测试版和存档不在清理范围内。
- Fresh remote-clone validation caught 569 recovery `.log` objects excluded by the asset repository's existing ignore rule. Cleanup was blocked. Added an archive-scoped ignore exception and a tracked-object assertion to the verifier; preserve the original upload checkpoint and use the new `-verified` tag only after full network-retrieval checks pass. No server data was deleted during this failed verification.
- 远端重取验证发现首次上传漏了被既有忽略规则挡住的 569 份日志对象，清理立即停止；新增只针对本次归档的例外规则，并要求清单对象必须确实被 Git 跟踪。初次标签保留历史，完整恢复使用后续经验证标签。

## 2026-10-01 — Restore on a new server / 新服务器恢复与接续

- Restored the verified source and private-art checkpoints with full Git history. Both verified retirement tags and Git object checks match; the recovery manifest validates all 3,033 references / 761 unique objects. Archived runtime saves remain private and were not activated as player data.
- Reinstalled the original Godot 4.7 engine and only the required Windows x64 / Web export templates under the fungi server directory, after official SHA-512 verification. No shared service, GPU driver or other project was changed. The private repository was transferred through an authenticated local Git bundle, without persisting a GitHub token on the server.
- A focused continuation fixes stale campaign save-error notices after successful nest-upgrade or F5-save retries. The regression checks the live panel before reload, and preserves unrelated notices. No campaign objective, balance parameter, reward or second mission is introduced.
- 新机已恢复源码与私有素材完整历史，3,033 项备份引用全部核验；存档没有自动启用或覆盖。环境恢复与有界修复的验证结果见 [本轮恢复记录](SERVER_RESTORE_2026-10-01.zh-CN.md)。完整剧情战役仍未完成，下一独立任务先提交设计审阅。
- Baseline verification passed 82/82 smoke tests in 322 seconds. The new regression first reproduced the stale-notice failure, then passed 66 focused assertions after the fix. Final verification passed resource import, 82/82 tests and headless startup in 329 seconds without relaxing timeouts; log: `/home/ubuntu/fungi/test-logs/20260930T202716Z-48528/summary.txt`.
- New-server Windows split export and exact ZIP layout validation passed. The extracted EXE loaded the adjacent PCK for 60 headless frames on Windows with isolated application data; this is not human visual/input QA. Package SHA-256: `2dbe4367d51631b7471f4f8a579b45f7d2788fdf75f76e0eb1820819c6a20e70`. The sole local delivery target remains `fungi-test/FungiMicroculture.exe`; its installer records the final source commit.
