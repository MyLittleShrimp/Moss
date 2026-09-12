# Git 与双版本工作流

本项目从 G10 开始建立本地 Git 历史；历史阶段的交接文档保留，但不虚构此前的提交记录。

- develop：日常开发分支，当前工作区所在分支。
- main：通过验证后可构建的发布基线。
- v0.10.0：本次玩家模型、多存档和双版本功能快照。
- 没有配置远程仓库，没有上传代码。首次提交使用明确的本地项目身份 Moss Development / moss-local@localhost，不修改全局 Git 用户配置。

两分支本次指向相同的已测代码，版本差异来自 export_presets.cfg 的构建特性与 scripts/build_profile.gd 数值。这样修复存档、AI或玩法时不需要维护两套相似实现。

## 日常操作

```powershell
git switch develop
git status
# 完成修改并运行本阶段测试后：
git add scripts tests docs
git commit -m "Describe the concrete change"
```

正式发布时，先确认工作区干净和回归测试通过：

```powershell
git switch main
git merge --ff-only develop
# 为新版本使用新的标签，不覆盖已发布标签
# git tag v0.10.1
./tools/build.ps1 -Channel Release
git switch develop
```

不要因未合并分歧直接强制覆盖分支；无法快进时先处理差异。新设备先配置自己的 Git 提交身份，再提交后续工作。

## 构建与分发

```powershell
./tools/build.ps1 -Channel Development
./tools/build.ps1 -Channel Release
```

输出 dist/Moss-Development 和 dist/Moss-Release，分别打开 Start.cmd。根目录 StartGame.cmd 保持开发运行，StartReleasePreview.cmd 预览发布节奏。

发布时分享整个便携文件夹或它的外层压缩包。内部 game.zip 只有游戏资源，必须与 Moss.exe、Start.cmd 和许可文件一起分发。当前使用完整 Godot 二进制，后续安装专用导出模板可缩小体积。

## 忽略与保护

.gitignore 排除 .local、.tools、.godot、artifacts、dist、日志、加密密钥、环境文件与编辑器运行目录。玩家实际存档位于 user://，不在仓库内。工程的正式素材与源码进入 Git；测试证据保留本地 artifacts，可按文档复现，但不把测试存档提交。

导出预设同时排除 server、tests、artifacts、docs、旧 dialogue_client 和工具文件。没有把旧本机 DeepSeek 配置复制进仓库或发布包；旧本地配置仍留在原处，方便历史开发排查，新游戏入口不使用它。

Git 只在当前设备建立版本记录，不等于异地备份。后续可按你指定的平台建立私有远程；本轮没有自行上传。

## G11 更新

v0.11.0为途中来信与五城途经明信片版本，main快进到该已测基线，develop继续开发。v0.10.0标签和旧便携压缩包均保留。
