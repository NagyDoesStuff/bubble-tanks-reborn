extends Node
## No need for a class_name, this is an autoload script.

# PRELOADS
const BUTTON_01: PackedScene = preload("uid://dwlqr56nh4exq")

const BUBBLE_POINT: PackedScene = preload("uid://ckebyrul4e710")

const ARENA_TEMPLATE: PackedScene = preload("uid://dylq1171myx2n")

# CONSTANTS
const ARENA_PUSH_FORCE: int = 100
const HIT_BLINK_TIME: int = 6
const DISTANCE_BETWEEN_ARENAS: int = 200
const DEFAULT_MAX_ENEMIES: int = 6
const MAX_CLASS: int = 6

const CLUSTER_CHECK_DIST_FREQ: float = .25
const ESTIMATED_ARENA_RADIUS: float = 8505.0 / 2.0
const LAND_ON_ARENA_DIST: float = ESTIMATED_ARENA_RADIUS * 0.5
const MIN_BUBBLE_POINT_SIZE: float = 0.5
const BUBBLE_POINT_GROW_SIZE: float = 0.025
const MAX_ENEMIES_INCREMENT_PER_ARENA: float = 0.2

const PARTS_DIRECTORY: String = "res://scenes/parts/"
const EDITOR_SAVES_DIRECTORY: String = "res://editor/"

const HIT_COLOR: Color = Color(1.164, 1.164, 1.164, 1.0)

const DEFAULT_ARENA_SCALE: Vector2 = Vector2.ONE * 0.33

const PROGRESSION_REQUIREMENTS: Array[int] = [
	50, # CLASS 2
	100, # CLASS 3
	150, # CLASS 4 
	250, # CLASS 5
	400, # CLASS 6
	1000 # MAX
]

# NODES
var world: World
var player_cluster: Cluster
var loaded_clusters: Array[Cluster]

func _ready() -> void:
	load_clusters()

func get_closest(from: Node2D, list: Array) -> Node2D:
	var dist: float
	var best_dist: float = INF
	var best: Node2D = null
	for item: Node2D in list:
		dist = from.global_position.distance_to(item.global_position)
		if dist < best_dist:
			best_dist = dist
			best = item
	return best

func play_sound(
	file_path: String, 
	volume_db: float = 0.0, 
	pitch_scale: float = 1.0, 
	pitch_variation: float = 0.0, 
	volume_variation: float = 0.0, 
) -> AudioStreamPlayer2D:
	if file_path.is_empty(): return
	var pitch: float = pitch_scale + randf_range(-pitch_variation, pitch_variation)
	var vol: float = volume_db + randf_range(-volume_variation, volume_variation)
	var audio_node: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	get_tree().root.add_child(audio_node)
	audio_node.stream = load(file_path)
	audio_node.volume_db = vol
	audio_node.pitch_scale = pitch
	audio_node.max_distance = 999999
	audio_node.panning_strength = 0.0
	audio_node.process_mode = Node.PROCESS_MODE_ALWAYS
	audio_node.play()
	audio_node.finished.connect(audio_node.queue_free)
	return audio_node

func dice(amount: int, out_of: int) -> bool:
	if randi_range(0, out_of) <= amount:
		return true
	else:
		return false

func freeze_frame(time: float) -> void:
	get_tree().paused = true
	await get_tree().create_timer(time).timeout
	get_tree().paused = false

	# func make_dmg_num_text(on: Cluster, dmg: float) -> void:
		# var floating_text: FloatingText = FloatingText.new()
		# floating_text.text = str(int(dmg))
		# floating_text.label_settings = load("res://godot_resources/taunt_label_settings_template.tres").duplicate()
		# floating_text.label_settings.font_color = Color.RED
		# floating_text.global_position = on.global_position
		# floating_text.velocity = on.linear_velocity * global_delta
		# arena.add_child(floating_text)

func load_clusters() -> void:
	for file in ResourceLoader.list_directory(EDITOR_SAVES_DIRECTORY + "saved_tanks/"):
		var cluster: Cluster = load(EDITOR_SAVES_DIRECTORY + "saved_tanks/" + file).instantiate()
		loaded_clusters.append(cluster)
