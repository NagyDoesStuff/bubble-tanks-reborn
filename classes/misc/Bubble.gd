extends Node2D
class_name Bubble

@export var is_static: bool = false
var init_scale: Vector2 = Vector2.ONE

var grow_freq: float = 4.0
var grow_amplitude: float = 0.15
var grow_freq_variation: float = 0.5
var grow_amplitude_variation: float = 0.33

func _ready() -> void:
	init_scale = scale
	grow_freq += grow_freq * randf_range(1 - grow_freq_variation, grow_freq_variation)
	grow_amplitude += grow_amplitude * randf_range(1 - grow_amplitude_variation, grow_amplitude_variation)
	
var t: float = randf_range(0.0, 1.0)
func _process(_delta: float) -> void:
	if is_static: return
	t += _delta
	scale = init_scale * (1 + abs(sin(t * grow_freq) * grow_amplitude))
