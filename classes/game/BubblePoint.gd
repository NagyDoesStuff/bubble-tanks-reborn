extends Area2D
class_name BubblePoint

@onready var spr: Sprite2D = $Sprite2D

var velocity: Vector2 = Vector2.ZERO

var min_spread_force: float = 10.0
var max_spread_force: float = 20.0
var follow_speed: float = 3.0
var dist_from_center: float = 0.0
var accel: float = 0.92
var add_value: float = 1.0

var can_follow: bool = false

func _ready() -> void:
	scale = Vector2.ONE * (GlobalClass.MIN_BUBBLE_POINT_SIZE + (add_value * GlobalClass.BUBBLE_POINT_GROW_SIZE))
	velocity = Vector2.from_angle(randf_range(0, TAU)) * randf_range(min_spread_force,max_spread_force)
	if add_value >= 100:
		spr.texture = load("uid://3of6wli6kjpb")
	
	var check_dist_center_timer: Timer = Timer.new()
	check_dist_center_timer.autostart = true
	check_dist_center_timer.wait_time = 0.1
	check_dist_center_timer.timeout.connect(func () -> void:
		if GlobalClass.current_arena: 
			dist_from_center = global_position.distance_to(GlobalClass.current_arena.global_position)
	)
	add_child(check_dist_center_timer)
	
	area_entered.connect(on_area_entered, ConnectFlags.CONNECT_DEFERRED)
	
func _process(_delta: float) -> void:
	if GlobalClass.player_cluster and !GlobalClass.world.mid_battle and GlobalClass.player_cluster.enabled: 
		velocity += (GlobalClass.player_cluster.global_position - global_position).normalized() * follow_speed
	global_position += velocity
	velocity *= accel
	if GlobalClass.current_arena and dist_from_center > GlobalClass.ESTIMATED_ARENA_RADIUS * GlobalClass.current_arena.scale.x:
		queue_free()

func on_area_entered(area: Area2D) -> void:
	if area is Cluster and area.team == 0 and area.enabled:
		area.progress += add_value
		GlobalClass.play_sound("uid://xd20t8hrw5mh")
		queue_free()
