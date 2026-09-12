extends "res://scripts/main.gd"

func shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(path) == OK)

func qa_flow() -> void:
	assert(world.save_path.is_empty() and audio_manager.config_path.is_empty())
	var audio = audio_manager
	assert(audio.catalog.size() == 33)
	for id in audio.catalog:
		var sound = audio.stream(id)
		assert(sound != null and sound.get_length() > 1, id)
	assert(audio.catalog.main_theme.source.ends_with("苔间小屋 主旋律 Main theme.mp3"))
	assert(audio.current_track == "main_theme")
	var capture_effect = AudioEffectCapture.new()
	AudioServer.add_bus_effect(0, capture_effect)
	await get_tree().create_timer(3).timeout
	var peak = 0.0
	for frame in capture_effect.get_buffer(capture_effect.get_frames_available()):
		peak = maxf(peak, maxf(absf(frame.x), absf(frame.y)))
	assert(peak > 0.00001, "Mixer must produce non-silent PCM")
	audio.set_process(false)
	settings_panel.open()
	await qa_click(settings_panel.actions.audio_tab)
	settings_panel.actions.audio_music.value = 35
	assert(is_equal_approx(audio.volumes.music, 0.35))
	await qa_click(settings_panel.actions.audio_mute)
	assert(AudioServer.is_bus_mute(AudioServer.get_bus_index("MossMusic")))
	audio.config_path = "res://artifacts/g14-audio-settings.cfg"
	await qa_click(settings_panel.actions.audio_save)
	audio.muted = false
	audio.volumes.music = 0.9
	audio.load_settings()
	assert(audio.muted and is_equal_approx(audio.volumes.music, 0.35))
	audio.muted = false
	audio.apply_volumes()
	settings_panel.audio_page()
	await shot("res://artifacts/g14-audio-settings.png")
	await qa_click(settings_panel.actions.audio_preview)
	assert(audio.previewing and audio.current_track == "main_theme")
	settings_panel.hide()
	audio.resume_scene()
	for page_name in ["田园", "厨房", "远行", "收藏", "记忆"]:
		life_panel.open(page_name)
		for i in range(12): audio._process(0.5)
		assert(audio.current_track == "main_theme")
	life_panel.hide()
	world.data.weather.kind = "rainy"
	audio._process(6)
	assert(audio.current_track == "main_theme" and audio.current_ambient == "rain")
	postcard_view.audio_destination = "iceland"
	postcard_view.show()
	audio._process(6)
	assert(audio.current_track == "main_theme")
	postcard_view.hide()
	# Two complete shuffle rounds, each track exactly once, no boundary repeat.
	for round_index in range(2):
		var seen = []
		for i in range(24):
			var previous = audio.current_track
			var next = audio.next_album_track()
			assert(next != previous and next not in seen and next != "main_theme")
			seen.append(next)
			audio.current_track = next
		assert(seen.size() == 24)
	audio.current_track = "main_theme"
	audio.queue_travel_theme("iceland")
	audio.queue_travel_theme("creek")
	assert(audio.pending_track.is_empty())
	audio.queue_travel_theme("iceland")
	audio.queue_travel_theme("iceland")
	assert(audio.pending_track == "music_18" and audio.current_track == "main_theme")
	# Exercise the real AudioStreamPlayer.finished signal without waiting several minutes.
	audio.music_players[audio.music_index].seek(audio.music_players[audio.music_index].stream.get_length() - 0.15)
	await get_tree().create_timer(0.7).timeout
	assert(audio.current_track == "music_18" and audio.pending_track.is_empty())
	await get_tree().create_timer(2.6).timeout
	audio.music_players[audio.music_index].seek(audio.music_players[audio.music_index].stream.get_length() - 0.15)
	await get_tree().create_timer(0.7).timeout
	assert(audio.current_track != "music_18" and audio.current_track.begins_with("music_"))
	# Interrupted crossfades have bounded players and no stale callback stopping the new song.
	audio.switch_music("music_15")
	audio.switch_music("music_18")
	await get_tree().create_timer(3).timeout
	assert(audio.music_players[audio.music_index].playing)
	assert(not audio.music_players[1 - audio.music_index].playing)
	var before = world.data.duplicate(true)
	audio.play_cue("mail")
	var count = audio.cue_count
	audio.play_cue("mail")
	assert(audio.cue_count == count)
	assert(world.data == before)
	audio.cue.stop()
	audio.apply_volumes()
	# Real journey return and first discovery use real game commands in an isolated world.
	world = World.new()
	world.release_timing = true
	world.rng.seed = 2
	world.data.foods.potato_box = 8
	world.data.rare_misses.iceland = 2
	audio.reset_observation()
	world.command("travel", {"destination":"iceland", "food":"potato_box"})
	audio.current_track = "music_02"
	audio._process(0.5)
	assert(audio.pending_track == "music_18" and audio.current_track == "music_02")
	var schedule = world.data.trip_snapshot.mail_schedule.duplicate(true)
	assert(not schedule.is_empty())
	world.advance(schedule[0].time)
	audio._process(0.5)
	assert(audio.last_cue == "mail")
	world.advance(world.data.trip_end + 1)
	audio._process(0.5)
	assert(audio.last_cue == "welcome")
	parcel_view.open()
	await qa_click(parcel_view.open_button)
	await get_tree().create_timer(0.45).timeout
	assert(audio.last_cue == "discover")
	parcel_view.hide()
	count = audio.cue_count
	world = World.new()
	audio._process(0.5)
	assert(audio.cue_count == count and not audio.cue.playing)
	life_panel.hide()
	get_window().size = Vector2i(960,600)
	settings_panel.open()
	settings_panel.audio_page()
	await get_tree().create_timer(0.3).timeout
	await shot("res://artifacts/g14-audio-settings-960.png")
	AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0)-1)
	print("G15_AUDIO_PASS: 33 decoded streams; main theme; mixer peak=", peak, "; volumes/mute/persistence; 24-track shuffle rounds; menu/weather continuity; queued theme; real finished signal; crossfade; mail/return/reveal; isolated saves; 960px")
	get_tree().quit()
