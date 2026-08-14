extends Area2D
class_name BubblePoint

var velocity: Vector2 = Vector2.ZERO

var min_spread_force: float = 20.0
var max_spread_force: float = 30.0
var follow_speed: float = 2.0
var dist_from_center: float = 0.0
var accel: float = 0.9
var add_value: float = 1.0

var in_arena: Arena

func _ready() -> void:
	scale = Vector2.ONE * (GlobalClass.MIN_BUBBLE_POINT_SIZE + (add_value * GlobalClass.BUBBLE_POINT_GROW_SIZE))
	velocity = Vector2.from_angle(randf_range(0, TAU)) * randf_range(min_spread_force,max_spread_force)
	check_dist_to_center()
	
	area_entered.connect(on_area_entered)
	
func _process(_delta: float) -> void:
	if GlobalClass.player_cluster and !GlobalClass.world.mid_battle: velocity += (GlobalClass.player_cluster.global_position - global_position).normalized() * follow_speed
	global_position += velocity
	velocity *= accel
	if in_arena and dist_from_center > GlobalClass.ESTIMATED_ARENA_RADIUS * in_arena.scale.x:
		queue_free()

func check_dist_to_center() -> void:
	if in_arena: dist_from_center = global_position.distance_to(in_arena.global_position)
	get_tree().create_timer(GlobalClass.CLUSTER_CHECK_DIST_FREQ).timeout.connect(check_dist_to_center)

func on_area_entered(area: Area2D) -> void:
	if area is Cluster and area.team == 0:
		area.progress += add_value
		GlobalClass.play_sound("uid://xd20t8hrw5mh")
		queue_free()
