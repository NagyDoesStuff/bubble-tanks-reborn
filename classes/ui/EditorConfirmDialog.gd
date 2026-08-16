extends Control
class_name EditorConfirmDialog

@onready var ignore_button: Button = $MarginContainer/VBoxContainer/Options/MarginContainer/HBoxContainer/Ignore
@onready var go_to_editor_button: Button = $MarginContainer/VBoxContainer/Options/MarginContainer/HBoxContainer/GoToEditor

func _ready() -> void:
	configure_signals()
	hide()

func activate() -> void:
	modulate.a = 0.0
	show()
	GlobalClass.player_cluster.enabled = false
	create_tween().tween_property(self, "modulate:a", 1.0, 1.0)

func configure_signals() -> void:
	go_to_editor_button.pressed.connect(go_to_editor)
	ignore_button.pressed.connect(ignore)

func ignore() -> void:
	hide()
	GlobalClass.player_cluster.enabled = true

func go_to_editor() -> void:
	hide()
	GlobalClass.world.last_player_position = GlobalClass.player_cluster.global_position
	GlobalClass.world.ui.toggle_editor(true)
	GlobalClass.world.ui.hud.hide()
	GlobalClass.world.ui.editor.load_cluster(GlobalClass.player_cluster_filename)
