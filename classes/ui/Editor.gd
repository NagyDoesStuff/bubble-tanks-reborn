extends Control
class_name Editor

@export var debug: bool = false

const MIRROR_Y: int = 515

var enabled: bool = false
var mid_transition: bool = false
var symmetry: bool = true

@onready var last_dragged_part_indicator: Sprite2D = $SelectIcon

@onready var part_list_display_container: VBoxContainer = $HBoxContainer/VBoxContainer2/List/MarginContainer/ScrollContainer/VBoxContainer

@onready var drag_and_drop_container: MarginContainer = $HBoxContainer/VBoxContainer2/DragAndDrop/MarginContainer

@onready var cluster_display_container: Panel = $HBoxContainer/VBoxContainer/Display

@onready var drag_button: Button = $HBoxContainer/VBoxContainer2/DragAndDrop/Button
@onready var delete_button: Button = $HBoxContainer/VBoxContainer/Options/MarginContainer/HBoxContainer/DeleteButton
@onready var move_up_button: Button = $HBoxContainer/VBoxContainer/Options/MarginContainer/HBoxContainer/MoveUpButton
@onready var move_down_button: Button = $HBoxContainer/VBoxContainer/Options/MarginContainer/HBoxContainer/MoveDownButton
@onready var center_part_button: Button = $HBoxContainer/VBoxContainer/Options/MarginContainer/HBoxContainer/CenterPartButton

@onready var save_button: TextureButton = $HBoxContainer/Panel/MarginContainer/VBoxContainer/SaveButton
@onready var load_button: TextureButton = $HBoxContainer/Panel/MarginContainer/VBoxContainer/LoadButton
@onready var clear_button: TextureButton = $HBoxContainer/Panel/MarginContainer/VBoxContainer/ClearButton

@onready var cluster_name_input: LineEdit = $HBoxContainer/VBoxContainer/ClusterName
@onready var load_cluster_input: LineEdit = $HBoxContainer/Panel/LoadClusterName
@onready var cluster_team_edit: LineEdit = $HBoxContainer/VBoxContainer2/TankInfo/MarginContainer/VBoxContainer/TeamEdit
@onready var cluster_hp_edit: LineEdit = $HBoxContainer/VBoxContainer2/TankInfo/MarginContainer/VBoxContainer/HPEdit
@onready var cluster_drop_edit: LineEdit = $HBoxContainer/VBoxContainer2/TankInfo/MarginContainer/VBoxContainer/DropEdit
@onready var cluster_speed_edit: LineEdit = $HBoxContainer/VBoxContainer2/TankInfo/MarginContainer/VBoxContainer/SpeedEdit
@onready var cluster_min_available_edit: LineEdit = $HBoxContainer/VBoxContainer2/TankInfo/MarginContainer/VBoxContainer/MinAvailableEdit
@onready var cluster_turn_rate_edit: LineEdit = $HBoxContainer/VBoxContainer2/TankInfo/MarginContainer/VBoxContainer/TurnRateEdit

@onready var scale_slider: HSlider = $HBoxContainer/VBoxContainer/Options/MarginContainer/HBoxContainer/VBoxContainer/ScaleSlider
@onready var rotation_slider: HSlider = $HBoxContainer/VBoxContainer/Options/MarginContainer/HBoxContainer/VBoxContainer2/RotationSlider

@onready var symmetry_button: CheckButton = $HBoxContainer/VBoxContainer/Options/MarginContainer/HBoxContainer/SymmetryButton

var selected_part_path: String:
	set(value):
		selected_part_path = value
		display_selected_part(load(selected_part_path).instantiate())

var selected_part_type: Part

var dragged_part_path: String:
	set(value):
		dragged_part_path = value
		create_dragged_part(dragged_part_path)

var dragged_part: Part

var mirror_part: Part

var last_dragged: Part

var edited_cluster: Cluster

func _ready() -> void:
	if debug:
		enabled = true
		modulate.a = 1.0
	else:
		modulate.a = 0.0
	
	retrieve_avaliable_parts(GlobalClass.PARTS_DIRECTORY)
	
	await get_tree().process_frame
	
	create_edited_cluster(Cluster.new())
	
	editor_dir_analysis()
	
	configure_signals()
	
func _process(_delta: float) -> void:
	if !enabled: return
	
	if dragged_part:
		dragged_part.global_position = get_global_mouse_position()
		if symmetry and mirror_part:
			mirror_part.global_position.x = dragged_part.global_position.x
			mirror_part.global_position.y = MIRROR_Y * 2 - dragged_part.global_position.y
	
	if last_dragged:
		last_dragged_part_indicator.global_position = last_dragged.global_position
	
	if Input.is_action_just_pressed("lmb"):
		attempt_to_drag()
	
	if Input.is_action_just_released("lmb"):
		dragged_part = null
		mirror_part = null
	
	if Input.is_action_just_pressed("enter") and !load_cluster_input.text.is_empty() and load_cluster_input.visible:
		load_cluster_input.hide()
		load_cluster(load_cluster_input.text)

func retrieve_avaliable_parts(dir: String) -> void:
	for subdir in ResourceLoader.list_directory(dir):
		for file in ResourceLoader.list_directory(dir + subdir):
			var full_path: String = dir + subdir + file
			make_part_select_button(full_path, part_list_display_container)

func make_part_select_button(part_path: String, parent: Control) -> void:
	var button: Button = GlobalClass.BUTTON_01.instantiate()
	var unpacked_part: Part = load(part_path).instantiate()
	button.text = unpacked_part.name
	button.pressed.connect(set.bind("selected_part_path", part_path))
	parent.add_child(button)
	unpacked_part.queue_free()
	print("Loaded path from: " + part_path)

func display_selected_part(part: Part) -> void:
	if !enabled: return
	
	if selected_part_type: selected_part_type.queue_free()
	part.disabled = true
	part.global_position = drag_and_drop_container.global_position + drag_and_drop_container.size / 2
	selected_part_type = part
	add_child(part)
	print("Displayed new part: " + part.name)

func create_dragged_part(part_path: String) -> Part:
	if !enabled: return
	
	var part: Part = load(part_path).instantiate()
	part.editor_mode = true
	part.disabled = true
	dragged_part = part
	last_dragged = dragged_part
	edited_cluster.add_child(part)
	part.owner = edited_cluster
	
	if symmetry:
		var part2: Part = dragged_part.duplicate()
		part2.editor_mode = true
		part2.disabled = true
		mirror_part = part2
		edited_cluster.add_child(part2)
	
	return part

func update_dragged_part_path() -> void:
	if !enabled: return
	if !selected_part_path: return
	dragged_part_path = selected_part_path

func editor_dir_analysis() -> void: 
	if !DirAccess.dir_exists_absolute(GlobalClass.EDITOR_SAVES_DIRECTORY):
		DirAccess.make_dir_absolute(GlobalClass.EDITOR_SAVES_DIRECTORY + "saved_tanks/")
	
func save_cluster() -> void:
	if !enabled: return
	var init_cluster_pos: Vector2 = edited_cluster.global_position
	edited_cluster.global_position = Vector2.ZERO
	
	var saved: PackedScene = PackedScene.new()
	saved.pack(edited_cluster)
	
	edited_cluster.global_position = init_cluster_pos
	
	if !debug:
		GlobalClass.world.ui.toggle_editor(false)
		GlobalClass.world.ui.hud.show()
		GlobalClass.world.transform_player_into(edited_cluster)
	
	if FileAccess.file_exists(GlobalClass.EDITOR_SAVES_DIRECTORY + "saved_tanks/" + edited_cluster.name + ".tscn"):
		randomize()
		edited_cluster.name += str(randi())
	var error = ResourceSaver.save(saved, GlobalClass.EDITOR_SAVES_DIRECTORY + "saved_tanks/" + edited_cluster.name + ".tscn")
	if error == OK:
		print("Saved " + str(saved) + "at path: " + GlobalClass.EDITOR_SAVES_DIRECTORY + "saved_tanks/" + edited_cluster.name + ".tscn")
	else:
		print("Saving failed.")

func update_cluster_name(text: String) -> void:
	edited_cluster.name = text

func create_edited_cluster(cluster: Cluster) -> void:
	if edited_cluster:
		edited_cluster.queue_free()
	edited_cluster = cluster
	edited_cluster.global_rotation = 0.0
	edited_cluster.enabled = false
	edited_cluster.global_position = cluster_display_container.global_position + cluster_display_container.size / 2
	cluster_name_input.text = edited_cluster.name
	cluster_team_edit.text = str(edited_cluster.team)
	cluster_hp_edit.text = str(edited_cluster.max_progress)
	cluster_speed_edit.text = str(edited_cluster.speed)
	cluster_drop_edit.text = str(edited_cluster.drop_value)
	cluster_min_available_edit.text = str(edited_cluster.min_to_available)
	cluster_turn_rate_edit.text = str(edited_cluster.turn_rate)
	
	for p in edited_cluster.get_parts():
		p.disabled = true
		p.editor_mode = true
	call_deferred("add_child", edited_cluster)

func load_cluster(text: String) -> void:
	if !enabled: return
	var full_path: String = GlobalClass.EDITOR_SAVES_DIRECTORY + "saved_tanks/" + text + ".tscn"
	if FileAccess.file_exists(full_path):
		create_edited_cluster(load(full_path).instantiate())
		load_cluster_input.hide()

func toggle_load_input() -> void:
	if !enabled: return
	load_cluster_input.visible = !load_cluster_input.visible

func attempt_to_drag() -> void:
	if !enabled: return
	for c in edited_cluster.get_parts():
		if c.is_hovered:
			dragged_part = c
			last_dragged = c
			break

func update_cluster_float_with_line_edit(_text: String, variable: String, line_edit: LineEdit) -> void:
	if !enabled: return
	edited_cluster.set(variable, line_edit.text.to_float())

func configure_signals() -> void:
	drag_button.button_down.connect(update_dragged_part_path)
	save_button.pressed.connect(save_cluster)
	load_button.pressed.connect(toggle_load_input)
	clear_button.pressed.connect(clear_cluster)
	
	delete_button.pressed.connect(delete_last_dragged)
	move_up_button.pressed.connect(move_last_dragged_up)
	move_down_button.pressed.connect(move_last_dragged_down)
	center_part_button.pressed.connect(center_last_dragged)
	
	cluster_name_input.text_changed.connect(update_cluster_name)
	cluster_team_edit.text_changed.connect(
		update_cluster_float_with_line_edit.bind("team", cluster_team_edit))
	cluster_hp_edit.text_changed.connect(
		update_cluster_float_with_line_edit.bind("max_progress", cluster_hp_edit))
	cluster_drop_edit.text_changed.connect(
		update_cluster_float_with_line_edit.bind("drop_value", cluster_drop_edit))
	cluster_speed_edit.text_changed.connect(
		update_cluster_float_with_line_edit.bind("speed", cluster_speed_edit))
	cluster_min_available_edit.text_changed.connect(
		update_cluster_float_with_line_edit.bind("min_to_available", cluster_min_available_edit))
	cluster_turn_rate_edit.text_changed.connect(
		update_cluster_float_with_line_edit.bind("turn_rate", cluster_turn_rate_edit))
	
	scale_slider.value_changed.connect(scale_last_dragged)
	rotation_slider.value_changed.connect(rotate_last_dragged)
	
	symmetry_button.pressed.connect(toggle_symmetry)

func delete_last_dragged() -> void:
	if last_dragged: last_dragged.queue_free()

func move_last_dragged_up() -> void:
	if last_dragged: edited_cluster.move_child(last_dragged, last_dragged.get_index() + 1)

func move_last_dragged_down() -> void:
	if last_dragged: edited_cluster.move_child(last_dragged,last_dragged .get_index() - 1)

func scale_last_dragged(value: float) -> void:
	if last_dragged: last_dragged.scale = Vector2.ONE * value

func rotate_last_dragged(value: float) -> void:
	if last_dragged: last_dragged.rotation_degrees = value

func toggle_symmetry() -> void:
	symmetry = !symmetry

func center_last_dragged() -> void:
	if last_dragged: last_dragged.global_position.y = MIRROR_Y

func clear_cluster() -> void:
	create_edited_cluster(Cluster.new())
