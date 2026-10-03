# Server Verification Index / 服务器测试记录索引

## Latest: 2026-10-04 Chapter 1 / 最新第一章验证

- Full suite: **95/95 PASS**, resource import PASS, main-scene startup PASS, **497 s**. Run started at 2026-10-03 21:32:58 UTC against the chapter working tree based on `fdd1ba1ccfd2`; summary: `/home/ubuntu/fungi/test-logs/20261003T213258Z-271124/summary.txt`.
- Render probe: **645 captures**, nine missions, seven languages, 1280×720 and 640×360, PASS. Evidence: `/home/ubuntu/fungi/test-logs/campaign-visual-20261003T213310Z-271531/`. No human visual/input/audio acceptance is implied.
- Snapshot integrity: the full-suite snapshot had 97 checks; the final focused expansion passed **109**, including real backup recovery and rejection of missing mission entities. Product code was unchanged. Logs: `/home/ubuntu/fungi/test-logs/chapter1-focused-20261004/`.
- Windows artifact: split EXE/PCK, exact three-file ZIP, CRC, x64 PE and all 137 PCK entry digests PASS; **no Windows runtime test this turn**. Evidence: `/home/ubuntu/fungi/test-logs/windows-chapter1-20261003T213257Z-271074/`.
- Sole candidate: `/home/ubuntu/fungi/game/release/FungiMicroculture-Windows-x64.zip`, 44,108,704 bytes; SHA-256 `97c9f3c675621f4de3f0d7aac834f3720d1effcb67a235da9d4c33f4dbb7068d`.
- Below are historical verification records, not the current test count. New implementation details and the unmeasured human-playtime boundary are recorded in `DEVELOPMENT_LOG.md` and `CHAPTER1_APPROVED_MISSIONS.zh-CN.md`.

Godot version used by the archived server: `4.7.stable.official.5b4e0cb0f`.

The full transient logs were stored outside the repository under `/home/ubuntu/fungi/test-logs/`. This file preserves the meaningful run summaries before server retirement; caches and verbose per-test logs are intentionally excluded from Git.

完整临时日志位于仓库外的 `/home/ubuntu/fungi/test-logs/`。服务器到期前仅归档具有长期价值的汇总；缓存及冗长的逐测试输出不进入 Git。

| UTC run | Result | Smoke tests | Import | Main scene | Notes |
|---|---:|---:|---:|---:|---|
| 2026-08-05 16:31 | PASS | 52/52 | PASS | PASS | First isolated server-test baseline |
| 2026-08-05 17:59 | PASS | 53/53 | PASS | PASS | Expanded save/developer coverage |
| 2026-08-05 20:02 | FAIL | 53/54 | PASS | PASS | Intermediate development failure retained for history |
| 2026-08-05 20:04 | PASS | 54/54 | PASS | PASS | Failure corrected |
| 2026-08-06 03:15 | FAIL | 47/54 | PASS | PASS | Sprite/scale work in progress |
| 2026-08-06 03:41 | FAIL | 51/55 | PASS | PASS | Intermediate sprite integration |
| 2026-08-06 03:49 | FAIL | 54/55 | PASS | PASS | One remaining regression |
| 2026-08-06 04:04 | FAIL | 54/55 | PASS | PASS | Final iteration before green run |
| 2026-08-06 04:08 | PASS | 55/55 | PASS | PASS | Initial sprite integration green |
| 2026-08-06 09:52 | FAIL | 56/57 | PASS | PASS | Founder/save work in progress |
| 2026-08-06 09:59 | PASS | 57/57 | PASS | PASS | Founder/save regression corrected |
| 2026-08-06 13:22 | PASS | 58/58 | PASS | PASS | Balance and feeder bandwidth coverage |
| 2026-08-06 13:25 | PASS | 58/58 | PASS | PASS | Confirmation run |
| 2026-08-06 14:17 | FAIL | 57/58 | PASS | PASS | Late interaction regression found |
| 2026-08-06 14:20 | PASS | 58/58 | PASS | PASS | Interaction regression corrected |
| 2026-08-11 09:44 | PASS | 59/59 | PASS | PASS | Extension cancellation coverage |
| 2026-08-11 10:23 | PASS | 60/60 | PASS | PASS | Core/unit LOD integration |
| 2026-08-11 10:56 | PASS | 60/60 | PASS | PASS | Minimum-zoom hunt-zone fix; 104 s |
| 2026-08-25 11:10 | PASS | 60/60 | PASS | PASS | Restored-server clean baseline on `codex/fungi-next`; 108 s |
| 2026-08-27 20:51 | PASS | 60/60 | PASS | PASS | Portable split-package working tree; 107 s |

## Authoritative pre-archive verification / 归档前权威验证

- UTC run: `2026-08-22T063737Z-2351945`
- Result: `PASS`
- Resource import: `PASS`
- Smoke tests: `60/60 passed`
- Main scene startup: `PASS`
- Godot: `4.7.stable.official.5b4e0cb0f`
- Elapsed time: `119 seconds`
- Original server summary: `/home/ubuntu/fungi/test-logs/20260822T063737Z-2351945/summary.txt`

This verification ran against the complete archive working tree immediately before staging and commit.

本次验证在暂存和提交前针对完整归档工作树执行。

## Restored-server authoritative baseline / 恢复服务器权威基线

- UTC run: `2026-08-25T111050Z-156189`
- Result: `PASS`
- Source commit: `6c8886dd346c`
- Dirty entries: `0`
- Resource import: `PASS`
- Smoke tests: `60/60 passed`
- Main scene startup: `PASS`
- Godot: `4.7.stable.official.5b4e0cb0f`
- Elapsed time: `108 seconds`
- Summary: `/home/ubuntu/fungi/test-logs/20260825T111050Z-156189/summary.txt`

This is the first authoritative run from the restored server and the isolated
`codex/fungi-next` worktree.

这是恢复服务器后、从隔离 `codex/fungi-next` 工作树执行的第一份权威基线。

## Windows portable-package gates / Windows 便携包门禁

The Windows release workflow now has two Linux artifact checks plus a Windows runtime gate in addition to the game suite:

- `tools/windows_split_export_smoke.sh` runs the Godot Windows exporter and requires non-empty `FungiMicroculture.exe` and `FungiMicroculture.pck` outputs.
- `tools/windows_portable_bundle_smoke.sh` runs the release packager and requires exactly `FungiMicroculture.exe`, `FungiMicroculture.pck` and `README-FIRST.txt` at the ZIP root.
- `tools/windows_portable_runtime_smoke.ps1` extracts the finished ZIP and launches its EXE with the adjacent PCK. Its fixture-based gate self-test passed on Windows on 2026-08-28; the actual candidate result must be recorded separately when a Windows build is tested.

除游戏测试套件外，Windows 发行流程现在还包含两项 Linux 产物检查和一项 Windows 运行门禁：

- `tools/windows_split_export_smoke.sh` 实际调用 Godot Windows 导出器，并要求生成非空的 EXE 与 PCK。
- `tools/windows_portable_bundle_smoke.sh` 实际调用发行打包脚本，并要求 ZIP 根目录准确包含 EXE、PCK 与 `README-FIRST.txt`。
- `tools/windows_portable_runtime_smoke.ps1` 会解压最终 ZIP，并启动使用同目录 PCK 的 EXE。门禁自身已于 2026-08-28 在 Windows 上使用临时测试程序通过；实际候选包的结果须在 Windows 测试后另行记录。
