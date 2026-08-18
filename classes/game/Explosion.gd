extends Area2D
class_name Explosion

@export var dmg_info: Dictionary = {
	"type": "dmg",
	"amount": 0,
	"duration": 0.0
}
@export var lifetime: float = 0.1
@export var radius: float = 0.0
var team: int = 0

func _ready() -> void:
	area_entered.connect(deal_dmg)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	
	var col: CollisionShape2D = CollisionShape2D.new()
	col.shape = CircleShape2D.new()
	col.shape.radius = radius
	add_child(col)
	
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func deal_dmg(area: Node2D):
	if area is Cluster and area.team != team:
		area.recieve_hit(dmg_info)
