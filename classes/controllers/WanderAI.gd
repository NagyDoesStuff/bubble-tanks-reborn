extends AIController
class_name WanderAI

func _subready() -> void:
	ai_cycle()

func ai_cycle() -> void:
	var time: float = randf_range(min_freq, max_freq)
	turn(randf_range(min_turn_time_ratio, max_turn_time_ratio), randi_range(-1, 1))
	get_tree().create_timer(time).timeout.connect(ai_cycle)

func _process(_delta: float) -> void:
	user.velocity = lerp(
		user.velocity, 
		Vector2.from_angle(user.global_rotation) * user.speed,
		_delta * user.acceleration
	)
	
	if !GlobalClass.current_arena: return
	
	if run_to_center_margin * GlobalClass.current_arena.scale.x > user.dist_from_center:
		user.global_rotation += user.turn_rate * turn_dir * _delta
	else:
		user.global_rotation = move_toward(
			user.global_rotation,
			(GlobalClass.current_arena.global_position - user.global_position).angle(),
			_delta * user.turn_rate * run_to_center_mult
		)
	
func turn(duration: float, dir: int) -> void:
	turn_dir = dir
	if get_tree(): get_tree().create_timer(duration).timeout.connect(set.bind("turn_dir", 0))
