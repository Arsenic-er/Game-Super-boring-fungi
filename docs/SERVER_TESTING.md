# Server-side verification / 服务器端测试

## Current default: server only / 当前默认：仅在服务器（2026-10-03）

Keep source checkout, editing, dependencies, builds, tests, experiments, results
and Git publishing on the designated server. The user's computer is a remote
control endpoint, not a fallback development environment. Return concise text
summaries only. Downloading any particular file requires explicit user consent.
Do not create local clones, worktrees, build directories or experimental caches.
If SSH/Tailscale fails, diagnose the connection and report a blocker rather than
building locally. Stop a cleanup operation if the execution environment blocks it.

源码、编辑、依赖、构建、测试、实验、结果和 Git 发布默认均在服务器；本机仅作
远程控制端，不再自动下载测试包或建立开发副本。具体文件下载须先获得明确同意。
连接失败不退回本机构建；删除被拦截就停止，不换工具绕过，也不谎称已完成。
先前通过本机 Git mirror/bundle 中转恢复的记录仅作历史保留，不再自动沿用。
需要更新私有仓库时，先在服务器核对受控认证；不能因此把完整仓库再次克隆到本机。

## Optional Windows delivery / 经明确同意才进行的 Windows 交付

The local-update workflow below was the default on 2026-09-13. From 2026-10-03
it is opt-in only. When requested, keep one installed version with separate EXE
and adjacent PCK files, not an embedded executable.

Build the portable ZIP with `tools/package_windows_portable.sh`, copy that
archive to a temporary local download location, and obtain its SHA-256 from
the server. Then run:

```powershell
.\tools\windows_update_local_test.ps1 `
  -ArchivePath .\FungiMicroculture-Windows-x64.zip `
  -Destination "$env:USERPROFILE\Documents\战舰\fungi-test" `
  -ExpectedSha256 <server-sha256> -SourceCommit <git-commit> -RemoveArchive
```

The updater checks the archive hash and extracted EXE/PCK startup before
replacing the existing version. It refuses to overwrite a running game,
restores the previous managed files if replacement fails, and removes temporary
backup/staging directories after success. Unrelated files and application-data
saves are not removed. The installed `build-info.json` records the source
commit, package hash and update time. Keep the same destination on every update.

Run `tools/windows_update_local_test_selftest.ps1` to verify replacement,
rollback on a locked file, running-game rejection, hash checking and missing-PCK
rejection without downloading a game build.

以下本机安装步骤保留作为按需交付工具，不再自动执行。仅在用户明确要求下载后，
测试版可放在本机 `%USERPROFILE%\Documents\战舰\fungi-test` 并覆盖同一目录。
届时只保留一份最新版，
仍采用 EXE 加独立 PCK 的拆分布局，不退回资源全部内嵌的单文件形式。

更新前先核对压缩包 SHA-256 并测试 EXE/PCK 能否启动；游戏运行中不会强行覆盖。
中途失败会恢复上一份文件，成功后删除临时备份和下载 ZIP，保留构建提交号与
校验值。用户存档和非安装器管理的文件不删除。浏览器存档与 Windows 存档仍
相互独立，本流程不做隐式迁移。

## Server-only OpenGL captures / 仅在服务器生成画面证据

On the configured server, run:

```bash
cd /home/ubuntu/fungi/game
bash tools/server_campaign_visual_probe.sh
```

The helper uses project-local Xvfb/PRoot utilities and the existing Mesa software
renderer, with an isolated source snapshot and HOME/XDG directories. It does not
change GPU drivers or require a permanent display service. PNGs, fixture saves
and complete logs remain under the server's `test-logs/campaign-visual-*/`.
Only return its concise text summary unless the user explicitly requests files.
The checks confirm actual rendering, PNG dimensions and seven-language compact
coverage; they do not claim human visual review, real input testing or balance.

On the restored server, portable display tools live under
`/home/ubuntu/fungi/tools/xvfb`; downloaded Debian packages stay under
`/home/ubuntu/fungi/tools/xvfb-downloads`. They were extracted there without
installing system packages: `xvfb`, `libxfont2`, `xserver-common`, `libpixman-1-0`,
`libfontenc1`, `x11-xkb-utils`, `libxkbfile1`, `proot`, `libtalloc2`, `libxcursor1`,
`libxinerama1`, `libxi6`, `libxrandr2`, `libxrender1`, `libxfixes3`, `libxkbcommon0`.
System `xauth` and Mesa were already available. PRoot maps the project-local
`xkbcomp` into Xvfb's fixed child-process lookup path; it does not replace the
host executable or grant extra privileges. Missing tools stop the run.

已配置服务器可在用户目录内运行便携虚拟显示与软件 OpenGL。图像与完整日志不回传本机。
无界面回归不等于真实画面；成功生成画面也不等于已经人工审阅文字、完成真人操作或数值验收。

## English

The Linux development server can verify the source project without exporting or
copying a Windows executable:

```bash
cd /home/ubuntu/fungi/game
./tools/server-test.sh
```

One run performs three gates:

1. Imports all Godot resources in an isolated temporary project.
2. Runs every `tests/*_smoke.gd` test (including `smoke_test.gd`).
3. Starts the real main scene headlessly for 30 frames.

The temporary project is removed automatically. Godot's generated `.uid`,
`.import`, cache, settings, and `user://` files never touch the source checkout.
No EXE, PCK, or release archive is produced.

The terminal ends with a short pass/fail summary. Detailed logs are kept under:

```text
/home/ubuntu/fungi/test-logs/
```

`/home/ubuntu/fungi/test-logs/latest/summary.txt` always points to the newest
summary. Failed runs also retain individual test logs. To preserve the temporary
project for diagnosis, use `./tools/server-test.sh --keep-workdir`.

Godot and timeout locations can be overridden through environment variables;
run `./tools/server-test.sh --help` for the complete list.

## 简体中文

Linux 开发服务器可以直接检查源码项目，不需要导出或复制 Windows EXE：

```bash
cd /home/ubuntu/fungi/game
./tools/server-test.sh
```

一次运行依次完成三道检查：

1. 在隔离的临时项目中导入全部 Godot 资源。
2. 执行 `tests/*_smoke.gd` 中的全部测试（包含 `smoke_test.gd`）。
3. 以无界面模式启动真实主场景并运行 30 帧。

临时项目会自动删除。Godot 生成的 `.uid`、`.import`、缓存、设置和
`user://` 文件不会污染源码目录，也不会产生 EXE、PCK 或发布压缩包。

终端最后只显示简洁的通过/失败汇总；完整日志保存在：

```text
/home/ubuntu/fungi/test-logs/
```

`/home/ubuntu/fungi/test-logs/latest/summary.txt` 始终指向最新汇总。
失败时会保留各测试的独立日志。需要保留临时项目排查问题时，可使用
`./tools/server-test.sh --keep-workdir`。

Godot 路径和各阶段超时时间均可通过环境变量覆盖；运行
`./tools/server-test.sh --help` 可以查看全部选项。

## Browser preview (English)

Use the browser export for routine interactive checks on the development server:

```bash
cd /home/ubuntu/fungi/game
./tools/web_preview.sh start
./tools/web_preview.sh status
./tools/web_preview.sh restart
./tools/web_preview.sh stop
```

`start` rebuilds the Web export and starts the preview if it is not already
running. `restart` stops the managed preview process, rebuilds, and starts it
again. The service is bound only to `127.0.0.1:8060`; it is not exposed directly
to the public network.

From the Windows development computer, keep this SSH tunnel running:

```powershell
ssh -N -L 8060:127.0.0.1:8060 ubuntu@<server-ip>
```

Then open `http://127.0.0.1:8060/` in the browser. Browser saves use IndexedDB
and are isolated by origin. Keep the same local port (`8060`) and browser
profile if you want the same preview saves to remain available.

The Web build is for everyday testing only. Before a final release, build and
verify the portable Windows package described below, then run its Windows smoke
test as the release gate.

## 浏览器预览（简体中文）

日常需要交互测试时，可以直接使用开发服务器上的浏览器版本：

```bash
cd /home/ubuntu/fungi/game
./tools/web_preview.sh start
./tools/web_preview.sh status
./tools/web_preview.sh restart
./tools/web_preview.sh stop
```

`start` 会重新导出 Web 版本；预览服务尚未运行时才新建服务进程。
`restart` 会停止受脚本管理的旧进程、重新导出并启动。服务只绑定在
`127.0.0.1:8060`，不会直接暴露到公网。

在 Windows 开发电脑上保持以下 SSH 隧道运行：

```powershell
ssh -N -L 8060:127.0.0.1:8060 ubuntu@<server-ip>
```

然后用浏览器打开 `http://127.0.0.1:8060/`。浏览器存档保存在按来源隔离的
IndexedDB 中；要继续使用同一份预览存档，请保持本地端口为 `8060`，并使用
同一个浏览器配置文件。

Web 版本只用于日常开发测试。最终发布前仍须生成并校验下述 Windows
便携拆包，并通过 Windows 端冒烟测试后才能作为发布版本。

## Portable Windows package / Windows 便携拆包

The release bundle keeps the engine executable and game data separate. Build
it with an explicit destination:

```bash
cd /home/ubuntu/fungi/worktrees/codex-fungi-next
./tools/package_windows_portable.sh /absolute/output/FungiMicroculture-Windows-x64.zip
```

The ZIP root contains exactly `FungiMicroculture.exe`,
`FungiMicroculture.pck`, and `README-FIRST.txt`. Run both artifact gates before
publishing:

```bash
./tools/windows_split_export_smoke.sh
./tools/windows_portable_bundle_smoke.sh
```

The Linux server cannot execute the Windows build. On a Windows machine, first
self-test the runtime gate, then run it against the finished candidate ZIP:

```powershell
powershell -ExecutionPolicy Bypass -File tools\windows_portable_runtime_gate_selftest.ps1
powershell -ExecutionPolicy Bypass -File tools\windows_portable_runtime_smoke.ps1 `
  -ArchivePath C:\absolute\path\FungiMicroculture-Windows-x64.zip
```

The runtime gate extracts into a fresh temporary directory, verifies the exact
three-file layout, reads every ZIP payload, launches the extracted EXE with
`--headless --quit-after 30`, requires a clean bounded exit, and then removes
the temporary files. Passing the fixture self-test proves the gate logic, not
the actual game candidate; the second command is the final Windows release
evidence.

发行包将引擎程序与游戏数据分开保存。使用上面的命令指定输出 ZIP；其根目录
只包含 `FungiMicroculture.exe`、`FungiMicroculture.pck` 与
`README-FIRST.txt`。发布前必须执行两项产物门禁。玩家解压后应让 EXE 与
PCK 始终位于同一文件夹。

Linux 服务器不能执行 Windows 构建。请在 Windows 机器上先运行门禁自测，
再对最终候选 ZIP 运行实际启动门禁。它会在新的临时目录解压、核对准确的
三文件结构、读取全部 ZIP 内容、使用 `--headless --quit-after 30` 启动 EXE，
要求其限时正常退出，最后清理临时文件。临时测试程序通过只证明门禁逻辑；
第二条命令的真实游戏结果才是最终 Windows 发行证据。

## Secure-context note / 安全上下文说明

Godot 4.7 Web exports do not run from a plain `http://<server-ip>:8060/`
origin. The engine rejects that origin because it is not a secure context.
Use the loopback SSH tunnel shown above and open exactly
`http://127.0.0.1:8060/`. A direct-IP HTTP 200 response only proves that the
files are reachable; it does not prove that the game can start.

Godot 4.7 的 Web 导出不能从普通的 `http://<server-ip>:8060/` 来源运行；
即使该地址返回 HTTP 200，引擎仍会因为它不是安全上下文而拒绝启动。请使用
上面的 SSH 本地转发，并准确打开 `http://127.0.0.1:8060/`。直接 IP 能访问
只能证明文件可达，不能证明游戏已经成功运行。

## Current restored checkout / 当前恢复后的开发检出（2026-10-03）

The current server checkout is `/home/ubuntu/fungi/game` on branch
`codex/fungi-next`. Run verification and exports there. The older
`/home/ubuntu/fungi/worktrees/codex-fungi-next` path belonged to a retired server
layout; do not assume that worktree exists on the restored server.

新服务器当前检出为 `/home/ubuntu/fungi/game`，分支为 `codex/fungi-next`。
旧工作树路径仅属历史部署记录；后续验证、构建和编辑均以当前检出为准，
不在本机重新建立仓库或工作树。
