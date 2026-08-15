extends Node2D
class_name Projectile

var dist_from_center: float = 0.0

var team: int = 0
var velocity: Vector2 = Vector2.ZERO
var prj_info: Dictionary = {}
var targ: Cluster

@export var prj_area: Area2D

func _ready() -> void:
	if !prj_area and $Area2D: prj_area = $Area2D
	prj_area.area_entered.connect(on_hit, ConnectFlags.CONNECT_DEFERRED)
	
	scale = Vector2.ONE * prj_info["size"]
	
	if team == 0:
		$OTHER.queue_free()
	else:
		$PLAYER.queue_free()
	
	var check_dist_center_timer: Timer = Timer.new()
	check_dist_center_timer.autostart = true
	check_dist_center_timer.wait_time = 0.1
	check_dist_center_timer.timeout.connect(func () -> void:
		if GlobalClass.current_arena: 
			dist_from_center = global_position.distance_to(GlobalClass.current_arena.global_position)
	)
	add_child(check_dist_center_timer)
	
	if prj_info.has("homing") and prj_info["homing"]:
		search_for_target()

func _process(delta: float) -> void:
	velocity = Vector2.from_angle(global_rotation) * prj_info["speed"] * delta
	global_position += velocity
	
	if targ and prj_info.has("turn_rate"):
		global_rotation = move_toward(
			global_rotation,
		 	(targ.global_position - global_position).angle(),
			delta * prj_info["turn_rate"]
		)
	
	if GlobalClass.current_arena and dist_from_center > GlobalClass.ESTIMATED_ARENA_RADIUS * GlobalClass.current_arena.scale.x:
		destroy()

func on_hit(area: Area2D) -> void:
	var cluster: Cluster
	if area is Cluster: 
		cluster = area
	else: 
		return
	if cluster.team != team:
		cluster.recieve_hit(prj_info["dmg_info"])
		# SFX
		GlobalClass.play_sound("uid://br055er0cj176")
		
		destroy()

func destroy() -> void:
	var fx: Node2D
	if prj_info.has("hit_fx"):
		fx = load(prj_info["hit_fx"]).instantiate()
	else:
		fx = GlobalClass.DEFAULT_HIT_FX.instantiate()
	fx.global_position = global_position
	fx.scale = scale
	GlobalClass.world.add_child(fx)
	call_deferred("queue_free")
	
func search_for_target() -> void:
	var enemies: Array[Cluster] = []
	
	for c in GlobalClass.world.get_clusters():
		if c.team != 0:
			enemies.append(c)
	
	if enemies.is_empty(): 
		destroy()
		return
	
	targ = enemies.pick_random()
	targ.killed.connect(search_for_target, ConnectFlags.CONNECT_ONE_SHOT)
