extends Node
## Register a PackedScene and a setup(scene, context) callback, then await run().
## One fresh scene per cell. No window resize, input replay, or project settings writes.

signal progress(completed: int, total: int, case_id: String)

var states: Array[Dictionary] = []
var busy := false
var cancelled := false
var _snapshot: Dictionary = {}
var _draw_serial := 0

func _ready() -> void:
	RenderingServer.frame_post_draw.connect(_on_draw)

func _on_draw() -> void:
	_draw_serial += 1

func _wait_for_draw() -> bool:
	var next_draw := _draw_serial + 1
	var deadline := Time.get_ticks_msec() + 5000
	while _draw_serial < next_draw:
		if cancelled or Time.get_ticks_msec() > deadline:
			return false
		await get_tree().process_frame
	return not cancelled

func register_state(id: String, scene: PackedScene, setup: Callable) -> Error:
	if busy or id.is_empty() or not id.is_valid_filename() or scene == null or not setup.is_valid():
		return ERR_INVALID_PARAMETER
	for state in states:
		if state.id == id:
			return ERR_ALREADY_EXISTS
	states.append({"id": id, "scene": scene, "setup": setup})
	return OK

func request_cancel() -> void:
	cancelled = true

func settings_snapshot() -> Dictionary:
	return {"locale": TranslationServer.get_locale(), "time_scale": Engine.time_scale,
		"max_fps": Engine.max_fps, "paused": get_tree().paused,
		"window_size": [get_window().size.x, get_window().size.y]}

func _restore() -> void:
	if _snapshot.is_empty():
		return
	TranslationServer.set_locale(_snapshot.locale)
	Engine.time_scale = _snapshot.time_scale
	Engine.max_fps = _snapshot.max_fps
	_snapshot = {}

func _exit_tree() -> void:
	if RenderingServer.frame_post_draw.is_connected(_on_draw):
		RenderingServer.frame_post_draw.disconnect(_on_draw)
	_restore()

func _write_json(path: String, data: Dictionary) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return OK

func run(output_root: String, phase: String, sizes: Array[Vector2i], locales: Array[String], options: Dictionary = {}) -> Dictionary:
	if busy:
		return {"status": "failed", "error": "A capture is already running."}
	if DisplayServer.get_name() == "headless":
		return {"status": "failed", "error": "Screenshots require a real renderer. Remove --headless."}
	if states.is_empty() or sizes.is_empty() or locales.is_empty() or not phase.is_valid_filename():
		return {"status": "failed", "error": "Register states and supply a non-empty matrix and phase."}
	for dimensions in sizes:
		if dimensions.x < 2 or dimensions.y < 2 or dimensions.x > 4096 or dimensions.y > 4096:
			return {"status": "failed", "error": "Sizes must be between 2 and 4096 pixels."}
	for locale in locales:
		if locale.is_empty() or not locale.is_valid_filename():
			return {"status": "failed", "error": "Locale must be a safe non-empty identifier."}
	output_root = ProjectSettings.globalize_path(output_root)
	if not output_root.is_absolute_path():
		return {"status": "failed", "error": "Choose an absolute output folder or user:// path."}
	var folder := output_root.path_join("%s-%s-%s" % [phase, int(Time.get_unix_time_from_system()), Time.get_ticks_usec()])
	var mkdir_error := DirAccess.make_dir_recursive_absolute(folder)
	if mkdir_error != OK:
		return {"status": "failed", "error": "Cannot create output folder (error %s)." % mkdir_error}
	busy = true
	cancelled = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_snapshot = settings_snapshot()
	Engine.time_scale = 1.0
	Engine.max_fps = 60
	var manifest := {"schema": 1, "phase": phase, "status": "capturing", "folder": folder,
		"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(),
		"driver": RenderingServer.get_current_rendering_driver_name(), "device": RenderingServer.get_video_adapter_name(),
		"font": "Godot bundled ThemeDB.fallback_font (engine-pinned)", "seed": 2026, "clock": "2026-01-15T09:00:00Z",
		"total": states.size() * sizes.size() * locales.size(), "captures": [], "error": ""}
	var save_error := _write_json(folder.path_join("manifest.json"), manifest)
	if save_error != OK:
		manifest.status = "failed"
		manifest.error = "Cannot write manifest (error %s)." % save_error
		_restore()
		busy = false
		return manifest
	for state in states:
		for dimensions in sizes:
			for locale in locales:
				if cancelled or not manifest.error.is_empty():
					break
				TranslationServer.set_locale(locale)
				var viewport := SubViewport.new()
				viewport.size = dimensions
				viewport.disable_3d = true
				viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
				add_child(viewport)
				var instance: Node = state.scene.instantiate()
				viewport.add_child(instance)
				var context := {"phase": phase, "locale": locale, "size": dimensions,
					"seed": manifest.seed, "clock": manifest.clock, "data": options.get("data", {}).duplicate(true)}
				var prepared: Variant = await state.setup.call(instance, context)
				if prepared is bool and not prepared:
					manifest.error = "Setup callback rejected state %s." % state.id
				if not is_instance_valid(instance) or not is_instance_valid(viewport):
					manifest.error = "Setup callback must keep its scene and viewport alive."
					if is_instance_valid(viewport):
						viewport.queue_free()
					break
				instance.process_mode = Node.PROCESS_MODE_DISABLED
				# Layout notifications need frames; rendering still runs with processing disabled.
				for frame in range(3):
					await get_tree().process_frame
					if cancelled:
						break
				if not cancelled and manifest.error.is_empty():
					var rendered := await _wait_for_draw()
					if not rendered and not cancelled:
						manifest.error = "Renderer did not finish a frame within 5 seconds."
					if rendered:
						var pixels := viewport.get_texture().get_image()
						var id := "%s__%sx%s__%s" % [state.id, dimensions.x, dimensions.y, locale]
						if pixels == null or pixels.is_empty() or pixels.get_size() != dimensions:
							manifest.error = "Renderer returned an empty or incorrectly sized image for %s." % id
						else:
							pixels.convert(Image.FORMAT_RGBA8)
							var png_error := pixels.save_png(folder.path_join(id + ".png"))
							if png_error != OK:
								manifest.error = "Cannot save PNG (error %s)." % png_error
							else:
								var digest := HashingContext.new()
								digest.start(HashingContext.HASH_SHA256)
								digest.update(pixels.get_data())
								manifest.captures.append({"id": id, "state": state.id, "width": dimensions.x,
									"height": dimensions.y, "locale": locale, "file": id + ".png", "pixel_sha256": digest.finish().hex_encode()})
								save_error = _write_json(folder.path_join("manifest.json"), manifest)
								if save_error != OK:
									manifest.error = "Cannot update manifest (error %s)." % save_error
								progress.emit(manifest.captures.size(), manifest.total, id)
				viewport.queue_free()
				await get_tree().process_frame
	manifest.status = "failed" if not manifest.error.is_empty() else ("cancelled" if cancelled else "completed")
	_restore()
	manifest.restored = settings_snapshot()
	busy = false
	save_error = _write_json(folder.path_join("manifest.json"), manifest)
	if save_error != OK:
		manifest.status = "failed"
		manifest.error = "Cannot finalize manifest (error %s)." % save_error
	return manifest
