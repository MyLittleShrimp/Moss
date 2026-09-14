# G20 GitHub上传交接

日期：2026-09-14。目标仓库：https://github.com/MyLittleShrimp/Moss 。用户明确授权实际上传。

## 已执行范围

检查目标仓库为空后，添加origin，使用普通git push将本地develop推送为远程main；没有强推，没有覆盖现有远端分支。本地develop跟踪origin/main，本地历史main未改动。

G18游戏Release：https://github.com/MyLittleShrimp/Moss/releases/tag/g18 。Release关联游戏与首版发布材料提交884a3b0；后续首页链接/交接更新位于main，不改变G18游戏内容。

正式版、开发版ZIP与G18-SHA256SUMS.txt作为附件上传；先创建草稿，附件齐全后再公开。源码由Git仓库提供，未另上传重复源码ZIP。设置仓库About简介，README改为直接下载链接。

## 文件

README.md：真实Release下载链接。
docs/GITHUB_UPLOAD.md：当前远端与已上传状态，标记首次上传命令为历史参考。
docs/STATUS.md、本交接：发布状态和证据。

## 验证与隐私

- 首次ls-remote为空，上传后远端main确认884a3b0a8072d09d7fdbf2ecfc6f63bb63b7fb9c；文档完成后再次推送并核对最终HEAD。
- 发布前审计：319个工作文件、377个历史blob、每包163个含嵌套成员，模式扫描PASS，未检出API Token、本机配置或玩家存档。
- 上传使用Git凭证助手的现有登录，凭证只在进程内存中传给GitHub API；没有把Token写入源码、脚本参数、报告或日志。
- GitHub返回的附件名称、大小、下载URL及digest记录在本机artifacts/github-published.json；SHA-256与本地ZIP复核一致。
- 上传只涉及文档和已验证G18二进制，无游戏规则修改，因此没有重跑游戏测试。

## 运行与后续维护

玩家在Release选择正式版或开发版，完整解压后双击Start.cmd。
开发者在当前目录使用git push origin develop:main更新源码；发布新版本前运行tools/audit_publish.py，构建新包并创建新Release，不覆盖旧包。

本机GitHub-Upload目录仍是G19时的首次上传材料快照；在线main的README已换为真实下载链接。游戏包相同。GitHub仓库/Release已公开可访问，未设置分支保护或自动发布工作流，项目整体许可证尚未指定。
