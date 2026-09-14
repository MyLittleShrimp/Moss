# G21 AI 叙事、全年小书与接口兼容交接

日期：2026-09-15。范围为可选文本生成和未来绘图配置；实时图片生成未实现。新包只在本地构建，GitHub G18 下载包尚未更新。

## 已实现

- 模型设置接受 HTTP(S) 基础地址或完整接口。根地址补 `/v1/chat/completions`，版本基础路径补 `/chat/completions`；其他自定义路径、末尾斜杠与查询参数保持。远程 HTTPS、本机 HTTP；密钥填写独立栏。
- Ollama 支持兼容协议与原生 `/api/chat`，原生模型目录为 `/api/tags`。自定义路径无法推断目录时可手填模型。接受地址不等于支持任意协议，连接测试验证实际响应。
- 启用「AI 陪伴」后，阅读旅行手记或途中信件可生成短文；归家时也可请求最新手记。串行请求，成功结果缓存，原本地文字保留，失败可以在明信片窗口重试。旧存档无需重建。
- 关闭 AI、切换存档、配置变化或记忆清除后，旧回复不写入当前生活。生成文本无库存/奖励权限，规则旅册进展另行展示。
- 离线每日小书 366 篇、1098 页，按月日稳定取文，含2月29日，每年循环。内容是十二月季节主题和31组故事结构编排后的静态文本，不是366次实时模型生成；同一天保持一致。
- 设置新增「明信片绘图 · 预留」，独立配置和可选加密密钥。只准备 payload 和配置入口，无图片网络调用、无绘图费用。

## 主要文件

- `scripts/player_ai.gd`、`settings_panel.gd`：地址、协议、设置。
- `scripts/narrative_service.gd`、`main.gd`、`postcard_view.gd`：生成排队与展示。
- `scripts/expanded_world.gd`、`discovery_world.gd`、`reward_world.gd`：保存验证、文字缓存和本地进展。
- `scripts/yearbook.gd`、`growing_world.gd`、`home_interactions.gd`、`assets/text/yearbook.json`、`tools/build_yearbook.py`：全年书库。
- `scripts/postcard_image_config.gd`：未来绘图配置。
- `export_presets.cfg`、`tools/package_audio_builds.py`、`tools/audit_publish.py`、`.gitignore`：资源打包与配置排除。
- `tests/test_narrative.gd`、`run_narrative.py`、`capture_narrative.gd`、`narrative_scene.tscn`：隔离测试。

## 运行与验证

解压 `dist/Moss-Release-G21-Audio-Windows.zip` 或开发版同名包，双击 `Start.cmd`。已有存档继续使用；模型配置不随存档导出。设置中填地址/模型/自备 Key，保存、测试连接，再启用 AI 陪伴。

执行 `python tests/run_narrative.py`：389 项通过。仅本机模拟 HTTP：兼容路径、自定义路径、Ollama 原生、配置变化丢弃旧回复、503 回退、原文和经济不变、全年唯一文本、绘图 Key 加密。

Godot `--headless --path . --script tests/test_settings.gd`：325 项；`test_growing.gd`：31项；`test_balance.gd`：6264项；`test_travel_mail.gd`：1611项，全部通过。

Godot `--path . tests/narrative_scene.tscn -- --qa`：G21_NATIVE_PASS，截图 `artifacts/g21-settings.png`、`g21-image-settings.png`。QA 不读取玩家配置/存档。

`tools/build.ps1 -Channel Release` / `Development`，随后 `python tools/package_audio_builds.py --label G21`：双包各保留33音频及366篇书库。发布扫描使用 `python tools/audit_publish.py --label G21`，避免误检查旧 G18 包。

双包冒烟均输出 `G10_PACKAGE_SMOKE_PASS`，不读玩家存档、不请求模型。扫描结果 PASS、matches为空，双包各167个含嵌套成员；覆盖已知密钥模式和私有配置文件名，并非任意秘密的数学保证。

## 已知限制与下一步

未使用真实第三方账户或玩家 Key 测试，不声称已验证截图中具体服务。接口需要兼容聊天 JSON 或 Ollama 原生协议；非标准鉴权、其他返回结构仍需独立适配。模型正文需符合约定短文本 JSON，失败回退；提示词约束不能保证模型绝不虚构感受或事实，但程序不会执行文本中的奖励。离线全年文本共享故事结构，后续可逐篇编辑增加差异。

实时明信片下一阶段需要请求执行、格式/尺寸适配、超时重试、图片缓存与存档引用，当前不启用。公开更新应另建发布版本，保留 G18 下载。

协议参考：[Ollama Chat 官方文档](https://docs.ollama.com/api/chat)。
