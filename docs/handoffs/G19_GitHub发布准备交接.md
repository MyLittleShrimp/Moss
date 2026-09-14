# G19 GitHub发布准备交接

日期：2026-09-14。范围：发布材料与敏感数据检查，不改游戏行为，不创建远程仓库、不推送、不发布Release。

## 内容

README重写为当前G18玩家介绍，使用宣传片六张截图：home 2s、garden 6.5s、kitchen 11s、letters 22s、outfits 33s、ai 41s。图片在docs/images，1280宽JPEG，使用相对链接；AI设置帧已查看，配置为空。图片展示旧宣传片的演示界面，README明确说明版本差异和加速。

仓库About短描述和上传步骤在docs/GITHUB_UPLOAD.md；Release正文在docs/GITHUB_RELEASE_NOTES.md。没有为未选择的项目许可证擅自授予MIT等许可。README不再将已完成的混合便当/服装等列为未实现，也不把本地手记说成实时LLM生成。

## 文件与运行

修改：README.md、.gitignore、docs/STATUS.md、docs/TROUBLESHOOTING.md。
新增：docs/GITHUB_UPLOAD.md、docs/GITHUB_RELEASE_NOTES.md、docs/images/六张JPEG、tools/audit_publish.py、tools/prepare_github.py、tests/test_publish_audit.py、本交接。

`python tools/audit_publish.py`：扫描待提交文件、所有本地分支/标签可达历史对象、正式/开发ZIP与内部game.zip；报告位置artifacts/publish-audit.json，不输出匹配秘密内容。

`python tools/prepare_github.py`：先执行扫描，通过后按Git跟踪文件构建源码ZIP，复制原G18正式/开发包、上传说明、发布正文和审计报告，输出SHA256SUMS.txt。执行前将希望纳入源码快照的文件加入Git暂存区或提交。

最终材料目录：dist/GitHub-Upload。源码是Moss-and-Moments-Source-G18.zip，两个二进制仍沿用G18包名。工具不访问网络，不上传。

## 验证

原Git历史361个blob扫描未发现支持模式的Token。两套便携ZIP各含163个成员（含嵌套统计），扫描通过，无个人配置、加密Key或玩家存档。最终提交后的报告由prepare_github重新生成，历史对象数会增加。

扫描器4项单元测试通过：Token检出但日志脱敏、Godot运行时资源的窄白名单、嵌套ZIP检出、PEM解析标记与完整密钥块区分。README配图路径检查、源码ZIP内README与六图检查由打包脚本执行。截图总览及AI页已人工视觉检查。没有为文案修改重跑游戏经济测试，游戏程序及二进制与G18一致。

## 限制与下一步

模式扫描不能证明不存在所有未知格式秘密；以后修改配置或新增文件后需重新运行。Git跟踪源代码和文档含机制细节，公开仓库玩家可以自行阅读，不承诺数值保密。没有清理本机秘密或更改玩家存档。

用户创建空GitHub仓库后按上传说明推送当前develop到远程main，再发布两个Release附件。本地main仍是历史阶段，不应误推旧内容；不使用强推。GitHub远程地址未提供，故未设置origin或实际上传。未重新生成音乐、美术或游戏包。
