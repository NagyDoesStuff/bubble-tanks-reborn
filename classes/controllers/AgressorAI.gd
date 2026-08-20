extends AIController
class_name AgressorAI

var can_turn: bool = false

func _enter_tree() -> void:
	min_freq *= 2
	max_freq *= 2
	min_turn_time_ratio *= 2
	max_turn_time_ratio *= 2

func _subready() -> void:
	ai_cycle()

func ai_cycle() -> void:
	var time: float = randf_range(min_freq, max_freq)
	turn(randf_range(min_turn_time_ratio, max_turn_time_ratio))
	get_tree().create_timer(time).timeout.connect(ai_cycle)

func _process(_delta: float) -> void:
	user.velocity = lerp(
		user.velocity, 
		Vector2.from_angle(user.global_rotation) * user.speed,
		_delta * user.acceleration
	)
	
	if !GlobalClass.current_arena or !GlobalClass.player_cluster: return
	
	if run_to_center_margin * GlobalClass.current_arena.scale.x > user.dist_from_center:
		if can_turn:
			user.global_rotation = move_toward(
				user.global_rotation,
				(GlobalClass.player_cluster.global_position - user.global_position).angle(),
				_delta * user.turn_rate * run_to_center_mult
			)
	else:
		user.global_rotation = move_toward(
			user.global_rotation,
			(GlobalClass.current_arena.global_position - user.global_position).angle(),
			_delta * user.turn_rate * run_to_center_mult
		)
	
func turn(duration: float) -> void:
	can_turn = true
	if get_tree(): get_tree().create_timer(duration).timeout.connect(set.bind("can_turn", false))
