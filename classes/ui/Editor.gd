extends Control
class_name Editor

@export var debug: bool = false
@export var debug_text: Array[Label]

var enabled: bool = false
var mid_transition: bool = false

@onready var part_list_display_container: VBoxContainer = $HBoxContainer/VBoxContainer2/List/MarginContainer/ScrollContainer/VBoxContainer

@onready var drag_and_drop_container: MarginContainer = $HBoxContainer/VBoxContainer2/DragAndDrop/MarginContainer

@onready var cluster_display_container: Panel = $HBoxContainer/VBoxContainer/Display

@onready var drag_button: Button = $HBoxContainer/VBoxContainer2/DragAndDrop/Button
@onready var save_button: TextureButton = $HBoxContainer/Panel/MarginContainer/VBoxContainer/SaveButton
@onready var load_button: TextureButton = $HBoxContainer/Panel/MarginContainer/VBoxContainer/LoadButton

@onready var cluster_name_input: LineEdit = $HBoxContainer/VBoxContainer/ClusterName
@onready var load_cluster_input: LineEdit = $HBoxContainer/Panel/LoadClusterName
@onready var cluster_team_edit: LineEdit = $HBoxContainer/VBoxContainer2/TankInfo/MarginContainer/VBoxContainer/TeamEdit
@onready var cluster_hp_edit: LineEdit = $HBoxContainer/VBoxContainer2/TankInfo/MarginContainer/VBoxContainer/HPEdit
@onready var cluster_drop_edit: LineEdit = $HBoxContainer/VBoxContainer2/TankInfo/MarginContainer/VBoxContainer/DropEdit
@onready var cluster_speed_edit: LineEdit = $HBoxContainer/VBoxContainer2/TankInfo/MarginContainer/VBoxContainer/SpeedEdit
@onready var cluster_min_available_edit: LineEdit = $HBoxContainer/VBoxContainer2/TankInfo/MarginContainer/VBoxContainer/MinAvailableEdit

var selected_part_path: String:
	set(value):
		selected_part_path = value
		display_selected_part(load(selected_part_path).instantiate())

var selected_part: Part

var dragged_part_path: String:
	set(value):
		dragged_part_path = value
		create_dragged_part(dragged_part_path)

var dragged_part: Part

var last_dragged_part: Part

var edited_cluster: Cluster

func _ready() -> void:
	if !debug:
		for l in debug_text: l.queue_free()
		
	retrieve_avaliable_parts(GlobalClass.PARTS_DIRECTORY)
	
	await get_tree().process_frame
	
	create_edited_cluster(Cluster.new())
	
	editor_dir_analysis()
	
	drag_button.button_down.connect(update_dragged_part_path)
	save_button.pressed.connect(save_cluster)
	load_button.pressed.connect(toggle_load_input)
	
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
	
func _process(_delta: float) -> void:
	if !enabled: return
	
	if dragged_part:
		dragged_part.global_position = get_global_mouse_position()
	
	if Input.is_action_just_pressed("lmb"):
		attempt_to_drag()
	
	if Input.is_action_just_released("lmb"):
		dragged_part = null
	
	if Input.is_action_just_pressed("enter") and !load_cluster_input.text.is_empty():
		load_cluster(load_cluster_input.text)

func retrieve_avaliable_parts(dir: String) -> void:
	for subdir in ResourceLoader.list_directory(dir):
		for file in ResourceLoader.list_directory(dir + subdir):
			var full_path: String = dir + subdir + file
			make_part_select_button(full_path, part_list_display_container)

func make_part_select_button(part_path: String, parent: Control) -> void:
	if !enabled: return
	
	var button: Button = GlobalClass.BUTTON_01.instantiate()
	var unpacked_part: Part = load(part_path).instantiate()
	button.text = unpacked_part.name
	button.pressed.connect(set.bind("selected_part_path", part_path))
	parent.add_child(button)
	unpacked_part.queue_free()
	print("Loaded path from: " + part_path)

func display_selected_part(part: Part) -> void:
	if !enabled: return
	
	if selected_part: selected_part.queue_free()
	part.disabled = true
	part.scale *= 0.33
	part.global_position = drag_and_drop_container.global_position + drag_and_drop_container.size / 2
	selected_part = part
	add_child(part)
	print("Displayed new part: " + part.name)

func create_dragged_part(part_path: String) -> Part:
	if !enabled: return
	
	var part: Part = load(part_path).instantiate()
	part.editor_mode = true
	part.disabled = true
	dragged_part = part
	last_dragged_part = part
	edited_cluster.add_child(part)
	part.owner = edited_cluster
	
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
	
	var error = ResourceSaver.save(saved, GlobalClass.EDITOR_SAVES_DIRECTORY + "saved_tanks/" + edited_cluster.name + ".tscn")
	if error == OK:
		print("Saved " + str(saved) + "at path: " + GlobalClass.EDITOR_SAVES_DIRECTORY + "saved_tanks/" + edited_cluster.name + ".tscn")
	else:
		print("Saving failed.")
	
	toggle_editor(false)

func update_cluster_name(text: String) -> void:
	edited_cluster.name = text

func create_edited_cluster(cluster: Cluster) -> void:
	if edited_cluster:
		edited_cluster.queue_free()
	edited_cluster = cluster
	edited_cluster.enabled = false
	edited_cluster.global_position = cluster_display_container.global_position + cluster_display_container.size / 2
	for p in edited_cluster.get_parts():
		p.disabled = true
		p.editor_mode = true
	add_child(edited_cluster)

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
			last_dragged_part = c
			break

func update_cluster_float_with_line_edit(_text: String, variable: String, line_edit: LineEdit) -> void:
	if !enabled: return
	edited_cluster.set(variable, line_edit.text.to_float())

func toggle_editor(value: bool) -> void:
	if mid_transition: return
	mid_transition = true
	if value:
		enabled = false
		modulate.a = 0.0
		await create_tween().tween_property(self, "modulate:a", 1.0, 0.5).finished
		mid_transition = false
		enabled = true
	else:
		enabled = true
		modulate.a = 1.0
		await create_tween().tween_property(self, "modulate:a", 0.0, 0.5).finished
		mid_transition = false
		enabled = false
