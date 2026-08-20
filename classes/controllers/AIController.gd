extends Controller
class_name AIController

@onready var targ: Cluster = GlobalClass.player_cluster
var min_freq: float = 1.0
var max_freq: float = 2.0
var turn_dir: int = 0
var min_turn_time_ratio: float = 0.25
var max_turn_time_ratio: float = 0.5
var run_to_center_margin: float = GlobalClass.ESTIMATED_ARENA_RADIUS * 0.75
var run_to_center_mult: float = 2.0
