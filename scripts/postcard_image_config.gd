extends RefCounted
## Future image-provider seam. This phase saves config/builds payloads; never sends HTTP.
var config_path = "user://ai-image-settings.cfg"
var secret_path = "user://ai-key-image.enc"
var endpoint = ""
var model = ""
var api_key = ""
var image_size = "1024x1024"
func normalize(value: String) -> String:
	var url = value.strip_edges().trim_suffix("/")
	if url.is_empty(): return ""
	if url.find("/", url.find("://") + 3) < 0: return url + "/v1/images/generations"
	if url.ends_with("/v1"): return url + "/images/generations"
	return url
func load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(config_path) != OK: return
	endpoint = str(config.get_value("image", "endpoint", ""))
	model = str(config.get_value("image", "model", ""))
	image_size = str(config.get_value("image", "size", "1024x1024"))
func configure(url: String, name: String, key: String, size: String, remember: bool, password: String) -> String:
	var validator = preload("res://scripts/player_ai.gd").new()
	var problem = validator.validation(url, name)
	validator.free()
	if not problem.is_empty(): return problem
	if size not in ["1024x1024", "1536x1024", "1024x1536"]: return "请选择预留画幅。"
	if "\n" in key or "\r" in key: return "密钥不能包含换行。"
	if remember and (password.length() < 8 or key.is_empty()): return "保存密钥需要至少8位口令与非空Key。"
	url = normalize(url)
	var config = ConfigFile.new()
	config.set_value("image", "endpoint", url)
	config.set_value("image", "model", name.strip_edges())
	config.set_value("image", "size", size)
	if config.save(config_path) != OK: return "绘图配置保存失败。"
	if remember:
		var secret = ConfigFile.new()
		secret.set_value("key", "value", key)
		secret.set_value("key", "endpoint", url)
		if secret.save_encrypted_pass(secret_path, password) != OK: return "绘图Key加密保存失败。"
	elif FileAccess.file_exists(secret_path):
		if DirAccess.remove_absolute(secret_path) != OK: return "无法清除旧绘图Key文件。"
	endpoint = url; model = name.strip_edges(); api_key = key.strip_edges(); image_size = size
	return ""
func unlock(password: String) -> bool:
	var config = ConfigFile.new()
	if config.load_encrypted_pass(secret_path, password) != OK or config.get_value("key", "endpoint", "") != endpoint: return false
	api_key = str(config.get_value("key", "value", ""))
	return not api_key.is_empty()
func build_payload(city: String) -> Dictionary:
	return {"model":model, "size":image_size, "n":1, "prompt":"原创青蛙苔苔的旅行明信片插画，温暖水彩，轻松治愈，无文字。地点：" + city.left(80)}
func capability() -> Dictionary:
	return {"implemented":false, "message":"接口配置已预留；当前仍使用预绘明信片，不发起绘图请求。"}
