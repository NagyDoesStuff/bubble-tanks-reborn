extends Node2D
class_name GunBarrel

@export var muted: bool = false

# "template" is the projectile scene file
# "dmg_info" types: "dmg", "slowdown" and "jam"
# "targ_mode" modes: "default" and "mouse"
# "turn_mode" modes: "default" and "sin"

@export var prj_info: Dictionary = {
	# Normal attributes.
	"template": "uid://cnlneqp8i4qud",
	"dmg_info": {
		"type": "dmg",
		"duration": 0.0,
		"amount": 1.0
	},
	"speed": 2000.0,
	"size": 1.0,
	"hit_fx": "uid://bwddu713otuhv",
	# Homing attributes.
	"homing": false,
	"turn_rate": 10.0,
	"targ_mode": "default",
	# Turning attributes.
	"turn_mode": "default",
	"sin_turn_mode_freq": 3.0
}

@onready var gun: GunPart = get_parent()

func _ready() -> void:
	if gun.disabled or !gun.user: return
	
	if gun.user.team != 0:
		muted = true

func shoot() -> void:
	if gun.user.is_jammed: return
	
	if !muted and gun.salvo_interval == 0.0:
		GlobalClass.play_sound(gun.shoot_fx)
	
	for x in range(gun.amount_per_salvo):
		var prj: Projectile = load(prj_info["template"]).instantiate()
		prj.global_position = global_position
		prj.global_rotation = global_rotation + randf_range(-gun.spread, gun.spread)
		prj.prj_info = prj_info
		prj.team = gun.user.team
		GlobalClass.world.add_child(prj)
		
		if gun.salvo_interval > 0.0:
			if !muted:
				GlobalClass.play_sound(gun.shoot_fx)
			await get_tree().create_timer(gun.salvo_interval).timeout
