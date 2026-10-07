extends Control
## All visual assets are original code-built controls. No private project assets.

var ctx: Dictionary
var state: String

func panel(color: Color, radius: int = 16) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	return box

func text_at(parent: Node, copy: String, at: Vector2, bounds: Vector2, font_size: int, color: Color = Color("edf4f5")) -> Label:
	var label := Label.new()
	label.text = copy
	label.position = at
	label.size = bounds
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func prepare(context: Dictionary, state_id: String) -> void:
	ctx = context
	state = state_id
	theme = Theme.new()
	theme.default_font = ThemeDB.fallback_font
	theme.default_font_size = 16
	var portuguese: bool = ctx.locale == "pt_BR"
	var fixed: bool = ctx.phase != "before"
	var dimensions: Vector2i = ctx.size
	var width := float(dimensions.x)
	var background := ColorRect.new()
	background.color = Color("10221f")
	background.size = dimensions
	add_child(background)
	text_at(self, "T / S", Vector2(28, 22), Vector2(70, 30), 22, Color("80e0c3"))
	text_at(self, "TRAIL SUPPLY", Vector2(103, 24), Vector2(width - 125, 26), 16)
	text_at(self, "EQUIPAMENTO PARA IR MAIS LONGE" if portuguese else "GO FURTHER. PACK LIGHTER.", Vector2(28, 71), Vector2(width - 56, 24), 12, Color("a7bbc5"))
	var card_width := minf(620.0, width - 48.0) if fixed else 620.0
	var card := Panel.new()
	card.position = Vector2((width - card_width) / 2.0, 120)
	card.size = Vector2(card_width, 435)
	card.add_theme_stylebox_override("panel", panel(Color("1b332e")))
	add_child(card)
	text_at(card, "02 / PRONTO PARA A TRILHA" if portuguese else "02 / READY FOR THE TRAIL", Vector2(28, 25), Vector2(card_width - 56, 22), 12, Color("80e0c3"))
	text_at(card, ("Tudo pronto." if portuguese else "You're all set.") if state == "packed" else ("Seu kit de aventura" if portuguese else "Your adventure kit"), Vector2(28, 60), Vector2(card_width - 56, 42), 28)
	text_at(card, "Pedido TS-1042 · 15 Jan 2026" if portuguese else "Order TS-1042 · 15 Jan 2026", Vector2(28, 109), Vector2(card_width - 56, 24), 14, Color("a7bbc5"))
	var item := Panel.new()
	item.position = Vector2(28, 160)
	item.size = Vector2(card_width - 56, 102)
	item.add_theme_stylebox_override("panel", panel(Color("29483e"), 12))
	card.add_child(item)
	text_at(item, "△", Vector2(16, 17), Vector2(54, 58), 40, Color("80e0c3"))
	text_at(item, "Kit Horizonte" if portuguese else "Horizon kit", Vector2(78, 18), Vector2(card_width - 166, 28), 18)
	text_at(item, "3 itens · 1,2 kg · Verde" if portuguese else "3 items · 1.2 kg · Forest", Vector2(78, 53), Vector2(card_width - 166, 24), 14, Color("a7bbc5"))
	text_at(card, "TOTAL", Vector2(28, 285), Vector2(80, 25), 12, Color("a7bbc5"))
	text_at(card, "R$ 129,00" if portuguese else "$ 24.00", Vector2(card_width - 174, 280), Vector2(146, 35), 23)
	var cta_width := card_width - 56 if fixed else 148.0
	var cta := Panel.new()
	cta.position = Vector2(28, 337)
	cta.size = Vector2(cta_width, 68 if fixed else 52)
	cta.clip_contents = true
	cta.add_theme_stylebox_override("panel", panel(Color("80e0c3"), 10))
	card.add_child(cta)
	var copy := ("Ver os detalhes do pedido" if portuguese else "View order") if state == "packed" else ("Confirmar e preparar minha aventura" if portuguese else "Pack my kit")
	var cta_label := text_at(cta, copy, Vector2(14, 6), Vector2(cta_width - 28, cta.size.y - 12), 16, Color("10221f"))
	cta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cta_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if fixed:
		cta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		cta_label.clip_text = true
	text_at(self, "Pequenas escolhas. Grandes jornadas." if portuguese else "Small choices. Great journeys.", Vector2(28, 586), Vector2(width - 56, 26), 14, Color("a7bbc5"))
