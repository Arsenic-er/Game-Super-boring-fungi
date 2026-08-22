# Server Verification Index / 服务器测试记录索引

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
