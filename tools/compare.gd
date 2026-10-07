extends SceneTree
## Compare existing manifests in separate invocations; no renderer needed.
const Report = preload("res://addons/ui_check/report.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 3:
		printerr("Usage: --script res://tools/compare.gd -- BEFORE_MANIFEST AFTER_MANIFEST OUTPUT_FOLDER")
		quit(2)
		return
	var before: Variant = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var after: Variant = JSON.parse_string(FileAccess.get_file_as_string(args[1]))
	if not before is Dictionary or not after is Dictionary:
		printerr("Both inputs must be valid manifest JSON objects.")
		quit(2)
		return
	var result := Report.write_pair(before, after, args[2])
	if not result.get("error", "").is_empty():
		printerr(result.error)
		quit(1)
		return
	print(result.path)
	quit(0)
