# G4 交接：DeepSeek 真实接入

日期：2026-09-09。状态：完成本轮接入与少量真实联调，不代表模型长期质量评测完成。

## 范围与结果

DeepSeek Chat Completions 已接通，使用官方文档当前列出的 `deepseek-v4-flash`，JSON Object 模式，关闭 thinking。独立合成输入与 Godot→本机代理→DeepSeek→校验→界面两种真实链路均成功。模型仍只能返回文本和情绪，不能改变库存或记忆。

密钥未放进源代码、日志或本文件；当前用户的 Windows DPAPI 加密文件位于 Git 忽略的 `.local`。代理可读取环境变量 `DEEPSEEK_API_KEY` 覆盖本地存储。不应把 `.local` 打包分享。

## 改动文件

- `server/proxy.py`：加密凭据加载、DeepSeek thinking 配置、明确情绪枚举、健康与授权关闭接口。
- `server/deepseek.example.json`：无密钥供应商配置模板；本机配置在忽略目录。
- `server/live_check.py`：显式付费路径的单次合成输入检查，仅保存安全错误码和测试响应。
- `server/launch.py`、`StartGame.cmd`：检测本机代理并按需隐藏启动，然后运行 Godot。
- `server/stop_proxy.py`、`StopAIProxy.cmd`：通过令牌停止本机代理，不按进程名称批量终止。
- `scripts/main.gd`：独立内存世界真实 QA 入口、截图与开关选中态文字修复。
- `README.md`、`docs/STATUS.md`、`docs/AI_SETUP.md`、`docs/TROUBLESHOOTING.md`：使用方式和 TS-009–011。

## 使用

重新启动 `StartGame.cmd`，打开顶部「启用 AI 对话」，输入普通纸条。明确偏好更新仍标注本地规则。关闭 AI 开关停止后续模型请求；双击 `StopAIProxy.cmd` 可关闭后台代理。代理不会自行轮询模型。

## 验证证据

- `artifacts/g4-live-check.json`：真实 DeepSeek 合法输出，记录单次约1.9秒；输入为合成测试文字。
- `artifacts/g4-live-ui.log`：`G4_LIVE_UI_PASS`，实际 Godot 图形链路，库存未改变，未触碰用户存档。
- `artifacts/g4-live-dialogue.png`：实际视口截图，显示真实 LLM 回复。
- `artifacts/g4-proxy-tests.log`：8项无付费代理回归通过。
- `artifacts/g4-regression-ui.log`：玩法、历史翻页、过期响应丢弃通过。
- 运行控制：实际执行启动→授权关闭→再次启动，分别返回 PROXY_READY / Local proxy stopped / PROXY_READY；最终本地代理处于可用状态，不主动发模型请求。

联调曾发生一次本地凭据失败与两次输出枚举失败，修复后两条真实成功路径通过；没有自动无限重试。测试消耗少量供应商请求，未核算人民币金额，不能将一次延迟当 P95。

## 剩余边界与下一步

当前逐条聊天只携带本次输入与有限事实，尚无多轮短期上下文；旅行信仍为模板；情绪字段暂未映射完整角色动画。自然语言事实一致性仍需评测，结构正确不保证语义绝对正确。

下一阶段建议：短期对话上下文、常见情绪与偏好样例评测、用量统计、角色动作反馈。原云存档、MCP、社交路线均未宣称完成。后续阶段继续独立 handoff 与 troubleshooting。

来源：[DeepSeek 官方调用说明](https://api-docs.deepseek.com/)、[JSON Output](https://api-docs.deepseek.com/guides/json_mode/)、[Chat Completions](https://api-docs.deepseek.com/api/create-chat-completion/)。
