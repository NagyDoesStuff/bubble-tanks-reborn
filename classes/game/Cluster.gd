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

@export_group("Spawn Settings")
@export var min_to_available: int = 0
@export var max_of_type: int = 2

var dist_from_center: float = 0.0

var velocity: Vector2 = Vector2.ZERO

var mid_blinking: bool = false

var in_arena: Arena

var enabled: bool = true

## For player tanks, this serves as the progression variable for unlocking the next class.
## For enemy tanks, this serves as the health variable.
var progress: int = 1:
	set(value):
		progress = clampi(value, 0, max_progress)
		progress_changed.emit()
		check_progress()
@export var max_progress: int = 1

var parts: Array[Part] = []

func _ready() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.5)
	
	if !enabled: return
	
	parts = get_parts()
	check_dist_to_center()
	
	await get_tree().process_frame
	
	if team == 0:
		GlobalClass.player_cluster = self
		add_child(PlayerController.new())
		max_progress = GlobalClass.world.player_progression_requirement
	else:
		progress = max_progress
		add_child(AIController.new())
	
	killed.connect(GlobalClass.world.check_battle_state)

func _process(_delta: float) -> void:
	if !enabled: return
	
	global_position += velocity
	if in_arena and dist_from_center > GlobalClass.ESTIMATED_ARENA_RADIUS * in_arena.scale.x:
		if team != 0:
			kill()
		else:
			print("OUTSIDE ARENA, TRANSFERING TO NEW ONE")
			GlobalClass.world.transfer_player_to_next_arena((global_position - in_arena.global_position).angle())
	
func get_parts() -> Array[Part]:
	var list: Array[Part]
	for b in get_children():
		if b is Part:
			list.append(b)
	return list

func recieve_hit(dmg_info: Dictionary) -> void:
	match dmg_info["type"]:
		"dmg":
			progress -= dmg_info["amount"]
			if team == 0:
				GlobalClass.play_sound("uid://c2wjfumwdpyo")
		_: 
			pass

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

func check_dist_to_center() -> void:
	if in_arena: dist_from_center = global_position.distance_to(in_arena.global_position)
	get_tree().create_timer(GlobalClass.CLUSTER_CHECK_DIST_FREQ).timeout.connect(check_dist_to_center)

func kill() -> void:
	GlobalClass.play_sound("uid://dq4v7w25xntxg")
	killed.emit()
	drop_points()
	queue_free()

func blink() -> void:
	if mid_blinking: return
	mid_blinking = true
	
	var color: Color = modulate
	modulate = GlobalClass.HIT_COLOR
	for x in range(GlobalClass.HIT_BLINK_TIME):
		await get_tree().process_frame
	
	modulate = color
	mid_blinking = false

func drop_points() -> void:
	var drop_list: Array[BubblePoint] = []
	
	var avaliable_value_to_convert: int = drop_value
	for x in range(drop_value):
		var rand_pt_val: int = randi_range(1,10)
		@warning_ignore("narrowing_conversion")
		if rand_pt_val > avaliable_value_to_convert:
			rand_pt_val = avaliable_value_to_convert
		
		var pt: BubblePoint = GlobalClass.BUBBLE_POINT.instantiate()
		pt.add_value = rand_pt_val
		pt.global_position = global_position
		pt.in_arena = in_arena
		
		avaliable_value_to_convert -= rand_pt_val
		drop_list.append(pt)
	
	for pt in drop_list:
		GlobalClass.world.call_deferred("add_child", pt)
