extends Node
## Serial, opt-in prose generation. Original local text and rule-owned rewards stay intact.
signal updated(kind: String, id: String)
var host
var client
var pending: Array = []
var running = false
var active_key = ""
func _init(owner_node): host = owner_node
func _ready():
	client = preload("res://scripts/player_ai.gd").new()
	add_child(client)
static func entry_id(kind: String, entry: Dictionary) -> String:
	return str(entry.get("id", "")) if kind == "mail" else "%d:%s:%d" % [int(entry.get("trip", 0)), entry.get("event_id", "legacy"), int(entry.get("time", 0))]
func find_entry(world, kind: String, id: String) -> Dictionary:
	for entry in world.data.get("travel_mail" if kind == "mail" else "letters", []):
		if entry_id(kind, entry) == id: return entry
	return {}
func request_entry(kind: String, entry: Dictionary, retry: bool = false) -> void:
	if not host.ai_client.enabled or kind not in ["mail", "travel"] or entry.is_empty(): return
	var id = entry_id(kind, entry)
	var target = find_entry(host.world, kind, id)
	if target.is_empty() or target.has("ai_text") or (target.get("ai_attempted", false) and not retry): return
	var key = str(host.world.get_instance_id()) + ":" + kind + ":" + id
	if active_key == key: return
	for job in pending:
		if job.key == key and job.world == host.world: return
	if pending.size() >= 8: return
	pending.append({"world":host.world,"kind":kind,"id":id,"key":key,"epoch":int(host.world.data.memory_epoch),"generation":host.ai_client.generation})
	call_deferred("_pump")
func _pump() -> void:
	if running: return
	running = true
	while not pending.is_empty():
		var job = pending.pop_front()
		if job.world != host.world or not host.ai_client.enabled or job.generation != host.ai_client.generation or job.epoch != int(host.world.data.memory_epoch): continue
		var entry = find_entry(job.world, job.kind, job.id)
		if entry.is_empty() or entry.has("ai_text"): continue
		active_key = job.key
		entry.ai_attempted = true
		job.world.persist()
		var baseline = str(entry.text)
		client.copy_configuration(host.ai_client)
		client.enabled = true
		var city = str(entry.get("destination", "creek"))
		var facts = {"city":job.world.Mail.city_name(city), "stage":"途中，尚未到终点" if job.kind == "mail" else ("忘物折返回家，未到目的地" if str(entry.get("event_id", "")).ends_with("_forgot") else "旅行已结束"), "reassurance":entry.get("reassurance",false), "local_record":baseline.left(1000), "preferences":job.world.preference_lines()}
		var result = await client.reply("请把这段已发生的旅行写成寄给小屋的短文。", facts, "travel_mail" if job.kind == "mail" else "travel_journal")
		if job.world == host.world and host.ai_client.enabled and job.generation == host.ai_client.generation and job.epoch == int(host.world.data.memory_epoch):
			var current = find_entry(job.world, job.kind, job.id)
			if not current.is_empty() and str(current.text) == baseline and result.ok:
				current.ai_text = result.text
				job.world.data.revision += 1
				job.world.persist()
			updated.emit(job.kind, job.id)
		active_key = ""
	running = false
