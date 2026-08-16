extends Part
class_name PoppablePart

@export_enum(
	"projectiles",
	"other"
) var split_mode: String = "projectiles"
@export var split_into: PackedScene
@export var split_amount: int = 1
