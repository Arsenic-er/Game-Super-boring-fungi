# 2026-09-17 服务器到期：备份与恢复说明

## 最新项目在哪里

- 公开源码仓库：`Arsenic-er/Game-Super-boring-fungi`，当前开发分支 **`codex/fungi-next`**。默认 `main` 仍是旧归档，不要只拉默认分支就当作最新版本。
- 私有素材仓库：`Arsenic-er/Game-Super-boring-fungi-dev-assets`，分支 **`main`**。
- 两库使用同名恢复标签 `server-retirement-2026-09-17` 固定此次归档；不改写既有分支历史，不更改仓库可见性。
- 本次不开发新玩法。最后一个游戏代码提交为 `954715782fdcd4416207f67df1cb7268f6f69235`；其后的此次提交只记录恢复信息。

## 目前真正完成的内容

保留像素俯视、菌丝经营、DNA 与食性升级、兵营和可指挥体外孢子、探索黑幕、七语言及最多 48 小时离线经营。当前剧情方向是独立任务取得材料、返回长期主巢并升级，不再以早期单场快速通关代表完整新战役。

已有 **一个**主巢—任务—返回—升级闭环：主巢和“第一条补给线”分别是 `HomeNest.tscn`、`FirstSupply.tscn`。首个任务用临时菌落和固定补给；胜利首次获得 3 份筑巢物质，可升级主巢到 2 级。后续挑战只有预告，完整 4–6 小时第一章尚未制作。任务设计、数值与未定项见 `CHAPTER1_STORY_CAMPAIGN.zh-CN.md`，实际场景与验证见 `CHAPTER1_INDEPENDENT_SCENES.zh-CN.md`。

最近完整验证：Godot 4.7，资源导入、82/82 冒烟测试、主场景启动通过，用时 318 秒；Windows 真实渲染取得 33 张截图并抽查代表画面。没有把脚本或截图称作真人手感验收。

本机测试版保留在 `C:\Users\jiang\Documents\战舰\fungi-test\FungiMicroculture.exe`，采用 EXE + 相邻 PCK，不是嵌入全部资源的单文件 EXE。对应包 SHA-256 为 `e29400b3edb0114a88223956b1a0deb9107d55d81c6a60a6e6fc09596162a907`。服务器清理不涉及本机文件或本机存档。

## 新服务器恢复

在新的开发服务器家目录创建 `fungi`，通过 Git 账户自己的凭据获取项目：

```sh
mkdir -p "$HOME/fungi"
git clone --branch codex/fungi-next https://github.com/Arsenic-er/Game-Super-boring-fungi.git "$HOME/fungi/game"
git clone https://github.com/Arsenic-er/Game-Super-boring-fungi-dev-assets.git "$HOME/fungi/dev-assets"
```

需要精确重现本次归档时，可在两个仓库分别检出同名恢复标签。准备 Godot 4.7 及对应导出模板；已有 `tools/server-test.sh`、`tools/package_windows_portable.sh`，可通过 `GODOT_BIN` 指定新机器上的引擎路径。旧绝对路径不一定适用于新服务器，先阅读 `docs/SERVER_TESTING.md`。

运行资源导入和全套测试后再继续开发。Windows 导出仍使用分离包和原有 ZIP 校验、本机隔离启动校验。不要把服务器历史测试存档自动覆盖到用户正在使用的本机存档。

## 额外资料与隐私

正式美术、音频、字体、候选稿已经在私有素材库；本次按 SHA-256 去重补存未归档截图、日志、历史诊断草稿和旧部署辅助脚本。其位置：`recovery/server-retirement-2026-09-17/manifest.json`。每条记录保留原路径、长度、摘要及对应私有对象或既有 Git 文件的恢复引用。

服务器上残留的本项目 Godot 存档只进私有归档，不进公开源码库。凭据、SSH 私钥、token 和 Tailscale 配置不进入任何仓库。

可重新下载或生成的 Godot 二进制、导出模板副本、下载包、导入缓存、重复 PCK/EXE 和历史构建不重复塞入 Git。无独有修改的临时源码镜像由源码历史恢复。

## 清理的硬性顺序和边界

先推送两个仓库及恢复标签，再从远端重新克隆；逐一验证 Git 完整性、分支/标签提交、源码文件清单和私有恢复清单的内容摘要。全部通过后，才清理旧服务器的以下准确范围：

1. `/home/ubuntu/fungi`，包括其内部源码、素材克隆、下载、工具副本、日志和构建。
2. 经过检查且无运行任务引用的 `/tmp/fungi-*` 历史测试文件与目录。
3. 已先私有备份的 `/home/ubuntu/.local/share/godot/app_userdata/Game- Super boring fungi`。

不删除 `~/.ssh`、Tailscale、全局 Godot 模板/配置/缓存或任何其他项目。记录本身是恢复与清理规范；实际推送/复核/清理结果以本次操作完成后的交付记录为准，不能仅凭这篇文档推断文件已经删除。
