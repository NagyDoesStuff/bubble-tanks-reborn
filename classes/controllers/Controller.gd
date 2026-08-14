extends Node2D
class_name Controller

@onready var user: Cluster = get_parent()

func _ready() -> void:
	if !user.enabled: queue_free()
	
	_subready()
	
func _subready() -> void:
	pass
