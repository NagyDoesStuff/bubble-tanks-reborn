extends Part
class_name CollisionPart

@onready var col: CollisionShape2D = $CollisionShape2D

func _subready() -> void:
	await get_tree().process_frame
	if get_parent() is Cluster:
		col.reparent(get_parent())
