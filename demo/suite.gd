extends RefCounted

const SCENE = preload("res://demo/trail_supply.tscn")
const SIZES: Array[Vector2i] = [Vector2i(480, 720), Vector2i(960, 640)]
const LOCALES: Array[String] = ["en", "pt_BR"]

static func register(runner: Node) -> void:
	runner.register_state("supply", SCENE, func(scene: Node, ctx: Dictionary): scene.prepare(ctx, "supply"))
	runner.register_state("packed", SCENE, func(scene: Node, ctx: Dictionary): scene.prepare(ctx, "packed"))
