extends Node2D
class_name Arena

func spawn_enemies() -> void:
	var enemies_left_to_spawn: float = GlobalClass.DEFAULT_MAX_ENEMIES + (GlobalClass.world.arenas_travelled * GlobalClass.MAX_ENEMIES_INCREMENT_PER_ARENA)
	var enemy_names_spawned: Array[String] = []
	
	while enemies_left_to_spawn > 0:
		var enemies: Array[Cluster] = []
		for cluster in GlobalClass.loaded_clusters:
			if cluster.team == 1 and cluster.min_to_available <= GlobalClass.world.arenas_travelled:
				enemies.append(cluster)
		
		if enemies.is_empty(): return
		
		var rand_enemy: Cluster = enemies.pick_random()
		if enemy_names_spawned.has(rand_enemy.name):
			break
		else:
			enemy_names_spawned.append(rand_enemy.name)
		for x in randi_range(0, 3):
			var deployable_enemy: Cluster = rand_enemy.duplicate()
			deployable_enemy.in_arena = self
			deployable_enemy.global_position = global_position + Vector2.from_angle(randf_range(0, TAU)) * randf_range(0, GlobalClass.ESTIMATED_ARENA_RADIUS * 0.25)
			deployable_enemy.global_rotation = randf_range(0, TAU)
			for p in deployable_enemy.get_parts():
				p.editor_mode = false
				p.disabled = false
			GlobalClass.world.add_child(deployable_enemy)
			enemies_left_to_spawn -= 1
