extends Node2D
class_name World

var mid_battle: bool = false

var arenas_travelled: int = 0
var player_max_class: int = 1
var player_gun_points: int = 1
var player_progression_requirement: int = GlobalClass.PROGRESSION_REQUIREMENTS[0]

@onready var start_arena: Arena = $Arena

@onready var ui: GameUI = $UI

var dynamic_cam: DynamicCamera = DynamicCamera.new()

func _ready() -> void:
	GlobalClass.world = self
	
	generate_arena()
	
	add_child(dynamic_cam)
	
	for c in get_clusters():
		c.in_arena = start_arena
		if c.team == 0:
			dynamic_cam.anchor = c
	
	mid_battle = true

func generate_arena() -> void:
	pass

func get_clusters() -> Array[Cluster]:
	var list: Array[Cluster] = []
	
	for c in get_children():
		if c is Cluster:
			list.append(c)
	
	return list

func get_arenas() -> Array[Arena]:
	var list: Array[Arena] = []
	
	for c in get_children():
		if c is Arena:
			list.append(c)
	
	return list

func transform_player_into(cluster: Cluster) -> void:
	cluster.global_position = GlobalClass.player_cluster.global_position
	cluster.global_rotation = GlobalClass.player_cluster.global_rotation
	cluster.velocity = GlobalClass.player_cluster.velocity
	cluster.in_arena = GlobalClass.player_cluster.in_arena
	cluster.team = 0
	cluster.max_progress = player_progression_requirement
	for p in cluster.get_parts():
		p.disabled = false
	GlobalClass.player_cluster.queue_free()
	GlobalClass.player_cluster = cluster
	add_child(cluster)
	dynamic_cam.anchor = cluster

func spawn_as_enemy(cluster: Cluster) -> void:
	cluster.team = 1
	cluster.in_arena = GlobalClass.player_cluster.in_arena
	for p in cluster.get_parts():
		p.disabled = false
	add_child(cluster)

func check_battle_state() -> void:
	await get_tree().create_timer(0.1).timeout
	for c in get_clusters():
		if c.team != 0:
			mid_battle = true
			return
	mid_battle = false

func transfer_player_to_next_arena(angle: float = 0.0) -> void:
	arenas_travelled += 1
	GlobalClass.player_cluster.velocity = Vector2.ZERO
	
	for c in get_clusters():
		if c.team != 0:
			c.queue_free()
	
	var new_arena: Arena = GlobalClass.ARENA_TEMPLATE.instantiate()
	new_arena.global_position = GlobalClass.player_cluster.in_arena.global_position + Vector2.RIGHT.rotated(angle) * GlobalClass.ESTIMATED_ARENA_RADIUS + Vector2.RIGHT.rotated(angle) * GlobalClass.DISTANCE_BETWEEN_ARENAS
	new_arena.scale = GlobalClass.DEFAULT_ARENA_SCALE
	add_child(new_arena)
	
	GlobalClass.player_cluster.enabled = false
	await create_tween().tween_property(
		GlobalClass.player_cluster, 
		"global_position", 
		new_arena.global_position + Vector2.LEFT.rotated(angle) * GlobalClass.ESTIMATED_ARENA_RADIUS / 4, 
		1).set_trans(Tween.TRANS_CIRC).finished
	
	GlobalClass.player_cluster.in_arena.queue_free()
	GlobalClass.player_cluster.in_arena = new_arena
	
	await get_tree().create_timer(0.1).timeout
	
	GlobalClass.player_cluster.enabled = true
	new_arena.spawn_enemies()
	
func upgrade_player() -> void:
	player_max_class += 1
	player_gun_points += 1
	GlobalClass.player_cluster.progress = 0
	ui.editor.toggle_editor(true)
