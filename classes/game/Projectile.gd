extends Node2D
class_name Projectile

var dist_from_center: float = 0.0
var init_rot: float = 0.0

var team: int = 0
var velocity: Vector2 = Vector2.ZERO
@export var prj_info: Dictionary = {}

var targ: Cluster
@export var prj_area: Area2D

@export var lifetime: float = -1.0

@export var split_into: PackedScene
@export var split_radius: float = 10.0
@export var split_amount: int = 1

func _ready() -> void:
	if !prj_area and $Area2D: prj_area = $Area2D
	prj_area.area_entered.connect(on_hit, ConnectFlags.CONNECT_DEFERRED)
	
	scale = Vector2.ONE * prj_info["size"]
	init_rot = global_rotation
	
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
	
	if lifetime > 0.0:
		get_tree().create_timer(lifetime).timeout.connect(destroy)

var t: float = randf_range(0.0, 1.0)
func _process(delta: float) -> void:
	t += delta
	
	velocity = Vector2.from_angle(global_rotation) * prj_info["speed"] * delta
	global_position += velocity
	
	if prj_info.has("homing") and prj_info["homing"] and targ and prj_info.has("turn_rate") and prj_info.has("targ_mode"):
		follow_targ(prj_info["targ_mode"], delta)
	elif prj_info.has("homing") and prj_info["homing"] and targ and prj_info.has("turn_rate"):
		follow_targ("default", delta)
	
	if prj_info.has("turn_rate") and prj_info.has("turn_mode") and prj_info["turn_mode"] == "sin" and prj_info.has("sin_turn_mode_freq"):
		global_rotation = init_rot + sin(t * prj_info["sin_turn_mode_freq"]) * prj_info["turn_rate"]
	
	if GlobalClass.current_arena and dist_from_center > GlobalClass.ESTIMATED_ARENA_RADIUS * GlobalClass.current_arena.scale.x:
		destroy()

func on_hit(area: Area2D) -> void:
	if area is Cluster and area.team != team: 
		area.recieve_hit(prj_info["dmg_info"])
		GlobalClass.play_sound("uid://br055er0cj176")
		if prj_info.has("pierce") and !prj_info["pierce"]: return
		destroy()
	if area.get_parent() is Projectile and area.get_parent().team != team and area.get_parent().prj_info.has("homing") and area.get_parent().prj_info["homing"]:
		area.get_parent().destroy()
		if prj_info.has("pierce") and !prj_info["pierce"]: return
		destroy()
	if area.get_parent() is PoppablePart and area.get_parent().user.team != team:
		area.get_parent().destroy()
		if prj_info.has("pierce") and !prj_info["pierce"]: return
		destroy()

func destroy() -> void:
	if split_into:
		for x in range(split_amount):
			var split_result: Node2D = split_into.instantiate()
			split_result.global_position = global_position + Vector2.RIGHT.rotated(randf_range(0, TAU)) * split_radius * scale
			split_result.global_rotation = x * (TAU / split_amount)
			if split_result.get("team"): split_result.team = team
			GlobalClass.world.add_child(split_result)
	
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
		if c.team != team:
			enemies.append(c)
	
	if enemies.is_empty(): 
		destroy()
		return
	
	targ = enemies.pick_random()
	targ.killed.connect(search_for_target, ConnectFlags.CONNECT_ONE_SHOT)

func follow_targ(mode: String, delta: float) -> void:
	match mode:
		"default":
			global_rotation = lerp_angle(
				global_rotation,
				(targ.global_position - global_position).angle(),
				delta * prj_info["turn_rate"]
			)
		"mouse":
			global_rotation = lerp_angle(
				global_rotation,
				(get_global_mouse_position() - global_position).angle(),
				delta * prj_info["turn_rate"]
			)
