extends Camera2D
class_name DynamicCamera

var anchor: Node2D
var free_cam: bool = false

func _ready() -> void:
	position_smoothing_speed = 20.0
	position_smoothing_enabled = true

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("freecam"):
		free_cam = !free_cam
	
	if free_cam:
		global_position += Input.get_vector("cam_mleft", "cam_mright", "cam_mup", "cam_mdown").normalized() * 20
		zoom = lerp(zoom, Vector2.ONE * 0.75, _delta * 3)
	elif anchor: 
		global_position = anchor.global_position
		zoom = lerp(zoom, Vector2.ONE, _delta * 3)
