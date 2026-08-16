extends Control
class_name PauseMenu

@onready var resume_button: Button = $MarginContainer/VBoxContainer/Options/MarginContainer/HBoxContainer/Resume
@onready var main_menu_button: Button = $MarginContainer/VBoxContainer/Options/MarginContainer/HBoxContainer/MainMenu

var paused: bool = false

func _ready() -> void:
	configure_signals()
	hide()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		toggle()

func toggle() -> void:
	visible = !visible
	get_tree().paused = !get_tree().paused

func configure_signals() -> void:
	resume_button.pressed.connect(toggle)
	main_menu_button.pressed.connect(
		func () -> void:
			get_tree().paused = false
			get_tree().change_scene_to_file("uid://bkalqiq76isn0")
	)
