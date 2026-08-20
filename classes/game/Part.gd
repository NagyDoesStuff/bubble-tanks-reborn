extends Node2D
class_name Part

@export_enum(
	"Collision",
	"Player Primaries",
	"Player Secondaries",
	"Player Passives",
	"Enemy Weapons",
	"Enemy Behaviors",
	"Other"
) var category: String = "Other"

@export var disabled: bool = false
@export var editor_mode: bool = false
@export var is_hovered: bool = false
@export var gp_usage: int = 0

@onready var user: Cluster:
	get:
		if get_parent() is Cluster:
			return get_parent()
		else:
			return null
var linked_via_editor: Part
var init_rotation: float = 0.0

func _ready() -> void:
	owner = user
	init_rotation = rotation
	
	if editor_mode:
		var e_area: Area2D = Area2D.new()
		e_area.mouse_entered.connect(set.bind("is_hovered", true))
		e_area.mouse_exited.connect(set.bind("is_hovered", false))
		
		var e_col: CollisionShape2D = CollisionShape2D.new()
		e_col.shape = CircleShape2D.new()
		e_col.shape.radius = 16
		
		add_child(e_area)
		e_area.add_child(e_col)
	
	_subready()

func _subready() -> void:
	pass
