extends Line2D
class_name Trail2D

@export var point_freq: float = 0.01
@export var max_point_count: int = 50

@onready var user: Node2D = get_parent()

func _ready() -> void:
	show_behind_parent = true
	
	var timer: Timer = Timer.new()
	timer.autostart = true
	timer.wait_time = point_freq
	timer.timeout.connect(place_point)
	add_child(timer)

func _process(_delta: float) -> void:
	# Lock position and rotation.
	global_position = Vector2.ZERO
	global_rotation = 0.0

func place_point() -> void:
	add_point(to_local(user.global_position))
	while get_point_count() > max_point_count:
		remove_point(0)
