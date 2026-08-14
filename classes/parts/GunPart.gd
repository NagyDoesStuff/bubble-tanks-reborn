extends Part
class_name GunPart

@export var cooldown: float = 0.5
var can_shoot: bool = true

var barrels: Array[GunBarrel]

func _subready() -> void:
	barrels = get_barrels()

func _process(_delta: float) -> void:
	if !user or disabled: return
	
	if user.team == 0:
		if user.cluster_class >= 4:
			look_at(get_global_mouse_position())
		if can_shoot and Input.is_action_pressed("lmb"):
			fire_all_barrels()
	elif GlobalClass.player_cluster:
		look_at(GlobalClass.player_cluster.global_position)
		if can_shoot:
			fire_all_barrels()

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
