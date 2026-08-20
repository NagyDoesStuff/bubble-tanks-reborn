extends Node2D
class_name Controller

var user: Cluster
var enabled: bool = false

func _ready() -> void:
	if !enabled: 
		queue_free()
	else:
		user = get_parent()
		
	_subready()
	
func _subready() -> void:
	pass
