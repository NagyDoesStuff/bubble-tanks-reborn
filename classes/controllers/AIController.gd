extends Controller
class_name AIController

var min_freq: float = 1.0
var max_freq: float = 2.0
var turn_dir: int = 0
var min_turn_time_ratio: float = 0.25
var max_turn_time_ratio: float = 0.5
var run_to_center_margin: float = GlobalClass.ESTIMATED_ARENA_RADIUS * 0.65

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
	
	if !user.in_arena: return
	
	if run_to_center_margin * user.in_arena.scale.x > user.dist_from_center:
		user.global_rotation += user.turn_rate * turn_dir * _delta
	else:
		user.global_rotation = move_toward(
			user.global_rotation,
			(user.in_arena.global_position - user.global_position).angle(),
			_delta * user.turn_rate
		)
	
func turn(duration: float, dir: int) -> void:
	turn_dir = dir
	get_tree().create_timer(duration).timeout.connect(set.bind("turn_dir", 0))
