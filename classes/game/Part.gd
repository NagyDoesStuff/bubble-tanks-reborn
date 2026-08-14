extends Node2D
class_name Part

var disabled: bool = false
var editor_mode: bool = false
var is_hovered: bool = false

@onready var user: Cluster:
	get:
		if get_parent() is Cluster:
			return get_parent()
		else:
			return null

func _ready() -> void:
	if editor_mode:
		z_index += 99
		
		var e_area: Area2D = Area2D.new()
		e_area.mouse_entered.connect(set.bind("is_hovered", true))
		e_area.mouse_exited.connect(set.bind("is_hovered", false))
		
		var e_col: CollisionShape2D = CollisionShape2D.new()
		e_col.shape = CircleShape2D.new()
		e_col.shape.radius = 32
		
		add_child(e_area)
		e_area.add_child(e_col)
	
	_subready()

func _subready() -> void:
	pass
