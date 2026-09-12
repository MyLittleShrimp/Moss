# G3 交接：旅行内容与 AI 代理

日期：2026-09-09。状态：**本轮技术切片完成；真实国内供应商联调待定**。用户已确认上一版本可玩，本轮明确选择优先国内模型、稍后提供服务名称。

## 完成范围

- 三个可选目的地：溪谷、林间集市、山坡；六个有标题与固定事实的旅行事件。
- 优先出现尚未经历的内容；同地点两事件耗尽后交替。不是无限生成，也不是概率型事件系统。
- 出发时保存事件快照；返回和重开不重抽。仍使用一份便当、35 秒旅行、一枚青石奖励。
- 旅途页可翻阅最近 30 封信；老信缺少地点/标题时显示兼容标签。
- schema 1→2 非破坏迁移，迁移前保留 `.v1-backup`，保留库存、收藏、偏好和进行中旅行计时。
- AI 开关、来源标记、本地 HTTP 代理、可配置国内兼容接口、超时回退、输出字段限制、调用次数预算与过期回复丢弃。

## 修改文件

| 文件 | 内容 |
|---|---|
| `scripts/travel_catalog.gd` | 六个事件、目的地、选择与事件校验 |
| `scripts/world.gd` | 快照、信件、历史 ID、schema 迁移 |
| `scripts/main.gd` | 目的地选择、信件翻页、AI 开关和异步回复整合 |
| `scripts/local_dialogue.gd` | 根据实际目的地说途中便签 |
| `scripts/dialogue_client.gd` | Godot HTTPRequest、8 秒等待、响应校验 |
| `server/proxy.py` | Python 标准库 loopback 代理、两个协议适配、预算与鉴权 |
| `server/ai.example.json` | 无密钥、默认关闭的配置模板 |
| `StartAIProxy.cmd` | 本机代理启动入口 |
| `tests/test_world.gd` | 41 项规则与迁移检查 |
| `tests/test_proxy.py` | 8 项代理测试与模拟供应商集成 |
| `tests/test_dialogue_client.gd` | Godot 实际 HTTP 成功/失败验证 |
| `tests/delayed_client.gd` | 仅用于验证过期回复的延迟模拟 |
| `README.md`、`run.ps1`、`docs/STATUS.md` | 当前操作、测试入口与状态 |
| `docs/AI_SETUP.md`、`docs/TROUBLESHOOTING.md` | 配置边界与 TS-006–008 |

## 运行与体验

关闭旧游戏窗口后重新双击 `StartGame.cmd`（不要同时开两份写同一存档）。底部下拉框选目的地，做便当并出发；回来后在「旅途」用较新/较早翻阅信件。顶部 AI 默认关闭，不需要配置即可玩完整闭环。

真实 AI 配置见 `docs/AI_SETUP.md`，具体国内厂商未确定前保持默认关闭。密钥放在启动代理的本地环境，不发到聊天、不写进游戏资源或 JSON。代理只写本地次数预算，不操作游戏存档。

## 实际验证

| 验证 | 结果 | 证据 |
|---|---|---|
| 游戏规则/兼容迁移 | 41 项 PASS | `artifacts/g3-world-tests.log` |
| 代理与协议适配 | 8 项 PASS，无真实供应商网络调用 | `artifacts/g3-proxy-tests.log` |
| Godot→本机 HTTP | 成功和 503 回退均通过，上游为模拟 | `artifacts/g3-client-tests.log` |
| 原生 UI | 点击闭环、目的地、集市事件、历史翻页通过 | `artifacts/g3-ui-qa.log` |
| 过期回复 | 等待中修改 revision，旧文本被丢弃 | 同上 `STALE_REPLY_PASS` |
| 视觉 | 1280×800 原生渲染，已检查首页和集市信件，文字与控件无明显重叠 | `artifacts/g3-01-home.png`、`g3-05-market.png` |

命令：`./run.ps1 -Test`、`python tests/test_proxy.py`、`./run.ps1 -VisualQA`。测试都是独立文件或内存世界，未修改用户实际存档。原 G0–G2 handoff 和截图仍保留，反映当时版本。

## 未完成与限制

- 没有实际国内模型名称、endpoint、模型权限或密钥，所以没有真实对话质量与费用结论。
- chat_completions 只是通用适配，不保证每个国内服务字段完全兼容；json_mode 默认关闭，返回仍严格解析 JSON。
- 代理校验结构和长度，不保证自然语言语义事实绝对正确；文本可能说错，但不能直接发奖或执行命令。
- 仅本轮普通聊天接代理，旅行信仍为事件模板；记忆仅支持已有明确表达，尚无自由语义记忆提取。
- 六个事件共用青石奖励与现有背景，未新增地图场景、纪念品美术、语音和分层动画。
- 一分钟6次、UTC每日100次是尝试次数上限，不是实际金额预算；上游错误不自动重试。
- 本机代理不是生产公网服务，世界仍是本地单用户；没有云同步、服务器权威状态、MCP 或多实例锁。

## 下一步

用户提供国内服务名称后，先查官方接口并补适配特有参数，再以少量请求做真实联调与角色/事实评测；真实通过后另交 handoff。并行工作的候选是活动空间与角色动画，但尚未擅自标记完成。新问题持续追加 troubleshooting。
