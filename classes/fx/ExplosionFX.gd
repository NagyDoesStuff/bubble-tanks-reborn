extends Node2D
class_name ExplosionFX

@export var grow_rate: float = 10.0
@export var lifetime: float = 0.25

@export var random_rotation: bool = true

func _ready() -> void:
	if random_rotation: global_rotation = randf_range(0, TAU)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _process(delta: float) -> void:
	scale += Vector2.ONE * grow_rate * delta
