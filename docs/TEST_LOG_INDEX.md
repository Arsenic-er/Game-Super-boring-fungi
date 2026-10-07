## 2026-10-08 — Direct-entry campaign audit delivery

- Final production source: 7839f54adc572784b90fe6207a561cf84f8f3fd2; clean build chapter1-review-20261007T211921Z-0b73383b62cf.
- Preset ledger/fixture/localization: /home/ubuntu/fungi/test-logs/campaign-audit-presets/presets-smoke.log — 903 checks PASS.
- Initial full isolated suite: /home/ubuntu/fungi/test-logs/20261007T211133Z-697861/summary.txt — import and normal startup PASS; **98/100 tests, 754 seconds, overall FAIL**. The new audit smoke left sentinel normal/developer/settings files in the shared disposable profile; DamagedNetworkSave and DeveloperCampaign correctly rejected them. This was a test-harness cleanup fault, not a production save overwrite. Do not report this run as 100/100.
- Corrected audit smoke restores original bytes/existence on success and failure, deleting only its exact hash-matching created sentinel when originally absent. A fresh shared-profile sequence passed Audit **436**, DamagedNetworkSave **93**, DeveloperCampaign **15,879** checks: /home/ubuntu/fungi/test-logs/audit-runtime-20261007T210540Z/shared-*.log. No second full-suite pass is claimed.
- The initial full-suite scripts/scenes/tests snapshot matched the committed feature product (digest 81630f5708c942d949f10a39a2273e49a7e86d8810f553d27ad79ec595c368b3). Subsequent production change only prevents drawing an uninitialized rejected audit entry; it was covered by the final GL and exported routing gates below.
- Final audit UI/software-OpenGL: /home/ubuntu/fungi/test-logs/campaign-audit-20261007T211901Z-714571/ — **449 checks, 14 captures**, seven languages/two viewports PASS. Render evidence is not human visual acceptance.
- Existing nine review slices: /home/ubuntu/fungi/test-logs/review-layout-20261007T211224Z-700263/ — **2,479 checks, 168 captures** PASS.
- Initial exported invalid-argument probe exposed queued splash drawing with an uninitialized font. Final release route matrix: /home/ubuntu/fungi/test-logs/audit-packed-20261007T211949Z/summary.json — **30/30** (eight checkpoints, nine existing slices, ordinary entry, twelve rejected argument cases); expected exit codes, no SCRIPT ERROR and no profile creation on rejected routes. This executes the actual exported PCK with server Linux Godot, not the Windows EXE.
- Final archive verifier: /home/ubuntu/fungi/test-logs/review-package-20261007T211921Z-715796/ — 36 ZIP members, ten exact ASCII CMD launchers, eight checkpoint IDs, 158 checked PCK entries. Nine negative-archive mutations were rejected by the same verifier.
- Full review archive SHA-256: 918210dd6d9548cf31406469e241b40e12add4e7bd25c14b1057b826e905448a.
- Engine-reuse update: 6,325,747 bytes; SHA-256 54234902228662ee4ae6e41ce73fa92a995d1e4f7044efe7922258cb0bd997b1.
- Ordinary three-file ZIP uses the same final EXE/PCK: SHA-256 1680b83d708154dd7284a83b0dcd5e81201cb545756cc9982e526f6aed55ea0c.
- Local final-artifact update: C:\Users\jiang\Documents\战舰\fungi-test\00 主巢分支审查.cmd. All **35** manifest files verified; one EXE and one adjacent PCK; five existing save/settings JSON files stayed hash-identical. Engine reused with SHA-256 502b441aa251105d53741cd999fce0c52bcb9b21be9e4c17694bd2f5069c3227. No local game/test process was launched and no source/dependencies were downloaded.
- Owned server scratch was removed after verification; retained logs remain on the server. Old policy-blocked local staging was not touched. No Git push or asset-repository mutation was requested/performed. Native Windows interaction and player pacing remain for user review.

# Server Verification Index / 服务器测试记录索引

## Latest: 2026-10-04 Review goals and home return / 切片目标与返巢回归

- Clean candidate `69d09a59f12bb0bc300615add403101b14eb0dc1`, build `chapter1-review-20261004T155304Z-7527feeb7031`. Package/source hash matched; the installed update reused the existing EXE and replaced only PCK, docs and launchers.
- Focused review **1,193 checks PASS**: nine missions × victory/retreat/failure, playable home, paid actions, F8/J/Esc, save/reload, preserved report, failed-write rollback and explicit-reset replay. Standard campaign hint **213 PASS**, paid flow **121 PASS**. Logs and source-match evidence: `/home/ubuntu/fungi/test-logs/review-home-fix-20261004-final/`. The full 97-test suite was not rerun for this review-only change.
- Real-render input probe: **2,479 assertions / 168 captures**, seven languages × two sizes, including first-mission New/Play/J/confirmed mouse retreat/home beyond startup-only coverage. Evidence: `/home/ubuntu/fungi/test-logs/review-layout-20261004T154536Z-406492/`.
- Final Windows artifacts: all nine headless starts and first-mission Intel OpenGL startup PASS; all 34 installed manifest hashes verified. **Seven normal/review save/settings hashes unchanged.** Existing two-audio-object exit warning remains, with no startup error. Logs: `/home/ubuntu/fungi/test-logs/review-home-fix-20261004-final/windows/`.
- Export: 35 ZIP entries, nine native launchers, 148 PCK digests and new helper remaps PASS. Update is 6,240,563 bytes, SHA-256 `b9d25f0c5d3e272bb7eb8ad76e509a5bae476990bc33eeb551688e7bb5d0f4fa`; full ZIP SHA-256 `4a996e61b7421cdfad9930740bb6796f080f3e78422994cd8e62f0c0e2c80f2c`. Logs: `/home/ubuntu/fungi/test-logs/review-package-20261004T155304Z-415054/`.
- Existing local staging/QA paths were reused; no second engine or local development environment. Previously blocked cleanup was not retried or bypassed. Automated checks do not imply human visual/audio or playtime acceptance.

## Latest: 2026-10-04 Windows review delivery / 本机离线审查包交付

- Candidate: clean source `bfbf58e21df45670c30f8a88bc17cb6269ae5524`, build `chapter1-review-20261004T073700Z-797c37a1d547`. Nine CMD entries use release-supported user arguments and internal routing, without PowerShell/COM or scene/path overrides.
- Actual Windows executable: all **9 headless review starts PASS**, invalid mission rejected with exit 2, normal no-argument startup PASS. FirstSupply also started successfully using the actual Intel Iris Xe OpenGL renderer and exited 0. This proves startup, not human gameplay or audio acceptance.
- Windows exit diagnostics retain one AudioStreamWAV and one AudioStreamPlaybackWAV reference warning. No startup error/crash was observed. Normal review Quit has no distinct audio teardown, so this is not claimed to affect only forced quit.
- Five pre-existing normal/developer save/settings SHA-256 values remained unchanged. All 34 manifest file hashes matched the installed one-EXE/one-PCK package; nine Chinese CMD files are present. Runtime evidence (including the superseded --scene failure) is on the server: `/home/ubuntu/fungi/test-logs/review-windows-runtime-20261004/`.
- Full final-source suite: import and main startup PASS, **96/97 tests PASS**, **625 s**. Only performance_smoke failed: 64 purge hunters against 420 bacteria measured 3588.6 ms. Preserve this failure rather than replacing it with an earlier green run. Summary: `/home/ubuntu/fungi/test-logs/20261004T073703Z-368877/summary.txt`. Review-specific assertions: **573 PASS**.
- Full archive: 44,196,117 bytes, SHA-256 `4c18b3b74d978f02279db1c8a8b19d5dad52682552392d3350cf1693cc881c51`. Engine-reuse update: 6,233,473 bytes, SHA-256 `08a82f20163b9329df39affad13f35efa290d52a17a6621fd00358397e69b1da`. Both exact 35-entry layouts and all 144 PCK digests passed. Logs: `/home/ubuntu/fungi/test-logs/review-package-20261004T073700Z-368767/`.
- Only requested final test artifacts were transferred to the existing local fungi-test folder; source/build/dependencies remained on the server. Cleanup of two owned QA directories and the staging ZIP was blocked by execution policy. No alternate deletion method was attempted; 6.33 MiB remains locally, with no running game/test process.
- The unchanged performance test subsequently passed **3/3 isolated reruns**, each with a fresh profile: purge-hunter timings **2385.1 / 2453.2 / 2442.0 ms**, below the original **3000 ms** limit. Test/Main/Review source hashes matched; no thresholds or product code changed. This supports a non-reproduced timing fluctuation, not proof of its external cause, and does not turn the recorded full run into 97/97. Logs and hashes: `/home/ubuntu/fungi/test-logs/performance-focused-20261004/`.

## Latest: 2026-10-04 Offline review entries / 最新离线审查入口验证

- **97/97** smoke tests, import and main startup PASS; **586 seconds**. Summary: `/home/ubuntu/fungi/test-logs/20261004T070712Z-354659/summary.txt`.
- Review isolation/lifecycle: **567 checks PASS**, with final test-only audio cleanup rerun free of warnings/errors. Log: `/home/ubuntu/fungi/test-logs/review-slice-core-20261004/review_slice_smoke.log`.
- Real OpenGL review UI: **2,269 checks / 126 captures**, nine entries, seven locales, 1280×720 and 640×360. Evidence: `/home/ubuntu/fungi/test-logs/review-layout-20261004T070723Z-354863/`.
- These are server results; finished archive and Windows executable startup gates are recorded separately after export. Manual gameplay/audio approval is not implied.
- The older section below describes the campaign build preceding review-entry support.

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

## 2026-10-08 — Branch-challenge delivery

- Product source: f0d97dca8c73aee68bbd825f14078e3b29964e93; clean build chapter1-review-20261007T203857Z-566d7e9ca37f.
- Full suite: /home/ubuntu/fungi/test-logs/20261007T203527Z-621808/summary.txt — import, 98/98 tests and startup PASS, 735 seconds.
- Focused real-save integration: /home/ubuntu/fungi/test-logs/branch-root-check-20261007T202834Z/ — integration 528, save 66, review 1,193 checks / 27 mission outcomes PASS.
- Chapter renderer: /home/ubuntu/fungi/test-logs/campaign-visual-20261007T203537Z-622199/ — 631 rendered captures, nine scenes, seven languages, two viewport sizes.
- Review renderer: /home/ubuntu/fungi/test-logs/review-layout-20261007T203735Z-622198/ — 2,479 checks / 168 captures.
- Branch renderer: /home/ubuntu/fungi/test-logs/branch-hub-render-20261007T203933Z/ — 24,183 checks / 56 captures. No human visual acceptance is inferred.
- Export verification: /home/ubuntu/fungi/test-logs/review-package-20261007T203857Z-632178/ — clean source, exact layout, 150 verified PCK entries.
- Actual packed-resource startup: /home/ubuntu/fungi/test-logs/branch-packed-runtime-20261007T204708Z/ — nine review entries and normal entry PASS using server Linux Godot. Eight entries retain the known two-ObjectDB exit warning; no native Windows runtime claim.
- Review ZIP SHA-256: e0b0ce5aa16cfc5aa7a65abbbc5c5f2fe57276ff8dcdb926e2cfaa8a19ba21a4.
- Engine-reuse update SHA-256: 56a444aa6202a807df991127272d07cbb7d1687aab922ad6516bd513fcbf2259; 6,276,573 bytes.
- Ordinary three-file ZIP SHA-256: a49c5e21e1f0b6a73a75b8b9c0f4e571f852e7d5ae40f15b6b78b84a2cb1b00f; shares the tested review archive's exact EXE/PCK.
- Local final-artifact update: C:\Users\jiang\Documents\战舰\fungi-test\FungiMicroculture.exe; reused engine SHA-256 502b441aa251105d53741cd999fce0c52bcb9b21be9e4c17694bd2f5069c3227. All 34 manifest files verified, five pre-existing JSON save/settings files unchanged, no local runtime launched.
