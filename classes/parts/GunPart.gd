extends Part
class_name GunPart

@export var cooldown: float = 0.5
@export var shoot_fx: String = "uid://dfx02l3ac3xjd"
@export var spread: float = 0.0
@export var amount_per_salvo: int = 1
@export var salvo_interval: float = 0.0
@export_enum(
	"lmb",
	"space"
) var keybind: String = "lmb"
@export var fixed: bool = false
var can_shoot: bool = true

@export var full_turn_amount: int = 0

var barrels: Array[GunBarrel]

func _subready() -> void:
	barrels = get_barrels()

func _process(_delta: float) -> void:
	if !user or disabled or !user.enabled: return
	
	if user.team == 0:
		if user.cluster_class >= 4 and !fixed:
			look_at(get_global_mouse_position())
		if can_shoot and Input.is_action_pressed(keybind):
			fire_all_barrels()
	elif GlobalClass.player_cluster:
		if !fixed: look_at(GlobalClass.player_cluster.global_position)
		if can_shoot: fire_all_barrels()

func get_barrels() -> Array[GunBarrel]:
	var list: Array[GunBarrel] = []
	
	for c in get_children():
		if c is GunBarrel:
			list.append(c)
	
	return list

func fire_all_barrels() -> void:
	for b in barrels:
		b.shoot()
	can_shoot = false
	get_tree().create_timer(cooldown).timeout.connect(set.bind("can_shoot", true))
	for x in range(full_turn_amount):
		await create_tween().tween_property(self, "rotation", TAU, amount_per_salvo * salvo_interval).finished
		rotation = init_rotation
