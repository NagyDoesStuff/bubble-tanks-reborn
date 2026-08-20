extends Part
class_name PoppablePart

@export var split_into: PackedScene
@export var split_radius: float = 10.0
@export var split_amount: int = 1

func destroy() -> void:
	for x in range(split_amount):
		var split_result: Node2D = split_into.instantiate()
		split_result.global_position = global_position + Vector2.RIGHT.rotated(randf_range(0, TAU)) * split_radius * scale
		split_result.global_rotation = x * (TAU / split_amount)
		split_result.team = user.team
		GlobalClass.world.add_child(split_result)
	queue_free()
