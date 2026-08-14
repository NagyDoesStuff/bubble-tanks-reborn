extends Node2D
class_name Bubble

@export var is_static: bool = false
var init_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	init_scale = scale

var t: float = randf_range(0.0, 1.0)
func _process(_delta: float) -> void:
	t += _delta
	scale = init_scale * (1 + sin(t * 6) * 0.1)
