extends Node2D
class_name GunBarrel

var muted: bool = false
@export var prj_info: Dictionary = {
	"template": "uid://cnlneqp8i4qud",
	"dmg_info": {
		"type": "dmg",
		"amount": 1
	},
	"speed": 2000.0,
	"size": 1.0,
	"hit_fx": "uid://bwddu713otuhv",
	"homing": false
}

@onready var gun: GunPart = get_parent()

func _ready() -> void:
	if gun.disabled or !gun.user: return
	
	if gun.user.team != 0:
		muted = true

func shoot() -> void:
	if !muted:
		GlobalClass.play_sound("uid://dfx02l3ac3xjd")
	
	var prj: Projectile = load(prj_info["template"]).instantiate()
	prj.global_position = global_position
	prj.global_rotation = global_rotation
	prj.prj_info = prj_info
	prj.team = gun.user.team
	GlobalClass.world.add_child(prj)
