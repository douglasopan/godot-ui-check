extends RefCounted
## Portable local review: embedded PNGs, no server, CDN, or network.

static func write_pair(before: Dictionary, after: Dictionary, output_root: String) -> Dictionary:
	if before.get("status") != "completed" or after.get("status") != "completed":
		return {"error": "Both runs must complete before comparison."}
	for key in ["engine", "renderer", "driver", "device", "font", "seed", "clock"]:
		if before.get(key) != after.get(key):
			return {"error": "Capture environments differ: %s." % key}
	var pairs: Array[Dictionary] = []
	var changed := 0
	for original in before.captures:
		var candidate: Dictionary = {}
		for entry in after.captures:
			if entry.id == original.id:
				candidate = entry
		if candidate.is_empty():
			return {"error": "Missing after capture: %s." % original.id}
		var before_path: String = before.folder.path_join(original.file)
		var after_path: String = after.folder.path_join(candidate.file)
		var left := Image.load_from_file(before_path)
		var right := Image.load_from_file(after_path)
		if left == null or right == null or left.is_empty() or right.is_empty() or left.get_size() != right.get_size():
			return {"error": "Missing, invalid, or mismatched PNG: %s." % original.id}
		left.convert(Image.FORMAT_RGBA8)
		right.convert(Image.FORMAT_RGBA8)
		var a := left.get_data()
		var b := right.get_data()
		var count := 0
		for pixel in range(0, a.size(), 4):
			if a[pixel] != b[pixel] or a[pixel + 1] != b[pixel + 1] or a[pixel + 2] != b[pixel + 2] or a[pixel + 3] != b[pixel + 3]:
				count += 1
		var status := "changed" if count > 0 else "unchanged"
		changed += int(count > 0)
		var pair: Dictionary = original.duplicate(true)
		pair.erase("file")
		pair.status = status
		pair.changed_pixels = count
		pair.changed_percent = snappedf(100.0 * count / (left.get_width() * left.get_height()), 0.001)
		pair.before = "data:image/png;base64," + Marshalls.raw_to_base64(FileAccess.get_file_as_bytes(before_path))
		pair.after = "data:image/png;base64," + Marshalls.raw_to_base64(FileAccess.get_file_as_bytes(after_path))
		pairs.append(pair)
	if pairs.size() != after.captures.size():
		return {"error": "Capture matrices differ."}
	var data := {"schema": 1, "title": "Trail Supply / layout review", "changed": changed,
		"engine": before.engine, "renderer": before.renderer, "driver": before.driver, "device": before.device,
		"font": before.font, "seed": before.seed, "clock": before.clock,
		"before_folder": before.folder, "after_folder": after.folder, "pairs": pairs}
	var template := FileAccess.get_file_as_string("res://addons/ui_check/gallery.html")
	if template.is_empty():
		return {"error": "Gallery template is missing."}
	# Escape '<' so even user-supplied identifiers cannot terminate the JSON script.
	var html := template.replace("__REPORT_DATA__", JSON.stringify(data).replace("<", "\\u003c"))
	var folder := ProjectSettings.globalize_path(output_root).path_join("review-%s-%s" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()])
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		return {"error": "Cannot create review folder."}
	var file := FileAccess.open(folder.path_join("index.html"), FileAccess.WRITE)
	if file == null:
		return {"error": "Cannot write gallery."}
	file.store_string(html)
	file.close()
	for pair in pairs:
		pair.erase("before")
		pair.erase("after")
	var json := FileAccess.open(folder.path_join("report.json"), FileAccess.WRITE)
	if json == null:
		return {"error": "Cannot write report JSON."}
	json.store_string(JSON.stringify(data, "\t"))
	json.close()
	return {"path": folder.path_join("index.html"), "json": folder.path_join("report.json"), "changed": changed, "total": pairs.size(), "error": ""}
