extends Node2D
class_name World

var mid_battle: bool = false

var dynamic_cam: DynamicCamera = DynamicCamera.new()
@onready var start_arena: Arena = $Arena

func _ready() -> void:
	GlobalClass.world = self
	
	generate_arena()
	
	add_child(dynamic_cam)
	
	for c in get_clusters():
		c.in_arena = start_arena
		c.killed.connect(check_battle_state)
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
	cluster.in_arena = start_arena
	cluster.team = 0
	for p in cluster.get_parts():
		p.disabled = false
	GlobalClass.player_cluster.queue_free()
	GlobalClass.player_cluster = cluster
	add_child(cluster)
	dynamic_cam.anchor = cluster

func spawn_as_enemy(cluster: Cluster) -> void:
	cluster.team = 1
	cluster.in_arena = start_arena
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
