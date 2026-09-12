# 国内模型接入准备

## G4 当前配置（优先于下文 G3 历史说明）

DeepSeek 已实际接通，配置模板为 `server/deepseek.example.json`。官方地址 `https://api.deepseek.com/chat/completions`，模型 `deepseek-v4-flash`，JSON Object 输出，thinking disabled。依据 [DeepSeek 首次调用](https://api-docs.deepseek.com/) 和 [JSON Output](https://api-docs.deepseek.com/guides/json_mode/)。

本机 `.local/ai.json` 已启用；密钥来源优先 `DEEPSEEK_API_KEY` 环境变量，否则读取 `.local/deepseek-key.dpapi`，由当前 Windows 用户解密。文件不含明文密钥，不能直接迁移到另一用户/机器；换机重新配置环境变量或当地加密存储。

日常双击 `StartGame.cmd`，代理自动按需启动且不重复启动；游戏内打开 AI 开关后才发请求。`StopAIProxy.cmd` 通过本地令牌请求关闭代理，不操作其他 Python 进程。手动代理窗口入口仍保留。

`python server/live_check.py` 是明确会调用供应商的真实测试，使用合成文字并计入日预算，非普通无付费回归测试。完整模型质量和 token 账单统计尚未完成。

以下保留 G3 的适配范围与配置说明作为参考，原“服务未定”状态已由 G4 更新。

用户选择优先国内模型，具体服务名称尚待提供。当前完成通用代理适配，**未声称已支持或实测任何特定国内服务**；默认不开启付费请求。

## 当前接口

Godot → 本机 `127.0.0.1:8765/dialogue` → 供应商 HTTPS 接口。默认兼容 `chat_completions` 风格（messages/max_tokens/choices）；另保留 `responses` 适配。不同服务的字段、JSON 模式、鉴权、模型权限和地域可用性需要在选定服务后复核。

## 提供服务名称后需要的配置

1. 将 `server/ai.example.json` 复制为 `.local/ai.json`，不提交该本地目录。
2. 设置完整 HTTPS `endpoint`、模型 `model` 与 `protocol`；`enabled` 改为 true 才可调用。`json_mode` 仅在供应商确认支持时启用。
3. 在启动代理的本地终端设置 `MOSS_LLM_API_KEY` 环境变量；不要在聊天里提供密钥，不写进 Godot 脚本或配置 JSON。
4. 在同一终端执行 `python server/proxy.py`，或从已配置环境双击 `StartAIProxy.cmd`。窗口会显示是否具备配置，但不显示密钥。
5. 启动游戏，打开顶部「启用 AI 对话」；输入一句普通纸条。只有有效上游结果才标为 LLM，本地规则回复会明确标注。

没有配置时仍可游玩。默认启动器不自动启动代理，也不默默启用 AI 开关。代理关闭后，客户端自动使用规则回复。关闭代理窗口可停止服务。

## 约束与数据

- 客户端请求只有本次文字、宠物名称、是否出门、目的地、雨声偏好与最近事件标题；没有完整历史聊天或存档。
- 代理不写游戏存档；响应只有 `utterance`、`emotion`。带 action、奖励或额外字段的结果被拒绝。
- 普通文字的事实准确性目前依靠提示约束，并未实现语义事实证明；模型仍可能说错，后续供应商联调必须评测。
- 明确的偏好保存/纠正/遗忘在本地规则执行，不交给模型自动改记忆。
- 上游 socket 超时 6 秒；客户端等待最多 8 秒；无自动重试；返回时若游戏 revision 改变则丢弃旧回复。
- 每分钟最多 6 次、每日 UTC 最多 100 次尝试；日计数保存在 `.local/usage.json`，重启保留。调用失败也消耗尝试额度，避免循环重试。
- 仅监听 loopback，随机本地访问令牌放在 `.local/proxy-token`，拒绝带浏览器 Origin 的请求与错误令牌。供应商 HTTPS 重定向被拒绝，避免把 Authorization 转发到其他站点。
- 不记录对话或上游错误正文。预算只记录日期和次数；这不是完整按 token 计费账单。
- 这是个人电脑单用户开发代理，不是可直接公网部署的生产后端。

## 验证证据

`python tests/test_proxy.py` 使用模拟供应商验证鉴权、Origin、非法字段、输出长度、失败、预算和 Godot 真实 HTTP 通信。模拟返回里的 source=llm 只用于测试协议，不能作为真实模型接入成功的证据。

真实供应商验收待办：接口字段、模型可用性、JSON输出、中文风格、网络延迟、429/401/超时、实际 token 费用和删除/日志政策。供应商未确定前，不填猜测的 endpoint 或模型名。

参考：Responses 分支依据 [OpenAI 文本生成](https://developers.openai.com/api/docs/guides/text) 与 [结构化输出](https://developers.openai.com/api/docs/guides/structured-outputs)；这些资料不证明任何国内厂商的兼容性。
