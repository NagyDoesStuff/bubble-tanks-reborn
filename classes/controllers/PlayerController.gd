extends Controller
class_name PlayerController

func _process(_delta: float) -> void:
	if !user.enabled: return
	user.velocity = lerp(
		user.velocity, 
		Input.get_vector("mleft", "mright", "mup", "mdown").normalized() * user.speed, 
		_delta * user.acceleration
	)
	if user.cluster_class < 4:
		user.look_at(get_global_mouse_position())
	else:
		user.global_rotation = move_toward(
			user.global_rotation, 
			user.velocity.angle(), 
			_delta * user.turn_rate)
