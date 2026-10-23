# Server-expiry backup / 服务器到期备份（2026-10-24）

## Source progress

The complete development history through `5a9fb199393982f559654bc5abf69d3b763296f0` has been pushed to both `main` and `codex/fungi-next`. Both updates were fast-forwards, without rewriting history. All newly published authors and committers are Arsenic-er.

This includes the nine independent chapter-one mission slices, objective/home-return fixes, the branching home-nest campaign and tissue progression, and eight directly selectable campaign-audit checkpoints. Development notes, review cards, packaging tools, translations and tests are tracked with the code.

The latest executable was built from production commit `7839f54adc572784b90fe6207a561cf84f8f3fd2`; `5a9fb19` adds test-cleanup fixes and verification records, not a different game runtime.

## Playable backup

- Draft release: `backup-2026-10-24`, release ID `421995737`.
- File: `FungiChapter1-Review-Windows-x64.zip`, 44,288,391 bytes.
- SHA-256: `918210dd6d9548cf31406469e241b40e12add4e7bd25c14b1057b826e905448a`.
- Build: `chapter1-review-20261007T211921Z-0b73383b62cf`.
- GitHub's stored asset digest and size were verified after upload.
- The existing public v0.16.0 release is unchanged; this backup remains a draft.

The full ZIP includes one Windows EXE, its adjacent PCK, normal play, eight checkpoint choices via the 00 launcher, nine isolated mission launchers, and offline review documentation. Extract the entire folder. The ordinary and engine-reuse update ZIPs contain the same game payload, so they were not uploaded again.

Production art, fonts and audio already exist in the private `Game-Super-boring-fungi-dev-assets` repository and were not duplicated. Additional unique server evidence is retained under its `recovery/server-backup-2026-10-24/` directory, with content hashes and recovery instructions. Private runtime/diagnostic data is not included in this public source repository or playable ZIP.

Private archive publication was verified at commit `d643bc3985e3ed83b1449553549dc076bb300b55`:

- 5,313 recovery references, including 2,015 new content-deduplicated objects (57,921,135 bytes).
- Recovery manifest SHA-256: `649430fd7b77f096cf6085e2d14b6d07aa10b13408d9a003f1026cebd0ee7996`.
- Tracked object bytes, reachable history references and original content hashes all passed verification.
- Remote private `main` matched that exact commit after push.

## 恢复与继续开发

1. 在新服务器克隆本源码仓库，使用 `main` 或 `codex/fungi-next`。本次把旧主分支直接快进到完整开发进度，未丢弃旧提交。
2. 有权限时克隆私有素材库。按其中恢复清单验证内容；历史诊断草稿只作证据，不要覆盖正式源码。
3. 仅需要试玩时，在 GitHub 登录仓库所有者账号，从上述草稿 Release 下载完整审查包。00 入口可直接切入八个主巢进度节点，01–09 为独立单关。
4. 继续开发仍在服务器上安装项目所需 Godot 4.7 工具；引擎、可下载依赖、导入缓存和临时构建缓存不纳入 Git 备份。
5. 关键开发状态与验证限制见 `DEVELOPMENT_LOG.md`、`TEST_LOG_INDEX.md` 和 `review-slices/README.md`。

## Verification boundaries / 验证边界

This backup operation checks Git history, authorship, asset parity, archive hashes and remote publication. It does not perform a new gameplay test run or turn prior test results into a clean full-suite claim.

The recorded full suite initially passed 98/100 because an audit-test sentinel cleanup defect interfered with two later tests. The corrected shared-profile sequence passed all three affected tests. The final exported PCK passed 30 server-side route cases, with seven-language render checks separately recorded. Native Windows interaction and player pacing still require user review.

此次只备份，不删除服务器上的项目、素材、日志或存档；不向本机下载源码、依赖或新增开发环境。GitHub 登录凭据仅通过加密 SSH 传入远端进程内存，未写入文件或日志。

两个库恢复时应保留完整 Git 历史，不使用浅克隆：私有恢复清单可以引用已有历史对象，以避免重复上传相同内容。

这份记录之后的备份说明提交不改变游戏运行代码。远端分支最终提交号以完成备份后的 Git 引用为准。
