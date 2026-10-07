extends Control

const Runner = preload("res://addons/ui_check/capture_runner.gd")
const Suite = preload("res://demo/suite.gd")
const Report = preload("res://addons/ui_check/report.gd")
var runner: Node
var output: LineEdit
var status_label: Label
var progress_bar: ProgressBar
var cancel_button: Button
var review_button: Button
var actions: Array[Button] = []
var before: Dictionary = {}
var after: Dictionary = {}
var review_path := ""
var working := false
var cancel_sequence := false
var active_phase := ""

func style(color: String) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(color)
	box.set_corner_radius_all(12)
	box.set_border_width_all(1)
	box.border_color = Color("3b5362")
	box.content_margin_left = 20
	box.content_margin_right = 20
	box.content_margin_top = 16
	box.content_margin_bottom = 16
	return box

func copy(parent: Node, text: String, font_size: int = 16, color: String = "edf4f5") -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(color))
	parent.add_child(label)
	return label

func button(parent: Node, text: String, callback: Callable, primary: bool = false) -> Button:
	var control := Button.new()
	control.text = text
	control.custom_minimum_size.y = 48
	control.add_theme_stylebox_override("normal", style("80e0c3" if primary else "223441"))
	control.add_theme_stylebox_override("hover", style("a3edd8" if primary else "304958"))
	control.add_theme_stylebox_override("pressed", style("61bea3" if primary else "192630"))
	control.add_theme_stylebox_override("disabled", style("192630"))
	if primary:
		control.add_theme_color_override("font_color", Color("101820"))
		control.add_theme_color_override("font_hover_color", Color("101820"))
		control.add_theme_color_override("font_pressed_color", Color("101820"))
	control.pressed.connect(callback)
	parent.add_child(control)
	return control

func card(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", style("192630"))
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	return column

func _ready() -> void:
	theme = Theme.new()
	theme.default_font = ThemeDB.fallback_font
	theme.default_font_size = 16
	runner = Runner.new()
	add_child(runner)
	Suite.register(runner)
	runner.progress.connect(func(count: int, total: int, id: String):
		progress_bar.max_value = total
		progress_bar.value = count
		status_label.text = "Capturing %s · %s / %s\n%s" % [active_phase, count, total, id])
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)
	var scroll := ScrollContainer.new()
	margin.add_child(scroll)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 16)
	scroll.add_child(page)
	copy(page, "[ UI ]  GODOT UI CHECK                                    LOCAL PROOF / 0.1", 14, "80e0c3")
	copy(page, "Catch layout surprises early.", 32)
	copy(page, "Prepare a known state. Capture a small matrix. Review the pixels.", 16, "a7bbc5")
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 20)
	page.add_child(columns)
	var left := card(columns)
	left.custom_minimum_size.x = 425
	copy(left, "01 / Prepare", 24)
	copy(left, "Trail Supply", 21, "80e0c3")
	copy(left, "An original hiking checkout, with two intentional layout problems to compare.", 16, "a7bbc5")
	copy(left, "2 states     supply · packed\n2 sizes       480 × 720 · 960 × 640\n2 locales   English · Português (Brasil)")
	copy(left, "8 captures per version · fresh scene per case", 14, "a7bbc5")
	copy(left, "Output folder", 14, "a7bbc5")
	output = LineEdit.new()
	output.text = "F:/Codex/Builds/godot-ui-check" if DirAccess.dir_exists_absolute("F:/Codex/Builds/godot-ui-check") else ProjectSettings.globalize_path("user://captures")
	output.placeholder_text = "Absolute folder for unique capture runs"
	output.tooltip_text = "Every capture creates a new run folder; existing PNGs are never overwritten."
	left.add_child(output)
	copy(left, "Pinned font · fixed clock · fixed data · seed 2026", 13, "a7bbc5")
	var right := card(columns)
	copy(right, "02 / Capture", 24)
	actions.append(button(right, "Run both + build review", func(): _capture("both"), true))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	right.add_child(row)
	for phase in ["before", "after"]:
		var action := button(row, "Capture " + phase, func(): _capture(phase))
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.append(action)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.y = 10
	progress_bar.show_percentage = false
	right.add_child(progress_bar)
	cancel_button = button(right, "Cancel capture", _cancel)
	cancel_button.disabled = true
	review_button = button(right, "Open local gallery ↗", _open_review)
	review_button.disabled = true
	copy(right, "Before has intentional issues. After shows their fixes. Pixel changes still need human review.", 14, "a7bbc5")
	status_label = copy(page, "Ready · choose Run both to create the first comparison.\nGodot %s · %s" % [Engine.get_version_info().string, RenderingServer.get_current_rendering_method()], 16)
	copy(page, "What to look for", 20)
	copy(page, "01  A 620 px card overflows the 480 px mobile viewport.\n02  A fixed-width action clips the longer Portuguese text.\nThe corrected version fits the viewport and lets the action wrap.", 15, "a7bbc5")
	copy(page, "LOCAL ONLY   ·   No server or account   ·   New folder for every run", 12, "80e0c3")

func _cancel() -> void:
	cancel_sequence = true
	runner.request_cancel()
	status_label.text = "Cancelling · finishing cleanup and restoring settings…"

func _open_review() -> void:
	if not review_path.is_empty():
		OS.shell_open(review_path)

func _capture(phase: String) -> void:
	if working:
		return
	working = true
	cancel_sequence = false
	for action in actions:
		action.disabled = true
	output.editable = false
	cancel_button.disabled = false
	review_button.disabled = true
	progress_bar.value = 0
	status_label.text = "Preparing " + phase + "…"
	var result: Dictionary = {}
	if phase in ["before", "both"]:
		active_phase = "before"
		result = await runner.run(output.text.strip_edges(), "before", Suite.SIZES, Suite.LOCALES)
		before = result
	if phase == "after" or (phase == "both" and result.get("status") == "completed" and not cancel_sequence):
		active_phase = "after"
		result = await runner.run(output.text.strip_edges(), "after", Suite.SIZES, Suite.LOCALES)
		after = result
	if result.get("status") == "completed":
		status_label.text = "Completed · %s captures\n%s" % [result.captures.size(), result.folder]
		if before.get("status") == "completed" and after.get("status") == "completed":
			var review := Report.write_pair(before, after, output.text.strip_edges())
			if review.error.is_empty():
				review_path = review.path
				status_label.text = "Completed · %s pairs, %s changed · ready for review\n%s" % [review.total, review.changed, review.path]
			else:
				status_label.text += "\nReview error: " + review.error
	else:
		status_label.text = "%s · %s\n%s" % [result.get("status", "failed").capitalize(), result.get("error", ""), result.get("folder", "No output written")]
	for action in actions:
		action.disabled = false
	output.editable = true
	cancel_button.disabled = true
	review_button.disabled = review_path.is_empty()
	working = false
