extends Node
## Audio is presentation only: no inventory, save, or AI mutations.
const CITIES = {"creek":"10", "market":"11", "hill":"12", "hangzhou":"13", "dali":"14", "tokyo":"15", "istanbul":"16", "paris":"17", "iceland":"18", "shanghai":"19", "dubai":"20", "london":"21", "stockholm":"22", "copenhagen":"22"}
const PAGES = {"田园":"03", "厨房":"04", "远行":"09", "小铺":"11", "收藏":"23", "衣橱":"24", "记忆":"08", "照料":"08", "信箱":"23", "小屋":"02"}
var host
var catalog = {}
var volumes = {"master":0.8, "music":0.65, "ambient":0.4, "effects":0.7}
var muted = false
var config_path = ""
var music_players: Array[AudioStreamPlayer] = []
var ambient_players: Array[AudioStreamPlayer] = []
var cue: AudioStreamPlayer
var music_index = 0
var ambient_index = 0
var music_tween: Tween
var ambient_tween: Tween
var current_track = ""
var current_ambient = ""
var context = "home"
var candidate = "home"
var settled = 0.0
var home_index = 0
var observed_world
var last_trip = 0
var last_mail = ""
var last_cue = ""
var cue_count = 0
var previewing = false
var intro_active = true
var poll = 0.0

func _exit_tree() -> void:
	if music_tween: music_tween.kill()
	if ambient_tween: ambient_tween.kill()
	for value in music_players + ambient_players:
		value.stop()
		value.stream = null
	if is_instance_valid(cue): cue.stop(); cue.stream = null
	observed_world = null

func _init(owner_node = null, path: String = "") -> void:
	host = owner_node
	config_path = path

func _ready() -> void:
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/catalog.json"))
	for bus in ["MossMusic", "MossAmbient", "MossEffects"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	for i in range(2):
		music_players.append(player("MossMusic"))
		ambient_players.append(player("MossAmbient"))
		music_players[i].finished.connect(music_finished.bind(i))
		ambient_players[i].finished.connect(ambient_finished.bind(i))
	cue = player("MossEffects")
	cue.finished.connect(apply_volumes)
	load_settings()
	apply_volumes()
	reset_observation()
	# Export/smoke jobs have no audible surface; validate streams without starting decoders.
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	switch_music("main_theme")

func player(bus: String) -> AudioStreamPlayer:
	var value = AudioStreamPlayer.new()
	value.bus = bus
	add_child(value)
	return value

func load_settings() -> void:
	if config_path.is_empty(): return
	var cfg = ConfigFile.new()
	if cfg.load(config_path) != OK: return
	for key in volumes:
		var value = cfg.get_value("audio", key, volumes[key])
		if (value is float or value is int) and is_finite(float(value)): volumes[key] = clampf(float(value), 0, 1)
	muted = cfg.get_value("audio", "muted", false) == true

func save_settings() -> Error:
	if config_path.is_empty(): return OK
	var cfg = ConfigFile.new()
	for key in volumes: cfg.set_value("audio", key, volumes[key])
	cfg.set_value("audio", "muted", muted)
	return cfg.save(config_path)

func set_volume(key: String, value: float) -> void:
	if volumes.has(key): volumes[key] = clampf(value, 0, 1); apply_volumes()

func apply_volumes() -> void:
	for pair in [["MossMusic", "music"], ["MossAmbient", "ambient"], ["MossEffects", "effects"]]:
		var index = AudioServer.get_bus_index(pair[0])
		var gain = float(volumes.master) * float(volumes[pair[1]])
		if pair[1] == "music" and is_instance_valid(cue) and cue.playing: gain *= 0.55
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(gain, 0.0001)))
		AudioServer.set_bus_mute(index, muted or gain <= 0)

func stream(id: String) -> AudioStream:
	if not catalog.has(id): return null
	return load(catalog[id].path) as AudioStream

func switch_music(id: String) -> void:
	if id == current_track: return
	var audio = stream(id)
	if audio == null: return
	if music_tween: music_tween.kill()
	var outgoing = music_players[music_index]
	music_index = 1 - music_index
	var incoming = music_players[music_index]
	incoming.stop()
	incoming.stream = audio
	incoming.volume_db = -60
	incoming.play()
	current_track = id
	if id != "main_theme": intro_active = false
	music_tween = create_tween().set_parallel(true)
	music_tween.tween_property(outgoing, "volume_db", -60.0, 2.5)
	music_tween.tween_property(incoming, "volume_db", 0.0, 2.5)
	music_tween.chain().tween_callback(outgoing.stop)

func switch_ambient(id: String) -> void:
	if id == current_ambient: return
	if ambient_tween: ambient_tween.kill()
	var outgoing = ambient_players[ambient_index]
	ambient_index = 1 - ambient_index
	var incoming = ambient_players[ambient_index]
	incoming.stop()
	current_ambient = id
	ambient_tween = create_tween().set_parallel(true)
	ambient_tween.tween_property(outgoing, "volume_db", -60.0, 2)
	if not id.is_empty():
		incoming.stream = stream(id)
		incoming.volume_db = -60
		incoming.play()
		ambient_tween.tween_property(incoming, "volume_db", 0.0, 2)
	ambient_tween.chain().tween_callback(outgoing.stop)

func music_finished(index: int) -> void:
	if index != music_index: return
	intro_active = false
	if context == "home" and not previewing:
		home_index = (home_index + 1) % 4
		current_track = ""
		switch_music(["main_theme", "music_02", "music_01", "music_24"][home_index])
	else:
		var repeat = current_track
		current_track = ""
		switch_music(repeat)

func ambient_finished(index: int) -> void:
	if index == ambient_index and not current_ambient.is_empty(): ambient_players[index].play()

func play_cue(id: String) -> void:
	if not catalog.has(id): return
	if cue.playing and (id == last_cue or (last_cue == "welcome" and id == "mail")): return
	cue.stop()
	cue.stream = stream(id)
	last_cue = id
	cue_count += 1
	cue.play()
	apply_volumes()

func reset_observation() -> void:
	if host == null: return
	observed_world = host.world
	last_trip = int(host.world.data.trip_count)
	var letters = host.world.data.get("travel_mail", [])
	last_mail = "" if letters.is_empty() else str(letters[0].id)
	if is_instance_valid(cue): cue.stop(); apply_volumes()

func desired_context(hour: int = -1) -> String:
	if host.postcard_view.visible:
		if host.postcard_view.letter_mode: return "music_23"
		return "music_" + CITIES.get(host.postcard_view.audio_destination, "23")
	if host.home_interactions.book_panel.visible: return "music_07"
	if host.life_panel.visible: return "music_" + PAGES.get(host.life_panel.page, "02")
	if host.world.data.weather.kind == "rainy": return "music_05"
	if hour < 0: hour = Time.get_datetime_dict_from_system().hour
	if hour >= 21 or hour < 6: return "music_06"
	return "home"

func desired_ambient() -> String:
	if host.postcard_view.visible:
		match host.postcard_view.audio_destination:
			"creek", "hangzhou", "dali": return "stream"
			"hill", "iceland": return "wind"
			_: return ""
	if host.world.data.weather.kind == "rainy": return "rain"
	if host.life_panel.visible and host.life_panel.page == "田园": return "birds"
	if host.world.data.weather.kind == "cloudy": return "wind"
	return "forest"

func preview(id: String) -> void:
	previewing = true
	switch_music(id)

func resume_scene() -> void:
	previewing = false
	context = desired_context()
	candidate = context
	settled = 0
	switch_music("main_theme" if context == "home" else context)

func _process(delta: float) -> void:
	if host == null: return
	poll += delta
	if poll < 0.5: return
	var step = poll
	poll = 0
	if observed_world != host.world: reset_observation()
	var trip = int(host.world.data.trip_count)
	var letters = host.world.data.get("travel_mail", [])
	var mail = "" if letters.is_empty() else str(letters[0].id)
	if trip > last_trip: play_cue("welcome")
	elif mail != last_mail and not mail.is_empty(): play_cue("mail")
	last_trip = trip
	last_mail = mail
	var desired = desired_context()
	# Keep preview and the underlying scene while adjusting settings.
	if host.settings_panel.visible: return
	if previewing: resume_scene()
	if desired != candidate: candidate = desired; settled = 0
	else: settled += step
	if candidate != context and settled >= 4 and not (intro_active and candidate in ["home", "music_05", "music_06"]):
		context = candidate
		switch_music("main_theme" if context == "home" else context)
	switch_ambient(desired_ambient())
