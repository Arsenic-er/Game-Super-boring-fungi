# Server-side verification / 服务器端测试

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

The Web build is for everyday testing only. Before a final release, export the
Windows EXE and run its Windows smoke test as the release gate.

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

Web 版本只用于日常开发测试。最终发布前仍须导出 Windows EXE，并通过
Windows 端冒烟测试后才能作为发布版本。
