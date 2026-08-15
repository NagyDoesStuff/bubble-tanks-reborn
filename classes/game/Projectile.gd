extends Node2D
class_name Projectile

var dist_from_center: float = 0.0

var in_arena: Arena

var team: int = 0
var velocity: Vector2 = Vector2.ZERO
var prj_info: Dictionary = {}

@export var prj_area: Area2D

func _ready() -> void:
	if !prj_area and $Area2D: prj_area = $Area2D
	prj_area.area_entered.connect(on_hit)
	
	scale = Vector2.ONE * prj_info["size"]
	
	if team == 0:
		$OTHER.queue_free()
	else:
		$PLAYER.queue_free()
	
	check_dist_to_center()

func _process(delta: float) -> void:
	velocity = Vector2.from_angle(global_rotation) * prj_info["speed"] * delta
	global_position += velocity
	if in_arena and dist_from_center > GlobalClass.ESTIMATED_ARENA_RADIUS * in_arena.scale.x:
		queue_free()

func on_hit(area: Area2D) -> void:
	var cluster: Cluster
	if area is Cluster: 
		cluster = area
	else: 
		return
	if cluster.team != team:
		cluster.recieve_hit(prj_info["dmg_info"])
		
		# VFX
		cluster.blink()
		
		var fx: Node2D
		if prj_info.has("hit_fx"):
			fx = load(prj_info["hit_fx"]).instantiate()
		else:
			fx = GlobalClass.DEFAULT_HIT_FX.instantiate()
		fx.global_position = global_position
		fx.scale = scale
		GlobalClass.world.add_child(fx)
		
		# SFX
		GlobalClass.play_sound("uid://br055er0cj176")
		
		queue_free()

func check_dist_to_center() -> void:
	if in_arena: dist_from_center = global_position.distance_to(in_arena.global_position)
	get_tree().create_timer(GlobalClass.CLUSTER_CHECK_DIST_FREQ).timeout.connect(check_dist_to_center)
