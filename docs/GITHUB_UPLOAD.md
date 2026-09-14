# GitHub 上传准备

## 仓库简介（可直接粘贴到 About）

苔间小屋：一款支持自备 AI 模型的治愈系青蛙旅行养成游戏。种植、烹饪、远行、收集明信片与装扮，在慢生活中等一封远方的信。Godot / Windows。

English: A cozy frog travel life-sim built with Godot. Grow crops, pack meals, collect postcards and outfits, and bring your own AI companion via Ollama or an API.

建议 Topics：godot、gdscript、cozy-game、life-simulation、frog、ollama、ai-companion。

## 哪些文件上传到哪里

- Git 源码仓库：当前 develop 分支内容，包括 README 和 docs/images。不要把整个本机工作目录直接拖上去。
- GitHub Release 附件：dist/GitHub-Upload/Moss-Release-G18-Audio-Windows.zip 与 Moss-Development-G18-Audio-Windows.zip。
- Release 描述：复制 docs/GITHUB_RELEASE_NOTES.md。
- dist/GitHub-Upload/Moss-and-Moments-Source-G18.zip 是干净源码快照，供迁移或附加下载。需要新建源码仓库时应先解压，不能只上传这个ZIP替代可浏览源码。
- dist/GitHub-Upload/SHA256SUMS.txt 供校验附件完整性。

GitHub Releases 支持二进制附件，官方单文件限制为2 GiB；这两个约200MB的游戏包适合作为Release附件。[GitHub官方说明](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases)

## 用现有Git历史上传

当前开发成果在 develop；本地 main 是旧阶段，不要误推旧 main。Git历史已纳入本次敏感信息模式扫描。

在GitHub创建一个空仓库（不要预建README或许可证），复制它的HTTPS地址。以下命令只供你在准备好目标仓库后执行：

```powershell
git remote add origin <你的GitHub仓库HTTPS地址>
git push -u origin develop:main
```

把本地最新develop推到新仓库main，保留已有历史；这里没有执行远程推送。如已有origin或远端已有内容，先核对目标，不要直接覆盖或强推。

随后在GitHub创建Release，选择刚推送的main提交，添加新标签（例如g18），粘贴发布说明，上传两个游戏ZIP和校验文件。README图片为仓库内相对链接，无需修改账号或仓库名。

## API Key与个人文件检查

运行 `python tools/audit_publish.py`，检查当前待发布文件、所有本地分支/标签可达Git历史和两个游戏包内部资源；报告仅输出匹配位置，不输出密钥内容。

`.local/`、`.env*`、ai-settings.cfg、加密Key、玩家存档、artifacts/、dist/、原始OST和SoundFX均不进入源码提交。安装包检查另独立解压其内部game.zip，不只看外层文件名。源码快照以Git跟踪文件构建，不复制忽略目录。

报告：artifacts/publish-audit.json。本次扫描未检出支持模式的真实密钥，不等于对所有可能秘密形式的数学保证；以后填入新密钥或改配置后请重新检查，勿强制添加被忽略的个人文件。

## 截图来源

README的六张JPEG均取自用户指定宣传片，未生成替代画面：小屋2秒、种植6.5秒、厨房11秒、途中来信22秒、换装33秒、AI设置41秒。设置截图人工查看为空配置，不含Key。
