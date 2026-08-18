extends Area2D
class_name Cluster

signal progress_changed()
signal killed()

@export_group("Info")
@export var team: int = 0
@export var cluster_class: int = 1

@export_group("Stats")
@export var speed: float = 16.0
@export var acceleration: float = 6.0
@export var turn_rate: float = 2.0
@export var drop_value: int = 10
@export var max_progress: int = 1

@export_group("Spawn Settings")
@export var min_to_available: int = 0
@export var max_spawn_amount: int = 3

var dist_from_center: float = 0.0

var velocity: Vector2 = Vector2.ZERO

var mid_blinking: bool = false
var enabled: bool = true
var is_slown_down: bool = false
var is_jammed: bool = false

## For player tanks, this serves as the progression variable for unlocking the next class.
## For enemy tanks, this serves as the health variable.
var progress: int = 1:
	set(value):
		progress = clampi(value, 0, max_progress)
		progress_changed.emit()
		check_progress()

var parts: Array[Part] = []

func _ready() -> void:
	modulate.a = 0.0
	
	await get_tree().process_frame
	
	create_tween().tween_property(self, "modulate:a", 1.0, 0.5)
	
	if !enabled: return
	
	parts = get_parts()
	
	if team == 0:
		GlobalClass.player_cluster = self
		progress_changed.connect(GlobalClass.world.ui.hud.update_progression_bar)
		add_child(PlayerController.new())
		max_progress = GlobalClass.world.player_progression_requirement
	else:
		progress = max_progress
		add_child(AIController.new())
	
	killed.connect(GlobalClass.world.check_battle_state)
	
	var check_dist_center_timer: Timer = Timer.new()
	check_dist_center_timer.autostart = true
	check_dist_center_timer.wait_time = 0.1
	check_dist_center_timer.timeout.connect(func () -> void:
		if GlobalClass.current_arena: 
			dist_from_center = global_position.distance_to(GlobalClass.current_arena.global_position)
	)
	add_child(check_dist_center_timer)

func _process(_delta: float) -> void:
	if !enabled: return
	
	global_position += velocity
	if GlobalClass.current_arena and dist_from_center > GlobalClass.ESTIMATED_ARENA_RADIUS * GlobalClass.current_arena.scale.x:
		if team != 0:
			kill()
		else:
			GlobalClass.world.transfer_player_to_next_arena((global_position - GlobalClass.current_arena.global_position).angle())
	
func get_parts() -> Array[Part]:
	var list: Array[Part]
	for b in get_children():
		if b is Part:
			list.append(b)
	return list

func recieve_hit(dmg_info: Dictionary) -> void:
	if !enabled: return
	match dmg_info["type"]:
		"slowdown":
			slow_down(dmg_info["amount"], dmg_info["duration"])
		"jam":
			jam_weapons(dmg_info["duration"])
		_:
			progress -= dmg_info["amount"]
		
	if team == 0:
		GlobalClass.play_sound("uid://c2wjfumwdpyo")

func check_progress() -> void:
	if progress == max_progress and team == 0:
		GlobalClass.world.upgrade_player()
	
	if progress == 0:
		if team == 0:
			progress = 1
			await get_tree().process_frame
			GlobalClass.world.arenas_travelled = 0
			GlobalClass.world.transfer_player_to_next_arena(randf_range(0, TAU))
		else:
			kill()

func kill() -> void:
	GlobalClass.play_sound("uid://dq4v7w25xntxg")
	killed.emit()
	drop_points()
	if get_parent():
		get_parent().remove_child(self)
	queue_free()

func drop_points() -> void:
	var avaliable_value_to_convert: int = drop_value
	var available_bubble_sizes: Array[int] = GlobalClass.FIXED_BUBBLE_SIZES.duplicate()
	var values_to_erase: Array[int] = []
	for size in available_bubble_sizes:
		if size > drop_value:
			values_to_erase.append(size)
	for value in values_to_erase:
		available_bubble_sizes.erase(value)
	
	print("Picked sizes: " + str(available_bubble_sizes) + " with total drop value of " + str(drop_value))
	while avaliable_value_to_convert > 0:
		var bubble_value: int = available_bubble_sizes.pick_random()
		
		if bubble_value > avaliable_value_to_convert:
			bubble_value = avaliable_value_to_convert
		
		var pt: BubblePoint = GlobalClass.BUBBLE_POINT.instantiate()
		pt.add_value = bubble_value
		pt.global_position = global_position
		
		avaliable_value_to_convert -= bubble_value
		print("Created bubble with value of " + str(bubble_value))
		GlobalClass.world.call_deferred("add_child", pt)

func slow_down(mult: float, duration: float) -> void:
	if is_slown_down: return
	is_slown_down = true
	
	var init_speed: float = speed
	var init_turn_rate: float = turn_rate
	speed *= mult
	turn_rate *= mult
	
	modulate = GlobalClass.SLOWN_DOWN_COLOR
	
	await get_tree().create_timer(duration).timeout
	
	modulate = Color.WHITE
	
	speed = init_speed
	turn_rate = init_turn_rate
	is_slown_down = false

func jam_weapons(duration: float) -> void:
	if is_jammed: return
	is_jammed = true
	
	modulate = GlobalClass.JAMMED_COLOR
	
	await get_tree().create_timer(duration).timeout
	
	modulate = Color.WHITE
	
	is_jammed = false

func get_used_gp() -> int:
	var gp: int = 0
	for p in get_parts():
		gp += p.gp_usage
	return gp
