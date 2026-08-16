extends Control
class_name MainMenu

@onready var title: Label = $Title

@onready var buttons_container: Control = $Buttons

@onready var play_button: TextureButton = $Buttons/PlayButton
@onready var debug_editor_button: TextureButton = $Buttons/HBoxContainer/DebugEditorButton
@onready var exit_button: TextureButton = $Buttons/HBoxContainer/ExitButton
@onready var credits_button: TextureButton = $Buttons/HBoxContainer/CreditsButton

func _ready() -> void:
	buttons_container.hide()
	configure_buttons()
	do_intro()

func do_intro() -> void:
	await create_tween().tween_property(title, "global_position:y", 200, 2.0).set_trans(Tween.TRANS_EXPO).finished
	
	var flash: ScreenFlash = GlobalClass.SCREEN_FLASH.instantiate()
	flash.color = Color(1.0, 1.0, 1.0, 0.784)
	add_child(flash)
	flash.flash()
	
	buttons_container.show()

func configure_buttons() -> void:
	play_button.pressed.connect(get_tree().change_scene_to_file.bind("uid://cr1hv48vvi5cd"))
	debug_editor_button.pressed.connect(get_tree().change_scene_to_file.bind("uid://dwgmerdems35x"))
	exit_button.pressed.connect(get_tree().quit)
