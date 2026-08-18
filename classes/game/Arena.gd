extends Node2D
class_name Arena

func spawn_enemies() -> void:
	var enemies_left_to_spawn: int = int(GlobalClass.DEFAULT_MAX_ENEMIES + (GlobalClass.world.arenas_travelled * GlobalClass.MAX_ENEMIES_INCREMENT_PER_ARENA))
	var final_spawned_amount: int = 0
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
		
		var min_enemy_amount: int = 0
		var max_enemy_amount: int = rand_enemy.max_spawn_amount
		if rand_enemy.min_to_available == 0:
			min_enemy_amount = 1
		for x in randi_range(min_enemy_amount, max_enemy_amount):
			if enemies_left_to_spawn == 0: return
			var deployable_enemy: Cluster = rand_enemy.duplicate()
			deployable_enemy.global_position = global_position + Vector2.from_angle(randf_range(0, TAU)) * randf_range(0, GlobalClass.ESTIMATED_ARENA_RADIUS * 0.8 * scale.length() / 2)
			deployable_enemy.global_rotation = randf_range(0, TAU)
			for p in deployable_enemy.get_parts():
				p.editor_mode = false
				p.disabled = false
			enemies_left_to_spawn -= 1
			final_spawned_amount += 1
			GlobalClass.world.add_child(deployable_enemy)
	
	resize_arena(final_spawned_amount)

func resize_arena(enemy_amount: int) -> void:
	var targ_scale: Vector2 = GlobalClass.DEFAULT_ARENA_SCALE + Vector2.ONE * (GlobalClass.ARENA_RADIUS_GROW_PER_ENEMY * enemy_amount)
	create_tween().tween_property(self, "scale", targ_scale, 2.0).set_trans(Tween.TRANS_SINE)
