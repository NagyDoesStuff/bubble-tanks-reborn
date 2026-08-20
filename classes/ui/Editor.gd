extends Control
class_name Editor

@onready var last_dragged_part_indicator: Sprite2D = $SelectIcon

@onready var drag_and_drop_container: Panel = $HBoxContainer/VBoxContainer2/DragAndDrop
@onready var cluster_display_container: Panel = $HBoxContainer/VBoxContainer/Display
@onready var tank_info_container: Panel = $HBoxContainer/VBoxContainer2/TankInfo

@onready var drag_button: Button = $HBoxContainer/VBoxContainer2/DragAndDrop/Button
@onready var delete_button: Button = $HBoxContainer/VBoxContainer/Options/MarginContainer/HBoxContainer/DeleteButton
@onready var move_up_button: Button = $HBoxContainer/VBoxContainer/Options/MarginContainer/HBoxContainer/MoveUpButton
@onready var move_down_button: Button = $HBoxContainer/VBoxContainer/Options/MarginContainer/HBoxContainer/MoveDownButton
@onready var center_part_button: Button = $HBoxContainer/VBoxContainer/Options/MarginContainer/HBoxContainer/CenterPartButton
@onready var move_top_button: Button = $HBoxContainer/VBoxContainer/Options/MarginContainer/HBoxContainer/MoveTopButton

@onready var save_button: TextureButton = $HBoxContainer/Panel/MarginContainer/VBoxContainer/SaveButton
@onready var load_button: TextureButton = $HBoxContainer/Panel/MarginContainer/VBoxContainer/LoadButton
@onready var clear_button: TextureButton = $HBoxContainer/Panel/MarginContainer/VBoxContainer/ClearButton
@onready var exit_button: TextureButton = $HBoxContainer/Panel/MarginContainer/VBoxContainer/ExitButton

@onready var cluster_name_input: LineEdit = $HBoxContainer/VBoxContainer/ClusterName
@onready var load_cluster_input: LineEdit = $HBoxContainer/Panel/LoadClusterName
@onready var cluster_team_edit: LineEdit = $HBoxContainer/VBoxContainer2/TankInfo/MarginContainer/VBoxContainer/TeamEdit
@onready var cluster_hp_edit: LineEdit = $HBoxContainer/VBoxContainer2/TankInfo/MarginContainer/VBoxContainer/HPEdit
@onready var cluster_drop_edit: LineEdit = $HBoxContainer/VBoxContainer2/TankInfo/MarginContainer/VBoxContainer/DropEdit
@onready var cluster_speed_edit: LineEdit = $HBoxContainer/VBoxContainer2/TankInfo/MarginContainer/VBoxContainer/SpeedEdit
@onready var cluster_min_available_edit: LineEdit = $HBoxContainer/VBoxContainer2/TankInfo/MarginContainer/VBoxContainer/MinAvailableEdit
@onready var cluster_turn_rate_edit: LineEdit = $HBoxContainer/VBoxContainer2/TankInfo/MarginContainer/VBoxContainer/TurnRateEdit
@onready var cluster_max_spawn_edit: LineEdit = $HBoxContainer/VBoxContainer2/TankInfo/MarginContainer/VBoxContainer/MaxSpawnEdit

@onready var scale_slider: HSlider = $HBoxContainer/VBoxContainer/Options/MarginContainer/HBoxContainer/VBoxContainer/ScaleSlider
@onready var rotation_slider: HSlider = $HBoxContainer/VBoxContainer/Options/MarginContainer/HBoxContainer/VBoxContainer2/RotationSlider

@onready var symmetry_button: CheckButton = $HBoxContainer/VBoxContainer/Options/MarginContainer/HBoxContainer/SymmetryButton

@onready var info_label: Label = $HBoxContainer/VBoxContainer/Display/MarginContainer/Label
@onready var gp_usage_count: Label = $HBoxContainer/VBoxContainer2/DragAndDrop/GPUsageCount

@onready var category_tab_container: TabContainer = $HBoxContainer/VBoxContainer2/List/MarginContainer/ScrollContainer/TabContainer

@export var debug: bool = true

var enabled: bool = false
var mid_transition: bool = false
var symmetry: bool = true

var available_gp: int = 0

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

var last_dragged: Part

var edited_cluster: Cluster

func _ready() -> void:
	await get_tree().process_frame
	
	if debug:
		enabled = true
		modulate.a = 1.0
	else:
		modulate.a = 0.0
		tank_info_container.hide()
		exit_button.hide()
	
	make_category_containers()
	
	retrieve_avaliable_parts(GlobalClass.PARTS_DIRECTORY)
	
	create_template()
	
	configure_signals()
	
func _process(_delta: float) -> void:
	if !enabled: return
	
	last_dragged_part_indicator.visible = is_instance_valid(dragged_part)
	
	if dragged_part and !Input.is_action_pressed("ctrl"):
		dragged_part.global_position = get_global_mouse_position()
		if symmetry and dragged_part.linked_via_editor:
			dragged_part.linked_via_editor.global_position.x = dragged_part.global_position.x
			dragged_part.linked_via_editor.global_position.y = edited_cluster.global_position.y * 2.0 - dragged_part.global_position.y
	
	if last_dragged:
		last_dragged_part_indicator.global_position = last_dragged.global_position
	
	if Input.is_action_just_pressed("lmb"):
		attempt_to_drag()
	
	if Input.is_action_just_released("lmb"):
		stop_dragging()
	
	if Input.is_action_just_pressed("enter") and !load_cluster_input.text.is_empty() and load_cluster_input.visible:
		load_cluster_input.hide()
		load_cluster(load_cluster_input.text)
	
	if Input.is_action_just_pressed("del"):
		delete_last_dragged()

func retrieve_avaliable_parts(dir: String) -> void:
	for subdir in ResourceLoader.list_directory(dir):
		for file in ResourceLoader.list_directory(dir + subdir):
			var full_path: String = dir + subdir + file
			make_part_select_button(full_path)

func make_part_select_button(part_path: String) -> void:
	var button: Button = GlobalClass.BUTTON_01.instantiate()
	var unpacked_part: Part = load(part_path).instantiate()
	button.text = unpacked_part.name
	button.pressed.connect(set.bind("selected_part_path", part_path))
	category_tab_container.get_node(unpacked_part.category).add_child(button)
	unpacked_part.queue_free()
	print("Loaded path from: " + part_path)

func display_selected_part(part: Part) -> void:
	if !enabled: return
	
	if selected_part_type: selected_part_type.queue_free()
	part.disabled = true
	part.global_position = drag_and_drop_container.global_position + drag_and_drop_container.size / 2
	selected_part_type = part
	add_child(part)
	
	if part.gp_usage > 0:
		gp_usage_count.text = "Uses: " + str(part.gp_usage) + " GP"
	else:
		gp_usage_count.text = "Doesn't use GP."
	
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
		var mirror_part: Part = dragged_part.duplicate()
		mirror_part.editor_mode = true
		mirror_part.disabled = true
		edited_cluster.add_child(mirror_part)
		part.linked_via_editor = mirror_part
		mirror_part.linked_via_editor = part
	
	return part

func update_dragged_part_path() -> void:
	if !enabled: return
	if !selected_part_path: return
	dragged_part_path = selected_part_path
	
func save_cluster() -> void:
	if !enabled: return
	var init_cluster_pos: Vector2 = edited_cluster.global_position
	edited_cluster.global_position = Vector2.ZERO
	
	var saved: PackedScene = PackedScene.new()
	saved.pack(edited_cluster)
	
	edited_cluster.global_position = init_cluster_pos
	
	var full_path: String = GlobalClass.EDITOR_SAVES_DIRECTORY + "saved_tanks/" + edited_cluster.name + ".tscn"
	if FileAccess.file_exists(full_path) and GlobalClass.UNOVERWRITTABLE_TANK_NAMES.has(edited_cluster.name):
		randomize()
		edited_cluster.name += str(randi())
		full_path = GlobalClass.EDITOR_SAVES_DIRECTORY + "saved_tanks/" + edited_cluster.name + ".tscn"
	var error = ResourceSaver.save(saved, full_path)
	if error == OK:
		print("Saved " + str(saved) + "at path: " + full_path)
	else:
		print("Saving failed.")
	
	if !debug:
		GlobalClass.player_cluster_filename = edited_cluster.name
		GlobalClass.world.ui.toggle_editor(false)
		GlobalClass.world.ui.hud.show()
		GlobalClass.world.transform_player_into(load(full_path).instantiate())
		GlobalClass.can_pause = true

func update_cluster_name(text: String) -> void:
	edited_cluster.name = text

func create_edited_cluster(cluster: Cluster) -> void:
	if edited_cluster:
		edited_cluster.queue_free()
	edited_cluster = cluster
	for p in edited_cluster.get_parts():
		print(p)
		p.disabled = true
		p.editor_mode = true
	add_child(edited_cluster)
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
	cluster_max_spawn_edit.text = str(edited_cluster.max_spawn_amount)
	update_tank_info()

func load_cluster(text: String) -> void:
	if !enabled: return
	var full_path: String = GlobalClass.EDITOR_SAVES_DIRECTORY + "saved_tanks/" + text + ".tscn"
	if FileAccess.file_exists(full_path):
		var loaded_cluster: Cluster = load(full_path).instantiate()
		if GlobalClass.world and loaded_cluster.cluster_class <= GlobalClass.world.player_max_class and loaded_cluster.get_used_gp() <= GlobalClass.world.player_max_gun_points:
			create_edited_cluster(loaded_cluster)
			print("Loaded cluster from: " + full_path)
			load_cluster_input.hide()
		elif !debug:
			print("Could not load cluster, either class or gp is insufficient.")
		else:
			create_edited_cluster(loaded_cluster)
	if !debug and GlobalClass.player_cluster:
		update_tank_info()

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
	exit_button.pressed.connect(get_tree().change_scene_to_file.bind("uid://bkalqiq76isn0"))
	
	delete_button.pressed.connect(delete_last_dragged)
	move_up_button.pressed.connect(move_last_dragged.bind(1))
	move_down_button.pressed.connect(move_last_dragged.bind(-1))
	center_part_button.pressed.connect(center_last_dragged)
	move_top_button.pressed.connect(move_last_dragged_to_top)
	
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
	cluster_max_spawn_edit.text_changed.connect(
		update_cluster_float_with_line_edit.bind("max_spawn_amount", cluster_max_spawn_edit))
	
	scale_slider.value_changed.connect(scale_last_dragged)
	rotation_slider.value_changed.connect(rotate_last_dragged)
	
	symmetry_button.pressed.connect(toggle_symmetry)

func delete_last_dragged() -> void:
	if !last_dragged: return
	if symmetry and last_dragged.linked_via_editor: 
		delete_part(last_dragged.linked_via_editor)
	delete_part(last_dragged)
	
func move_last_dragged(value: int) -> void:
	if !last_dragged: return
	if symmetry and last_dragged.linked_via_editor: 
		edited_cluster.move_child(last_dragged.linked_via_editor, last_dragged.linked_via_editor.get_index() + 1)
	edited_cluster.move_child(last_dragged, last_dragged.get_index() + value)

func move_last_dragged_to_top() -> void:
	if !last_dragged: return
	last_dragged.move_to_front()
	if symmetry and last_dragged.linked_via_editor: 
		last_dragged.linked_via_editor.move_to_front()
	
func scale_last_dragged(value: float) -> void:
	if !last_dragged: return
	if symmetry and last_dragged.linked_via_editor: 
		last_dragged.linked_via_editor.scale = Vector2.ONE * value
	last_dragged.scale = Vector2.ONE * value

func rotate_last_dragged(value: float) -> void:
	if !last_dragged: return
	if symmetry and last_dragged.linked_via_editor: 
		last_dragged.linked_via_editor.rotation_degrees = value
	last_dragged.rotation_degrees = -value

func toggle_symmetry() -> void:
	symmetry = !symmetry

func center_last_dragged() -> void:
	if !last_dragged: return
	if symmetry and last_dragged.linked_via_editor: 
		last_dragged.linked_via_editor.global_position.y = edited_cluster.global_position.y
	last_dragged.global_position.y = edited_cluster.global_position.y

func update_tank_info() -> void:
	if !edited_cluster or edited_cluster.get_parts().is_empty(): return
	await get_tree().process_frame
	update_available_gp()
	update_class()
	update_info_ui()

func clear_cluster() -> void:
	for p in edited_cluster.get_parts():
		delete_part(p)
	create_template()

func create_template() -> void:
	var temp: Cluster = Cluster.new()
	temp.name = "Tank"
	create_edited_cluster(temp)

func stop_dragging() -> void:
	if !dragged_part: return
	dragged_part = null
	update_tank_info()

func update_class() -> void:
	var farthest_part: Part = GlobalClass.get_closest_or_farthest(edited_cluster, edited_cluster.get_parts(), false)
	var farthest_part_distance: float
	if farthest_part:
		farthest_part_distance = abs(farthest_part.global_position.distance_to(edited_cluster.global_position))
	else: return
	
	var determined_class: int
	for requirement in GlobalClass.CLASS_RADIUS:
		if requirement < farthest_part_distance:
			determined_class = GlobalClass.CLASS_RADIUS.find(requirement) + 1
			
	if GlobalClass.world and GlobalClass.world.player_max_class >= determined_class or debug:
		edited_cluster.cluster_class = determined_class
	else:
		delete_last_dragged()
	print("Class: " + str(determined_class))

func update_available_gp() -> void:
	if !GlobalClass.world or debug: return
	var calculated_value: int = GlobalClass.world.player_max_gun_points - edited_cluster.get_used_gp()
	if calculated_value >= 0:
		available_gp = calculated_value
	else:
		delete_last_dragged()
	
func delete_part(part: Part) -> void:
	part.queue_free()
	update_tank_info()

func update_info_ui() -> void:
	info_label.text = ""
	if GlobalClass.world:
		info_label.text += "GP: " + str(available_gp) + "\n"
		info_label.text += "Max Class: " + str(GlobalClass.world.player_max_class) + "\n"
	else:
		info_label.text += "GP: INF" + "\n"
		info_label.text += "Max Class: " + str(GlobalClass.MAX_CLASS) + "\n"
	info_label.text += "Class: " + str(edited_cluster.cluster_class)

func make_category_containers() -> void:
	for cat in GlobalClass.PART_CATEGORIES:
		var container: VBoxContainer = VBoxContainer.new()
		container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		container.name = cat
		category_tab_container.add_child(container, true)
