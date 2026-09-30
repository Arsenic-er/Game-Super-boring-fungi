# 2026-10-01 新服务器恢复与接续

## 恢复范围

- 按用户指定的另一项目最新服务器记录，通过 Tailscale 和既有 SSH 公钥连接新机；没有连接或清理旧服务器。
- 源码恢复到 `/home/ubuntu/fungi/game`，分支 `codex/fungi-next`，基线 `c43406eda1a5788833efeb88c95c06e60bed18d8`。
- 私有素材恢复到 `/home/ubuntu/fungi/dev-assets`，分支 `main`，基线 `919a341982671d564fee5f6f7974fba65e1cc0a5`。
- 两库均核对 `server-retirement-2026-09-17-verified` 标签和 Git 对象完整性。首次未完整的无后缀标签没有被用于恢复。
- 私有库经本机已认证 Git 完整镜像和 bundle 传输，服务端核对传输 SHA-256 后克隆，未向服务器复制 GitHub token。服务端私有库后续 fetch/push 仍需提供受控认证或使用同类传输流程。
- 恢复清单验证：`RECOVERY_MANIFEST_OK references=3033 unique_objects=761`。归档中的历史用户运行数据留在私有库，没有自动覆盖活动存档。

## 独立开发环境

- Godot：`4.7.stable.official.5b4e0cb0f`。
- 引擎：`/home/ubuntu/fungi/tools/godot/4.7/godot`。
- 官方引擎 ZIP 和导出模板 TPZ 均先对照官方 SHA-512 清单验证。仅提取 Windows x64 和无多线程 Web 所需模板，没有安装所有移动平台模板。
- 导出模板位于 fungi 自有数据目录。Windows 导出使用：

```sh
cd /home/ubuntu/fungi/game
XDG_DATA_HOME=/home/ubuntu/fungi/tools/godot-data bash tools/package_windows_portable.sh
```

- 回归仍使用 `bash tools/server-test.sh`：隔离源码快照和 HOME/XDG，保持既有导入、单项测试、启动的超时门槛。不修改其他项目、全局 Godot 配置、GPU 驱动或服务。

## 本轮有界修复

主巢升级或 F5 保存失败后，在同面板重试成功，原界面仍保留保存失败提示。只在实际写盘成功且提示确实为该保存错误时清理，保留无关通知；失败仍显示原错误。回归新增“重新读档之前即清理提示”与真实 F5 失败/重试路径，避免读档重置状态掩盖问题。

此修复不改变任何任务条件、营养/DNA 消耗、材料奖励、科技等级或语言文案。

## 验证记录

- 备份清单、Git 对象及官方工具校验：通过。
- Windows ZIP 验证器的正确结构和四种错误结构用例：通过。
- 原基线全套回归：资源导入、82/82 冒烟测试、主场景无界面启动全部通过，322 秒。证据：`/home/ubuntu/fungi/test-logs/20260930T202121Z-39851/summary.txt`。
- 修复定向回归：先在旧代码上复现失败，再在修复后通过 66/66 断言，七语 F5 失败/成功重试全部覆盖。证据：`/home/ubuntu/fungi/test-logs/notice-recovery-20261001/`。
- 修复后全套回归：资源导入、82/82 冒烟测试、主场景无界面启动全部通过，329 秒，未放宽时间门槛。证据：`/home/ubuntu/fungi/test-logs/20260930T202716Z-48528/summary.txt`。
- 新服务器 Windows 分体包结构验证通过；本机在隔离 APPDATA/LOCALAPPDATA 中无界面运行 60 帧成功退出，未读写玩家存档。这不是人工交互或图形验收。包 SHA-256：`2dbe4367d51631b7471f4f8a579b45f7d2788fdf75f76e0eb1820819c6a20e70`。
- 本机交付目标仍为唯一的 `C:\Users\jiang\Documents\战舰\fungi-test\FungiMicroculture.exe`，相邻 `.pck` 保持独立；更新器只替换四个受管文件并保留玩家存档，安装结果与确切源码提交记录在该目录的 `build-info.json`。不保留第二份可运行测试版。

## 内容边界

目前仍是一个主巢、一个真正独立的补给任务场景、首胜结算和一次主巢升级，不是完整 4–6 小时战役。第一任务已有普通资源脚本可达证据；这不是玩家平均时长。

下一个独立任务可围绕兵营、孢子实际搬运与采区指令设计，让玩家作出近处菌丝吸收或远处外勤采集的选择。任务地图、目标量、补给、材料奖励和危险区仍是待审阅设计，不在本轮偷偷加入第二关或强制等待门槛。
