extends CanvasLayer
class_name GameUI

@onready var hud: HUD = $HUD
@onready var editor: Editor = $Editor

func toggle_editor(value: bool) -> void:
	if editor.mid_transition: return
	editor.mid_transition = true
	if value:
		editor.enabled = true
		editor.modulate.a = 0.0
		await create_tween().tween_property(editor, "modulate:a", 1.0, 0.5).finished
		editor.mid_transition = false
	else:
		editor.enabled = false
		editor.modulate.a = 1.0
		await create_tween().tween_property(editor, "modulate:a", 0.0, 0.5).finished
		editor.mid_transition = false
