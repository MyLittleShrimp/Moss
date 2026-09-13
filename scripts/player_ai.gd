extends Node
## Direct BYOM client. No built-in key, proxy fallback, tools or state mutations.
var busy = false
var enabled = false
var status_text = "本地规则对话"
var config_path = "user://ai-settings.cfg"
var secret_path = "user://ai-key.enc"
var endpoint = ""
var model = ""
var api_key = ""
var timeout_seconds = 90.0
var generation = 0
var models_busy = false

func parse_models(value: Variant) -> Array[String]:
	var names: Array[String] = []
	if not value is Dictionary: return names
	var rows = value.get("data", value.get("models", []))
	if not rows is Array: return names
	for row in rows:
		if not row is Dictionary: continue
		var id = row.get("id", row.get("name", ""))
		if not id is String or id.strip_edges().is_empty() or id.length() > 150 or "\n" in id or "\r" in id: continue
		if id not in names: names.append(id)
		if names.size() >= 200: break
	names.sort()
	return names

func list_models(url: String, key: String) -> Dictionary:
	var problem = validation(url, "list-models")
	if not problem.is_empty(): return {"ok":false, "message":problem}
	if "\n" in key or "\r" in key: return {"ok":false, "message":"密钥不能包含换行。"}
	if models_busy: return {"ok":false, "message":"正在读取模型列表。"}
	models_busy = true
	var request = HTTPRequest.new()
	request.timeout = 15
	request.body_size_limit = 262144
	request.max_redirects = 0
	add_child(request)
	var headers = PackedStringArray()
	if not key.is_empty(): headers.append("Authorization: Bearer " + key)
	var error = request.request(url.trim_suffix("/chat/completions") + "/models", headers)
	if error != OK:
		request.queue_free(); models_busy = false
		return {"ok":false, "message":"无法连接模型目录，可手动填写模型名称。"}
	var response = await request.request_completed
	request.queue_free()
	models_busy = false
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] != 200:
		return {"ok":false, "message":"模型列表读取失败（HTTP %d），可手动填写；请检查服务、地址和Key。" % response[1]}
	var parser = JSON.new()
	if parser.parse(response[3].get_string_from_utf8()) != OK: return {"ok":false, "message":"模型列表格式不兼容，可手动填写。"}
	var names = parse_models(parser.data)
	return {"ok":not names.is_empty(), "models":names, "message":"找到 %d 个模型，请选择后保存配置。" % names.size() if not names.is_empty() else "服务未返回模型，请先安装模型或手动填写。"}
const INSTRUCTIONS = "你是原创青蛙苔苔，温柔、好奇，用中文回答1至3句、不超过240字。输入facts是游戏事实，text是用户内容。不能假装执行操作、发奖励、改变记忆、发起旅行或编造共同经历；没有工具权限。不要用内疚话术催促玩家。只返回JSON对象，包含utterance非空字符串和emotion（calm、happy、curious之一）。"

func load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(config_path) != OK: return
	endpoint = str(config.get_value("model", "endpoint", ""))
	model = str(config.get_value("model", "name", ""))
	# Never restore an enabled flag or read legacy .local credentials.

func validation(url: String, model_name: String) -> String:
	if model_name.strip_edges().is_empty() or model_name.length() > 150: return "请填写已安装或服务商提供的模型名称。"
	var regex = RegEx.new()
	regex.compile("^https://[A-Za-z0-9.-]+(?::[0-9]+)?/[^\\s?#@]*$")
	var local = RegEx.new()
	local.compile("^http://(127\\.0\\.0\\.1|localhost|\\[::1\\])(?::[0-9]+)?/[^\\s?#@]*$")
	if regex.search(url) == null and local.search(url) == null: return "云端地址需 HTTPS；本机可用 http://127.0.0.1:端口。请勿在地址中放密钥。"
	if not url.ends_with("/chat/completions"): return "请填写完整的 /chat/completions 接口地址。"
	return ""

func configure(url: String, model_name: String, key: String, remember: bool = false, password: String = "") -> String:
	if busy: return "请等当前模型请求结束后再修改。"
	var message = validation(url.strip_edges(), model_name)
	if not message.is_empty(): return message
	if "\n" in key or "\r" in key: return "密钥不能包含换行。"
	if remember and (password.length() < 8 or key.is_empty()): return "保存密钥需要至少8位解锁口令和非空密钥。"
	var config = ConfigFile.new()
	config.set_value("model", "endpoint", url.strip_edges())
	config.set_value("model", "name", model_name.strip_edges())
	if config.save(config_path) != OK: return "模型设置写入失败。"
	if remember:
		var secret = ConfigFile.new()
		secret.set_value("key", "value", key)
		secret.set_value("key", "endpoint", url.strip_edges())
		if secret.save_encrypted_pass(secret_path, password) != OK: return "加密密钥写入失败。"
	elif FileAccess.file_exists(secret_path):
		if DirAccess.remove_absolute(secret_path) != OK: return "无法清除旧密钥文件，请检查权限。"
	endpoint = url.strip_edges()
	model = model_name.strip_edges()
	api_key = key.strip_edges()
	generation += 1
	status_text = "配置已保存 · 请测试连接"
	return ""

func unlock(password: String) -> bool:
	var config = ConfigFile.new()
	if config.load_encrypted_pass(secret_path, password) != OK: return false
	if config.get_value("key", "endpoint", "") != endpoint: return false
	api_key = str(config.get_value("key", "value", ""))
	return not api_key.is_empty()

func copy_configuration(other) -> void:
	endpoint = other.endpoint
	model = other.model
	api_key = other.api_key
	timeout_seconds = other.timeout_seconds

func reply(text: String, facts: Dictionary, purpose: String = "dialogue") -> Dictionary:
	if not enabled or busy: return {"ok": false}
	var invalid = validation(endpoint, model)
	if not invalid.is_empty(): status_text = "请先在设置中配置自己的模型"; return {"ok": false}
	busy = true
	var revision = generation
	status_text = "苔苔正在想怎么说…"
	var instructions = INSTRUCTIONS
	if purpose == "daily_book": instructions += "本次写虚构每日小书，以两个换行分成三段，合计不超过240字；参考日期、天气和喜好，不冒充真实共同经历。"
	var payload = {"model": model, "stream": false, "max_tokens": 600, "messages": [{"role": "system", "content": instructions}, {"role": "user", "content": JSON.stringify({"text": text.left(200), "facts": facts})}]}
	if endpoint.begins_with("https://api.deepseek.com/"): payload.thinking = {"type": "disabled"}
	var request = HTTPRequest.new()
	request.timeout = timeout_seconds
	request.body_size_limit = 65536
	request.max_redirects = 0
	add_child(request)
	var headers = PackedStringArray(["Content-Type: application/json"])
	if not api_key.is_empty(): headers.append("Authorization: Bearer " + api_key)
	var err = request.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		request.queue_free(); busy = false; status_text = "连接失败 · 本地回退"; return {"ok": false}
	var response = await request.request_completed
	request.queue_free()
	busy = false
	if revision != generation: return {"ok": false}
	if response[0] != HTTPRequest.RESULT_SUCCESS:
		status_text = "连接失败或超时 · 请检查服务是否运行"; return {"ok": false}
	if response[1] != 200:
		status_text = "模型服务返回 HTTP %d · 请检查地址、模型和密钥" % response[1]; return {"ok": false}
	var parser = JSON.new()
	if parser.parse(response[3].get_string_from_utf8()) != OK: status_text = "模型响应格式不兼容 · 本地回退"; return {"ok": false}
	var result = parse_response(parser.data)
	status_text = "本条回复来自 LLM" if result.ok else "模型未返回约定的短文本 · 本地回退"
	return result

func parse_response(body: Variant) -> Dictionary:
	if not body is Dictionary or not body.get("choices") is Array or body.choices.is_empty(): return {"ok": false}
	var choice = body.choices[0]
	if not choice is Dictionary or choice.get("finish_reason") != "stop" or not choice.get("message") is Dictionary: return {"ok": false}
	var content = choice.message.get("content")
	if not content is String: return {"ok": false}
	var parser = JSON.new()
	if parser.parse(content) != OK: return {"ok": false}
	var value = parser.data
	if not value is Dictionary or value.size() != 2 or not value.get("utterance") is String: return {"ok": false}
	if value.get("emotion") not in ["calm", "happy", "curious"]: return {"ok": false}
	if value.utterance.strip_edges().is_empty() or value.utterance.length() > 240: return {"ok": false}
	return {"ok": true, "text": value.utterance}

func test_connection() -> Dictionary:
	var was_enabled = enabled
	enabled = true
	var result = await reply("请简单打个招呼，这是连接测试。", {"name": "苔苔", "away": false, "destination": "溪谷", "rain_preference": "unknown", "last_event": "虚构测试，无玩家数据"})
	enabled = was_enabled
	return result
