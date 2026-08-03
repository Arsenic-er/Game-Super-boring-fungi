[**English**](docs/i18n/README.en.md) | [简体中文](docs/i18n/README.zh-Hans.md) | [繁體中文](docs/i18n/README.zh-Hant.md) | [日本語](docs/i18n/README.ja.md) | [Español](docs/i18n/README.es.md) | [Deutsch](docs/i18n/README.de.md) | [Русский](docs/i18n/README.ru.md)

![Game: Super boring fungi](assets/branding/repo-hero.png)

# Game: Super boring fungi

An idle evolution and expansion game about growing from a microscopic spore into a force capable of reshaping ecosystems, societies, nations, and eventually the planet.

The project is currently an early Windows prototype. Version `0.44.0` focuses on Chapter 1: a top-down laboratory microculture where the player controls only the fungus, grows a mycelial network, collects nutrients, evolves new abilities, and commands mobile expedition spores.

## Languages

The main menu, settings, pause/session screens, and repository introduction support English, Simplified Chinese, Traditional Chinese, Japanese, Spanish, German, and Russian. Choose the interface language in Settings. Use the links above to read the complete localized introduction.

## Recent command and localization updates

- v0.39 introduced role-safe expedition commands: only compatible units attack or gather from a target, incompatible members of mixed selections fall back to a nearby hold position, `C` clears orders and restores automatic behavior, and command receipts report exact results.
- v0.40 adds the seven-language menu flow and localized session interface, together with matching repository documentation for every supported language.
- v0.41 shows the seven-language selector on the first launch of a new installation and provides Simplified Chinese, Traditional Chinese, English, Japanese, Spanish, German, and Russian text for the resource HUD, core radial actions, core status and common hover tooltips, expedition status, bacterial descriptions, and all ten unit names; the upgrade shop and full long-term-goal descriptions are not yet fully localized.
- v0.42 localizes all 22 long-term goals, the evolution-shop shell, node and survival upgrades, structure upgrades, the general barracks page, the lower barracks status panel, and detailed text for three specialist units in all seven languages. Diet detail pages, bacterial components, diet-exclusive unit pages, purchase and barracks interaction toasts, and chapter guidance, ecology-event, and Rival Sporefall text remain for later localization.
- v0.43 adds a six-page illustrated gameplay guide to the Esc pause menu. It explains germination, nutrients and DNA, evolution, barracks commands, exploration and goals, and colony survival in all seven interface languages, with a dedicated coarse-pixel image beside every topic.
- v0.44 completes seven-language diet detail, bacterial-component and diet-specialist pages, and localizes evolution purchases, unlocks and failure feedback. Long labels now scale inside their pixel UI controls, including Spanish, German and Russian.

## Download and play

Open the repository's [latest Release](../../releases/latest), download the Windows ZIP, extract it, and double-click `FungiMicroculture.exe`.

- Platform: Windows 10/11, 64-bit
- Installation: none; the game data is embedded in the executable
- Save data: stored separately in the current Windows user's application-data directory
- Windows may show a SmartScreen warning because this hobby build is not code-signed

## Current playable features

- A large, zoomable laboratory culture with clustered organic nutrients, mineral ions, water motes, and stationary bacterial colonies.
- One spore core that grows primary hyphae and fine absorbing hyphae, with slow fractional nutrient uptake suitable for idle play.
- DNA production, reversible evolution choices, structure upgrades, survival upgrades, diet paths, and long-term goals with different rewards. Core DNA production supports atomic batches of 1, 5, or 10 with live quantity, duration, and nutrient-cost tooltips.
- Core biomass, toxin pressure, gradual recovery, dying orphaned hyphae, and network rescue by another living core.
- Barracks cores and several expedition-spore roles for gathering, transport, mineral collection, and bacteria-focused combat.
- Bacteria-diet progression now unlocks reusable suppressor pods: right-click a position to move, unfold for four seconds, and establish a 70 μm front-line zone that reduces bacterial absorption and division speed to 30%.
- Bacteria-diet progression also unlocks ranged lytic dispersers: they hold position 36 μm from a bacterial target, release a 30 μm area burst every six seconds, and carry part of the lysed biomass back to the colony.
- Local bacterial blooms can now be solved without killing every target: keep all but three event bacteria inside suppressor zones for twelve uninterrupted seconds, then claim the new specialist objective reward.
- Persistent fog of war on both the culture view and minimap, plus fast scout spores that automatically reveal hidden resource regions.
- Permanent anomaly discoveries, exploration notifications, expedition supply and suppression goals, and independent scout vision and movement upgrades.
- Telegraphing bacterial ecology events: contain a local bloom with predation or expedition spores, or survive a temporary toxin zone with antibiotics, detoxification, and repair reserves.
- A fog-hidden rival fungus that consumes real organic resources, slowly extends its own hyphae, and damages player cores after physical contact.
- Rival colonies now spend real organic reserves to hatch mobile guard spores. They patrol the enemy hyphal network, pursue nearby expedition spores, disengage beyond their leash, accept direct right-click focus-fire orders, and slowly decay when their parent core dies.
- Selected foragers and fungi-specialist piercers can now receive a persistent square defense zone. They patrol within it, prioritize hostile guards before rival cores, abandon targets that leave the boundary, and resume the saved patrol after returning or repairing.
- Foragers, carriers, and chelators can receive persistent square harvesting zones. They split compatible resource targets, keep searching after a point is depleted, unload full cargo, recover from low biomass, and automatically resume the saved gathering route; harvesting continues during capped offline progress.
- With the bacteria diet active, foragers, lytic spores, and lytic dispersers can receive persistent square purge zones. Single-target hunters split claims, dispersers prefer dense clusters, and every eligible unit resumes the hunt after unloading or repair; offline purging respects the existing ten-minute combat cap and ignores temporary event strains.
- Each barracks can store one persistent defense, harvesting, or purge directive for its current replenishment role. Matching active units are reassigned immediately, automatic replacements inherit the square mission on birth, and manual production remains free for direct control; directives are isolated per barracks and persist through saves and offline progress.
- One long-term goal can now stay pinned to the HUD with a live progress bar and reward tooltip. Clicking it opens the correct goals page; completed goals wait for manual claiming, then recommend the next unclaimed objective. Saving a first barracks directive also completes a new automation teaching goal.
- Fungi-diet progression now unlocks piercer spores for attacking rival cores, plus a dedicated rival-colony objective and reward.
- Fungi-diet progression also unlocks coil hunters: order them onto individual enemy hyphae to sever supply lines, make dependent branches fade over 90 seconds, and earn the new severing objective while the rival regrows from its surviving network.
- Fungi-diet progression now adds reusable antifungal pods: unfold a 75 μm lockdown field to reduce rival nutrient absorption and regrowth to 35%, double the decay of severed hyphae, and complete a dedicated containment objective without dealing direct damage.
- A nine-step, non-blocking Chapter 1 guidance chain now connects core awakening, germination, absorption, DNA, colony growth, diet evolution, barracks, exploration, and rival clearance, ending in a persistent culture report.
- Fog-safe rival-hypha warnings appear only for explored threats; basic foragers retain a very slow manual anti-fungus fallback while fungi-specialist piercers remain dramatically stronger.
- A complete culture-session flow: true simulation pause, save-now and settings controls, save-and-return, separate continue/new-culture entries, overwrite confirmation, and recoverable game-over actions.
- Barracks production queues, per-barracks rally points, resource-aware automatic replenishment, and unit-type selection filters.
- Expedition spores now have role-specific fractional biomass, counterattack and toxin damage, automatic low-biomass retreat, slow free barracks repair, death, and replenishment. Live bacteria release a small defensive toxin while being consumed; their tooltip now explains this biomass loss.
- After the first rival is cleared, recurring Rival Sporefall cycles add long idle cooldowns, visible landing warnings, progressively stronger young colonies, and repeatable recovery rewards.
- RTS-style unit selection with a rectangular drag box, right-click orders, green command lines, accelerated testing speeds, and autosave.
- Role-safe expedition orders prevent incompatible units from attacking or gathering the wrong target; mixed selections fall back to a nearby hold position, and `C` restores healthy units to role-appropriate automation.
- Up to two hours of resource-faithful offline progress; expedition combat is capped at ten minutes and toxin exposure at one minute, with offline replenishment and a detailed return report.
- Pixel-art splash screen, main menu, save loading, fullscreen/window settings, and an optional green pixel cursor.
- A six-page, seven-language gameplay guide in the Esc pause menu, with topic-specific coarse-pixel illustrations and mouse or keyboard page navigation.
- An original procedural “pixel laboratory nebula” soundscape with interaction, growth, nutrient, DNA, RTS, combat, warning, and looping ambient cues; five independently adjustable audio channels remain rate-limited during accelerated play.

## Controls

- Core DNA button: click for 1, hold Shift and click for 5, or hold Ctrl and click for 10; the hover tooltip updates before clicking
- Left click: inspect a core, choose actions, or select expedition spores
- Top unit filters: select all units or all units of one unlocked role
- Left drag: rectangular unit selection
- Right click: issue movement, gathering, combat, hypha-severing, or deployable-zone orders
- `Z` or the defense button: enter defense mode, then right-drag a square patrol zone
- `X` or the harvest button: enter harvesting mode, then right-drag a square resource zone
- `V` or the purge button: enter purge mode, then right-drag a square bacteria-hunting zone
- Barracks status panel: choose a defense, harvesting, or purge directive, then right-drag its square; use Clear Task to remove the template
- Goals panel: use Track / Cancel Tracking on a goal card; click the HUD tracker to reopen that goal's page
- `C` or the clear-order button: remove the selected units' persistent defense, harvesting, or purge zones
- `R`: return selected expedition spores to their barracks
- Right drag / middle drag: move the camera
- Mouse wheel: zoom
- `WASD` / arrow keys: move the camera
- `E`: evolution shop
- `G`: long-term goals
- `F5`: save immediately
- `Esc`: close the current panel, cancel an action, or pause/resume; choose Gameplay guide in the pause menu, then use ←/→ to turn pages

## Planned scale progression

The current microculture is only the opening scale. Future independent chapters are intended to move through microorganisms and cells, small organisms and objects, ecosystems, human society, cities, countries, and the modern Earth. Traits evolved at earlier scales are intended to influence later spreading and conquest strategies.

## Development

The project uses Godot `4.7` with GDScript. Open `project.godot` in Godot to run the source project. Automated smoke tests live in `tests/`; the Windows export preset embeds the PCK into one executable.

## Rights

Copyright © 2026 koko. All rights reserved.

The source code, visual assets, game design, text, and other repository contents are publicly viewable but are **not licensed for reuse, modification, redistribution, derivative works, or commercial use**. The official compiled release may only be downloaded and run for personal play and evaluation. See [LICENSE](LICENSE).

---

# 《超级无聊真菌游戏》

[English](docs/i18n/README.en.md) | [**简体中文**](docs/i18n/README.zh-Hans.md) | [繁體中文](docs/i18n/README.zh-Hant.md) | [日本語](docs/i18n/README.ja.md) | [Español](docs/i18n/README.es.md) | [Deutsch](docs/i18n/README.de.md) | [Русский](docs/i18n/README.ru.md)

这是一款从微观孢子出发、逐步扩张至生态系统、人类社会、国家乃至整个地球的放置演化与征服游戏。

项目目前是 Windows 早期原型，版本为 `0.44.0`。现阶段集中制作第一章：玩家在俯视角实验室微观培养环境中只控制真菌，扩张菌丝网络、收集营养、进化能力，并指挥可离开母体活动的游猎孢子。

## 语言支持

主菜单、设置、暂停/会话界面与仓库介绍支持英语、简体中文、繁体中文、日语、西班牙语、德语和俄语。可在“设置”中选择界面语言；使用上方链接可阅读对应语言的完整介绍。

## 近期指令与本地化更新

- v0.39 加入职责安全的远征指令：只有相容单位会攻击或采集目标，混编选择中的不相容单位会移动到附近原地警戒，`C` 会清除指令并恢复自动行为，指令回执会显示准确执行结果。
- v0.40 加入七语言菜单流程与本地化会话界面，并为每种支持语言提供对应的仓库介绍。
- v0.41 在全新安装首次启动时显示七语选择，并为资源 HUD、核心径向动作、核心状态与常用悬停提示、远征状态、细菌说明及 10 种兵种名称提供简体中文、繁体中文、英语、日语、西班牙语、德语与俄语；升级商店和长期目标正文尚未完成全量翻译。
- v0.42 已将全部 22 个长期目标、进化商店外壳、节点与生存升级、结构升级、通用兵营页、兵营状态面板下半区，以及三种特种兵的详细说明扩展为七语。食性详情、细菌组件、食性专属单位页面、购买提示、兵营交互提示，以及章节引导、生态事件和竞争孢子雨文案仍待后续本地化。
- v0.43 在 Esc 暂停菜单中加入六页带插图的玩法指引，以七种界面语言说明萌发菌丝、营养与 DNA、进化、兵营指挥、探索目标和菌落生存；每个主题旁都有独立的粗像素插图。
- v0.44 完成食性详情、细菌组件与食性专属兵种页面的七语化，并翻译进化购买、解锁及失败反馈；西班牙语、德语和俄语等较长文字现在也会在像素 UI 控件内自适应缩放。

## 下载与运行

进入仓库的[最新 Release](../../releases/latest)，下载 Windows ZIP，解压后双击 `FungiMicroculture.exe` 即可运行。

- 平台：Windows 10/11 64 位
- 安装：无需安装，游戏数据已内嵌进 EXE
- 存档：单独保存在当前 Windows 用户的应用数据目录
- 因个人项目暂未进行代码签名，Windows 可能显示 SmartScreen 提示

## 当前可玩内容

- 可大范围缩放的实验室培养环境，包含聚集分布的有机营养、矿物离子、水分像素和静止细菌群落。
- 从一个孢子核心开始，延伸主菌丝并自动长出细吸收菌丝，以适合放置游戏的缓慢小数速率获取营养。
- DNA 生产、可逆进化、结构升级、生存升级、食性路线，以及奖励各不相同的长期目标；核心 DNA 支持一次生产 1、5 或 10 点，悬停说明会实时换算数量、总时间与营养成本。
- 核心生物量、毒素压力、缓慢恢复、孤立菌丝死亡，以及其他活核心重新连接后的网络救援。
- 兵营核心与多种游猎孢子，分别负责采集、运输、矿物收集和针对细菌的战斗。
- 细菌食性新增可重复部署的“抑菌囊体”：右键指定阵地、展开4秒后建立半径70 μm的前沿抑菌区，把范围内细菌的吸收和分裂速度压至30%。
- 细菌食性新增远程“溶菌散播体”：它会在细菌目标外36 μm保持距离，每6秒释放一次半径30 μm的范围裂解，并把部分裂解生物量运回菌落。
- 局部细菌暴发新增非击杀解法：让除最多3个以外的事件细菌连续12秒处于部署区内，即可完成静菌封锁并领取专属长期目标奖励。
- 可视化兵营生产队列、每座兵营独立集结点、遵守营养消耗的自动补员，以及按兵种快速筛选部队。
- 体外孢子现在具有按兵种区分的三位小数生物量、反击与毒素伤害、低生物量自动撤退、兵营缓慢免费修复、失活和自动补员闭环。活细菌在被摄食时会释放少量防御毒素，细菌悬停说明会明确提示这项生物量损失。
- 清除初始竞争菌落后会开启可重复的“竞争孢子雨”：经过长时间冷却和可定位的落点预警后生成逐轮增强的幼体菌落，击退后获得重复奖励。
- 大地图与小地图使用永久探索黑幕；高速嗅营孢子会自动寻找未探索区域并揭示资源热点。
- 异常资源区会触发永久发现记录与提示；新增远征补给、细菌压制目标，以及独立的嗅营感知和运动升级。
- 带预警的细菌生态事件：通过捕食和体外部队压制局部暴发，或利用抗生素、解毒代谢和修复储备熬过临时毒素区。
- 隐藏在探索黑幕后的竞争性真菌会消耗地图真实有机营养、缓慢延伸自己的菌丝，并在接触后侵染我方核心。
- 竞争菌落现在会消耗真实有机储备孵化移动守卫孢子：它们沿敌方菌丝巡逻、追击附近的我方远征孢子、超出警戒范围后脱战返回；玩家可以右键集火，母体核心死亡后守卫会缓慢衰亡。
- 已选中的游猎孢子和真菌专属穿壁孢子现在可以设置持久正方形防区：单位在区内巡逻、优先拦截敌方守卫再攻击竞争核心；目标越界后立即脱战，返巢修复后仍会继续执行已保存的防区任务。
- 游猎孢子、囊载孢子和螯合孢子可以设置持久正方形采区：单位会分流适合自身食性的资源点，采空后继续搜索，满载卸货或低生物量修复后自动恢复任务；在离线结算上限内也会继续执行真实资源采集。
- 开启细菌食性后，游猎孢子、裂菌孢子和溶菌散播体可以设置持久正方形清剿区：单体猎手会分流目标，远程散播体优先攻击密集菌群，卸货或修复后自动恢复任务；离线清剿遵守现有十分钟战斗上限，并避开临时生态事件菌株。
- 每座兵营现在可以为当前补员兵种保存一个持久防区、采区或猎区任务：同兵营同兵种的现役单位会立即重新编制，自动补员出生时自动接班，手动生产的单位仍保持自由；任务按兵营隔离，并支持存档与离线结算。
- 长期目标现在可以固定显示在 HUD 上，实时展示进度条与奖励提示；点击追踪条会直接打开目标所在页面，达成后仍需手动领取，并自动推荐下一个未领取目标。第一次为兵营保存持续任务还会完成新的自动编制教学目标。
- 真菌食性现在可以解锁穿壁孢子，用于攻击竞争菌落核心，并配有独立长期目标与奖励。
- 真菌食性还可解锁“缠丝猎手”：把它右键指派到一段敌方菌丝后可切断供给线，使依赖该段的远端分支在90秒内逐渐暗淡、失活；竞争菌仍会从幸存网络重新生长，并新增“断丝战术”目标。
- 真菌食性新增可重复部署的“抗真菌囊体”：展开半径75 μm的封锁区，把竞争真菌的营养吸收和再扩张压至35%，令已切断菌丝以两倍速度衰败；封锁区不直接造成伤害，并配有独立长期目标。
- 新增九步、非强制式第一章引导，将唤醒核心、萌发、吸收、DNA、扩建、食性、兵营、探索和清除竞争菌串成完整流程，结束后生成可持久保存的培养报告。
- 竞争菌丝威胁提示只读取已探索区域；基础游猎孢子保留极慢的手动对真菌攻击能力，真菌专属穿壁孢子仍具有显著效率优势。
- 完成培养会话管理闭环：真正冻结模拟的暂停菜单、立即保存与设置、保存返回主菜单、独立的继续/新培养入口、覆盖确认，以及失败后的重新培养和返回操作。
- 类 RTS 的矩形拖框选兵、右键指令和绿色命令线；另有测试加速与自动存档。
- 最多两小时、严格消耗地图真实资源的离线结算；体外单位战斗最多结算十分钟、毒素伤害最多一分钟，期间会执行自动补员，返回后显示详细报告。
- 像素风开屏、主菜单、读取存档、全屏/窗口设置和可关闭的绿色像素鼠标。
- Esc 暂停菜单内置六页七语玩法指引，每个主题配一张独立粗像素插图，并支持鼠标按钮与键盘翻页。
- 新增原创程序化“像素实验室星云”声音系统，覆盖界面交互、菌丝生长、营养吸收、DNA、RTS指令、战斗、警报和循环背景音；总音量、界面、菌落、战斗与背景五路可独立调节，加速时仍会限频。

## 操作方式

- 核心 DNA 按钮：普通点击生产 1 点，按住 Shift 点击生产 5 点，按住 Ctrl 点击生产 10 点；点击前悬停说明会实时更新
- 左键：查看核心、选择操作或选中游猎孢子
- 顶部兵种筛选：选中全部单位或某一已解锁兵种
- 左键拖动：矩形框选部队
- 右键：下达移动、采集、战斗、切断敌方菌丝或部署区域囊体的命令
- `Z` 或“设防”按钮：进入设防模式，再按住右键拖出正方形巡逻区
- `X` 或“采区”按钮：进入采集模式，再按住右键拖出正方形资源区
- `V` 或“猎区”按钮：进入清剿模式，再按住右键拖出正方形细菌猎区
- 兵营状态面板：选择持续防区、采区或猎区，再按住右键拖出正方形；“清任务”会移除兵营模板
- `C` 或“清令”按钮：移除所选单位的持久防区、采区或猎区
- `R`：让已选中的体外孢子返回所属兵营
- 右键拖动 / 中键拖动：移动镜头
- 鼠标滚轮：缩放
- `WASD` / 方向键：移动镜头
- `E`：进化商店
- `G`：长期目标
- 目标面板：点击目标卡片上的“追踪 / 取消追踪”；点击 HUD 追踪条可返回对应目标页面
- `F5`：立即保存
- `Esc`：关闭当前面板、取消操作或暂停/继续；暂停菜单中可进入“玩法指引”，再用 ←/→ 翻页

## 计划中的尺度阶段

当前微观培养只是游戏的起点。未来计划以独立章节依次扩展到微生物与细胞、小型生物与物品、生态系统、人类社会、城市、国家和现代地球。较小尺度进化出的生理特征将影响后续阶段的传播与征服策略。

## 开发

项目使用 Godot `4.7` 与 GDScript。使用 Godot 打开 `project.godot` 即可运行源码；自动化冒烟测试位于 `tests/`，Windows 导出设置会将 PCK 内嵌为单一 EXE。

## 权利声明

版权所有 © 2026 koko，保留所有权利。

本仓库的源码、视觉素材、游戏设计、文字及其他内容虽然公开可查看，但**不授权他人复用、修改、重新发布、制作衍生作品或用于商业用途**。官方编译版本仅允许下载后用于个人游玩与评估。详情见 [LICENSE](LICENSE)。
