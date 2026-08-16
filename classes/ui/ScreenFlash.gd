extends ColorRect
class_name ScreenFlash

signal deleted()

@export var flash_duration: float = 2.0

func _ready() -> void:
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func flash() -> void:
	modulate.a = 1.0
	create_tween().tween_property(
		self, 
		"modulate:a", 
		0.0, 
		flash_duration
	).finished.connect(
		func() -> void:
			deleted.emit()
			queue_free()
	)
