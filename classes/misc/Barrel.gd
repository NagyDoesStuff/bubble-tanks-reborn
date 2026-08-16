extends Node2D
class_name GunBarrel

var muted: bool = false

# "template" is the projectile scene file.
# "dmg_info" types: "dmg", "slowdown" and "jam"
# "targ_mode" modes: "default" and "mouse"

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
	"targ_mode": "default"
}

@onready var gun: GunPart = get_parent()

func _ready() -> void:
	if gun.disabled or !gun.user: return
	
	if gun.user.team != 0:
		muted = true

func shoot() -> void:
	if gun.user.is_jammed: return
	
	if !muted:
		GlobalClass.play_sound("uid://dfx02l3ac3xjd")
	
	var prj: Projectile = load(prj_info["template"]).instantiate()
	prj.global_position = global_position
	prj.global_rotation = global_rotation
	prj.prj_info = prj_info
	prj.team = gun.user.team
	GlobalClass.world.add_child(prj)
