extends Control
class_name Editor

@export var debug: bool = false
@export var debug_text: Array[Label]

@onready var part_list_display_container: VBoxContainer = $HBoxContainer/VBoxContainer2/List/MarginContainer/ScrollContainer/VBoxContainer

@onready var drag_and_drop_container: MarginContainer = $HBoxContainer/VBoxContainer2/DragAndDrop/MarginContainer

@onready var cluster_display_container: Panel = $HBoxContainer/VBoxContainer/Display

@onready var drag_button: Button = $HBoxContainer/VBoxContainer2/DragAndDrop/Button
@onready var save_button: TextureButton = $HBoxContainer/Panel/MarginContainer/VBoxContainer/SaveButton
@onready var load_button: TextureButton = $HBoxContainer/Panel/MarginContainer/VBoxContainer/LoadButton

@onready var cluster_name_input: LineEdit = $HBoxContainer/VBoxContainer/ClusterName
@onready var load_cluster_input: LineEdit = $HBoxContainer/Panel/LoadClusterName

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
	
func _process(_delta: float) -> void:
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
	var button: Button = GlobalClass.BUTTON_01.instantiate()
	var unpacked_part: Part = load(part_path).instantiate()
	button.text = unpacked_part.name
	button.pressed.connect(set.bind("selected_part_path", part_path))
	parent.add_child(button)
	unpacked_part.queue_free()
	print("Loaded path from: " + part_path)

func display_selected_part(part: Part) -> void:
	if selected_part: selected_part.queue_free()
	part.disabled = true
	part.scale *= 0.33
	part.global_position = drag_and_drop_container.global_position + drag_and_drop_container.size / 2
	selected_part = part
	add_child(part)
	print("Displayed new part: " + part.name)

func create_dragged_part(part_path: String) -> Part:
	var part: Part = load(part_path).instantiate()
	part.editor_mode = true
	part.disabled = true
	dragged_part = part
	edited_cluster.add_child(part)
	part.owner = edited_cluster
	
	return part

func update_dragged_part_path() -> void:
	if !selected_part_path: return
	dragged_part_path = selected_part_path

func editor_dir_analysis() -> void: 
	if !DirAccess.dir_exists_absolute(GlobalClass.EDITOR_SAVES_DIRECTORY):
		DirAccess.make_dir_absolute(GlobalClass.EDITOR_SAVES_DIRECTORY + "saved_tanks/")
	
func save_cluster() -> void:
	var saved: PackedScene = PackedScene.new()
	saved.pack(edited_cluster)
	var error = ResourceSaver.save(saved, GlobalClass.EDITOR_SAVES_DIRECTORY + "saved_tanks/" + edited_cluster.name + ".tscn")
	if error == OK:
		print("Saved " + str(saved) + "at path: " + GlobalClass.EDITOR_SAVES_DIRECTORY + "saved_tanks/" + edited_cluster.name + ".tscn")
	else:
		print("fuck you it didnt work")

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
	var full_path: String = GlobalClass.EDITOR_SAVES_DIRECTORY + "saved_tanks/" + text + ".tscn"
	if FileAccess.file_exists(full_path):
		create_edited_cluster(load(full_path).instantiate())
		load_cluster_input.hide()

func toggle_load_input() -> void:
	load_cluster_input.visible = !load_cluster_input.visible

func attempt_to_drag() -> void:
	for c in edited_cluster.get_parts():
		if c.is_hovered:
			dragged_part = c
			break
