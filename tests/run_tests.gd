extends SceneTree

const Runner = preload("res://addons/ui_check/capture_runner.gd")
const Suite = preload("res://demo/suite.gd")
const Report = preload("res://addons/ui_check/report.gd")
var results: Array[Dictionary] = []
var failures := 0
var output_root := "user://test-evidence"
var logic_only := false

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	for i in range(args.size()):
		if args[i] == "--output" and i + 1 < args.size():
			output_root = args[i + 1]
		if args[i] == "--logic-only":
			logic_only = true
	call_deferred("_run")

func check(name: String, passed: bool, details: String = "") -> void:
	results.append({"test": name, "passed": passed, "details": details})
	if not passed:
		failures += 1
	print("%s %s %s" % ["PASS" if passed else "FAIL", name, details])

func hashes_equal(a: Dictionary, b: Dictionary) -> bool:
	if a.get("captures", []).size() != b.get("captures", []).size():
		return false
	for i in range(a.captures.size()):
		if a.captures[i].id != b.captures[i].id or a.captures[i].pixel_sha256 != b.captures[i].pixel_sha256:
			return false
	return true

func _cancel_later(runner: Node) -> void:
	await create_timer(0.2, true, false, true).timeout
	runner.request_cancel()

func _run() -> void:
	output_root = ProjectSettings.globalize_path(output_root).path_join("tests-%s-%s" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(output_root)
	var runner := Runner.new()
	root.add_child(runner)
	Suite.register(runner)
	check("two registered callbacks", runner.states.size() == 2)
	check("duplicate state rejected", runner.register_state("supply", Suite.SCENE, func(_s, _c): pass) == ERR_ALREADY_EXISTS)
	check("unsafe state rejected", runner.register_state("../escape", Suite.SCENE, func(_s, _c): pass) == ERR_INVALID_PARAMETER)
	check("missing callback rejected", runner.register_state("missing", Suite.SCENE, Callable()) == ERR_INVALID_PARAMETER)
	var original := runner.settings_snapshot()
	if logic_only:
		var dummy: Dictionary = await runner.run(output_root, "before", Suite.SIZES, Suite.LOCALES)
		check("headless capture explicitly rejected", dummy.get("status") == "failed" and "real renderer" in dummy.get("error", ""))
		check("headless path preserves settings", runner.settings_snapshot() == original)
	else:
		var invalid: Dictionary = await runner.run(output_root, "before", [Vector2i(0, 720)], Suite.LOCALES)
		check("invalid dimensions rejected", invalid.get("status") == "failed")
		TranslationServer.set_locale("fr")
		Engine.time_scale = 0.75
		Engine.max_fps = 37
		paused = true
		var prior := runner.settings_snapshot()
		var before: Dictionary = await runner.run(output_root, "before", Suite.SIZES, Suite.LOCALES)
		check("before renders eight cases", before.get("status") == "completed" and before.get("captures", []).size() == 8, before.get("error", ""))
		check("success restores locale/time/FPS/pause/window", runner.settings_snapshot() == prior)
		var after: Dictionary = await runner.run(output_root, "after", Suite.SIZES, Suite.LOCALES)
		check("after renders eight cases", after.get("status") == "completed" and after.get("captures", []).size() == 8, after.get("error", ""))
		var again: Dictionary = await runner.run(output_root, "before", Suite.SIZES, Suite.LOCALES)
		check("before repeated pixels identical", hashes_equal(before, again))
		var after_again: Dictionary = await runner.run(output_root, "after", Suite.SIZES, Suite.LOCALES)
		check("after repeated pixels identical", hashes_equal(after, after_again))
		check("repeat uses unique output folders", before.get("folder") != again.get("folder") and after.get("folder") != after_again.get("folder"))
		var cancel_after_first := func(count: int, _total: int, _id: String):
			if count == 1:
				runner.request_cancel()
		runner.progress.connect(cancel_after_first)
		var cancelled: Dictionary = await runner.run(output_root, "before", Suite.SIZES, Suite.LOCALES)
		runner.progress.disconnect(cancel_after_first)
		check("cancel keeps partial evidence and status", cancelled.get("status") == "cancelled" and cancelled.get("captures", []).size() == 1)
		check("cancel restores settings", runner.settings_snapshot() == prior and not runner.busy)
		var early := Runner.new()
		root.add_child(early)
		early.register_state("early", Suite.SCENE, func(_s, _c): early.call_deferred("request_cancel"))
		var early_result: Dictionary = await early.run(output_root, "early", Suite.SIZES, Suite.LOCALES)
		check("cancel during setup/settle restores settings", early_result.get("status") == "cancelled" and early_result.captures.is_empty() and early.settings_snapshot() == prior)
		early.queue_free()
		var rendering_enabled := RenderingServer.render_loop_enabled
		RenderingServer.render_loop_enabled = false
		call_deferred("_cancel_later", runner)
		var no_frame_cancel: Dictionary = await runner.run(output_root, "before", Suite.SIZES, Suite.LOCALES)
		check("cancel while renderer is stopped remains responsive", no_frame_cancel.get("status") == "cancelled" and runner.settings_snapshot() == prior)
		var no_frame_timeout: Dictionary = await runner.run(output_root, "before", Suite.SIZES, Suite.LOCALES)
		RenderingServer.render_loop_enabled = rendering_enabled
		check("stopped renderer times out and restores settings", no_frame_timeout.get("status") == "failed" and "5 seconds" in no_frame_timeout.get("error", "") and runner.settings_snapshot() == prior)
		var blocked_file := output_root.path_join("not-a-folder")
		var blocker := FileAccess.open(blocked_file, FileAccess.WRITE)
		blocker.store_string("test fixture")
		blocker.close()
		var blocked: Dictionary = await runner.run(blocked_file, "before", Suite.SIZES, Suite.LOCALES)
		check("output IO failure is explicit and preserves settings", blocked.get("status") == "failed" and runner.settings_snapshot() == prior and not runner.busy)
		var recovered: Dictionary = await runner.run(output_root, "before", Suite.SIZES, Suite.LOCALES)
		check("run after cancel succeeds with same pixels", recovered.get("status") == "completed" and hashes_equal(before, recovered))
		var rejected_runner := Runner.new()
		root.add_child(rejected_runner)
		rejected_runner.register_state("bad", Suite.SCENE, func(_s, _c): return false)
		var rejected: Dictionary = await rejected_runner.run(output_root, "bad", Suite.SIZES, Suite.LOCALES)
		check("setup failure reported and settings restored", rejected.get("status") == "failed" and rejected_runner.settings_snapshot() == prior and not rejected_runner.busy)
		rejected_runner.queue_free()
		var report := Report.write_pair(before, after, output_root)
		check("portable gallery and JSON generated", report.get("error", "").is_empty() and FileAccess.file_exists(report.get("path", "")), report.get("path", report.get("error", "")))
		check("intentional changes detected", report.get("changed", 0) == 8)
		var identical := Report.write_pair(before, again, output_root)
		check("identical runs have zero changed pairs", identical.get("changed", -1) == 0)
		var mismatched := after.duplicate(true)
		mismatched.engine = "different-version"
		check("mixed engine comparison rejected", not Report.write_pair(before, mismatched, output_root).get("error", "").is_empty())
		var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(cancelled.folder.path_join("manifest.json")))
		check("cancelled manifest persisted", manifest is Dictionary and manifest.get("status") == "cancelled")
		paused = false
		TranslationServer.set_locale(original.locale)
		Engine.time_scale = original.time_scale
		Engine.max_fps = original.max_fps
		var lab: Node = load("res://lab/lab.tscn").instantiate()
		root.add_child(lab)
		for frame in range(3):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output_root.path_join("capture-lab.png"))
		lab.output.text = output_root
		lab.actions[0].pressed.emit()
		while lab.working:
			await process_frame
		check("native primary action produces review", not lab.review_path.is_empty() and not lab.review_button.disabled and lab.cancel_button.disabled)
		for frame in range(2):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output_root.path_join("capture-lab-completed.png"))
		var previous_before: String = lab.before.folder
		lab.actions[1].pressed.emit()
		while lab.working:
			await process_frame
		check("native before button captures before", lab.before.phase == "before" and lab.before.folder != previous_before)
		var previous_after: String = lab.after.folder
		lab.actions[2].pressed.emit()
		while lab.working:
			await process_frame
		check("native after button captures after", lab.after.phase == "after" and lab.after.folder != previous_after)
		var cancel_ui := func(count: int, _total: int, _id: String):
			if count == 1:
				lab.cancel_button.pressed.emit()
		lab.runner.progress.connect(cancel_ui)
		lab.actions[0].pressed.emit()
		while lab.working:
			await process_frame
		lab.runner.progress.disconnect(cancel_ui)
		check("native cancel action ends sequence and restores controls", lab.before.status == "cancelled" and lab.before.captures.size() == 1 and not lab.actions[0].disabled and lab.cancel_button.disabled)
		lab.queue_free()
	var data := {"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(),
		"logic_only": logic_only, "failures": failures, "tests": results, "output": output_root}
	var file := FileAccess.open(output_root.path_join("test-results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("EVIDENCE " + output_root)
	print("RESULT %s tests; %s failures" % [results.size(), failures])
	quit(0 if failures == 0 else 1)
