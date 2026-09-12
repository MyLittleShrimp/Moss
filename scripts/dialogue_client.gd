extends Node
## Only calls a loopback proxy. No provider key is stored in the game.
var busy = false
var enabled = false
var status_text = "本地规则对话"
var endpoint = "http://127.0.0.1:8765/dialogue"
var token_path = "res://.local/proxy-token"

func reply(text: String, facts: Dictionary, purpose: String = "dialogue") -> Dictionary:
	if not enabled or busy:
		return {"ok": false}
	if not FileAccess.file_exists(token_path):
		status_text = "代理未启动 · 本地回退"
		return {"ok": false}
	var token = FileAccess.get_file_as_string(token_path).strip_edges()
	if token.length() < 32:
		status_text = "代理配置异常 · 本地回退"
		return {"ok": false}
	busy = true
	status_text = "苔苔正在想怎么说…"
	var request = HTTPRequest.new()
	request.timeout = 8.0
	request.body_size_limit = 8192
	add_child(request)
	var err = request.request(endpoint,
		["Content-Type: application/json", "Authorization: Bearer " + token],
		HTTPClient.METHOD_POST, JSON.stringify({"text": text, "facts": facts, "purpose": purpose}))
	if err != OK:
		request.queue_free()
		busy = false
		status_text = "连接失败 · 本地回退"
		return {"ok": false}
	var response = await request.request_completed
	request.queue_free()
	busy = false
	var parser = JSON.new()
	if response[0] == HTTPRequest.RESULT_SUCCESS and response[1] == 200 and parser.parse(response[3].get_string_from_utf8()) == OK:
		var body = parser.data
		if body is Dictionary and body.get("source") == "llm" and body.get("utterance") is String and body.utterance.length() > 0 and body.utterance.length() <= 240:
			status_text = "本条回复来自 LLM"
			return {"ok": true, "text": body.utterance}
	status_text = "AI 暂不可用 · 本地回退"
	return {"ok": false}
