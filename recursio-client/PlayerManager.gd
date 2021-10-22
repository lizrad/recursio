extends Spatial

var _player_scene = preload("res://Players/Player.tscn")
var _ghost_scene = preload("res://Players/Ghost.tscn")
var _player_ghost_scene = preload("res://Players/PlayerGhost.tscn")
var _enemy_scene = preload("res://Players/Enemy.tscn")

var _my_ghosts = {}
# Key: Player ID | Value: List of ghosts
var _enemy_ghosts_dic = {}

# The player reference
var player

# The player id (rpc id)
var id

var enemies = {}

var time_of_last_world_state = -1
var time_since_last_server_update = 0

var time_of_last_world_state_send = -1

onready var game_result_screen = get_node("../GameResultScreen")
onready var countdown_screen = get_node("../CountdownScreen")
export var level_path: NodePath
onready var level = get_node(level_path)

onready var _prep_phase_time: float = Constants.get_value("gameplay", "prep_phase_time")

var _prep_phase_in_progress = false
var _game_phase_in_progress = false

func _ready():	
	game_result_screen.visible = false
	countdown_screen.visible = false
	time_of_last_world_state_send = Server.get_server_time()

	Server.connect("spawning_player", self, "_spawn_player")
	Server.connect("spawning_enemy", self, "_spawn_enemy")
	Server.connect("despawning_enemy", self, "_despawn_enemy")
	Server.connect("world_state_received", self, "_update_character_positions")
	Server.connect("own_ghost_record_received", self, "_create_own_ghost")
	Server.connect("enemy_ghost_record_received", self, "_create_enemy_ghost")
	Server.connect("round_start_received",self, "_on_round_start_received")
	Server.connect("round_end_received", self, "_on_round_ended_received")
	Server.connect("capture_point_captured", self, "_on_capture_point_captured" )
	Server.connect("capture_point_team_changed", self, "_on_capture_point_team_changed" )
	Server.connect("capture_point_status_changed", self, "_on_capture_point_status_changed" )
	Server.connect("capture_point_capture_lost", self, "_on_capture_point_capture_lost" )
	Server.connect("game_result", self, "_on_game_result" )
	Server.connect("player_hit", self, "_on_player_hit")
	Server.connect("ghost_hit", self, "_on_ghost_hit")
	Server.connect("ghost_picks", self, "_on_ghost_picks")
	Server.connect("player_action", self, "_on_player_action")
	
	set_physics_process(false)

func _reset():
	Logger.info("Full reset triggered.","gameplay")
	player.reset()
	player.spawn_point = _get_spawn_point(player.game_id, 0)
	player.move_back_to_spawnpoint()
	for enemy_id in enemies:
		enemies[enemy_id].reset()
	for ghost in _my_ghosts:
		_my_ghosts[ghost].queue_free()
	_my_ghosts.clear()
	for enemy_id in _enemy_ghosts_dic:
		for ghost_index in _enemy_ghosts_dic[enemy_id]:
			_enemy_ghosts_dic[enemy_id][ghost_index].queue_free()
		_enemy_ghosts_dic[enemy_id].clear()
	time_of_last_world_state = -1
	time_since_last_server_update = 0
	time_of_last_world_state_send = -1
	level.reset()
	GlobalActionManager.clear_action_instances()

func _on_game_result(winning_player_id):
	var player_id = get_tree().get_network_unique_id()
	if winning_player_id == player_id:
		Logger.info("I won!", "gameplay")
		game_result_screen.get_node("ResultText").text = "You Won!"
	else:
		Logger.info("I lost!", "gameplay")
		game_result_screen.get_node("ResultText").text = "You Lost!"
	_reset()
	game_result_screen.visible = true


var _wait_for_new_ghost_picking_input = 0
func handle_ghost_picking_input(delta:float):
	if _wait_for_new_ghost_picking_input>0:
		_wait_for_new_ghost_picking_input-=delta
		return
	if not _prep_phase_in_progress:
		return
	
	if Input.is_action_pressed("player_switch"):
		Logger.info("Switching ghost from "+str(player.ghost_index)+ " to "+str((player.ghost_index+1)%(Constants.get_value("ghosts","max_amount")+1)),"ghost_picking")
		_wait_for_new_ghost_picking_input = 0.2
		
		#Disable all ghosts
		_disable_ghosts()
		#Update ghost index
		player.ghost_index=(player.ghost_index+1)%(Constants.get_value("ghosts","max_amount")+1)
		#Enable new relevant ghosts
		_enable_ghosts()
		#Move player to new spawnpoint
		move_player_to_spawnpoint(player.ghost_index)


func _on_ghost_picks(player_pick, enemy_picks):
	Logger.info("Received ghost picks from server","ghost_picking")
	_disable_ghosts()
	player.ghost_index = player_pick
	
	player.swap_weapon_type(player_pick)
	
	for enemy_id in enemies:
		enemies[enemy_id].ghost_index = enemy_picks[enemy_id]
	_enable_ghosts()
	
func _process(delta):
	handle_ghost_picking_input(delta)
	
	time_since_last_server_update += delta
	var server_delta = 1.0 / Server.tickrate

	# Goes from 0 to 1 for each network tick
	var tick_progress = time_since_last_server_update / server_delta
	tick_progress = min(tick_progress, 1)

	for enemy in enemies.values():
		if not enemy.server_position:
			# No known server state yet
			continue

		enemy.velocity = (
			enemy.last_velocity
			+ (enemy.server_velocity - enemy.last_velocity) * tick_progress
		)

		var projected_from_start = (
			enemy.last_position
			+ enemy.velocity * time_since_last_server_update
			+ (
				enemy.server_acceleration
				* 0.5
				* time_since_last_server_update
				* time_since_last_server_update
			)
		)

		var projected_from_last_known = (
			enemy.server_position
			+ enemy.server_velocity * time_since_last_server_update
			+ (
				enemy.server_acceleration
				* 0.5
				* time_since_last_server_update
				* time_since_last_server_update
			)
		)

		enemy.transform.origin = (
			projected_from_start
			+ (projected_from_last_known - projected_from_start) * tick_progress
		)
	
	# Update capture points in HUD
	if player != null:
		var index: int = 0
		for capture_point in level.get_capture_points():
			player.hud.update_capture_point(index, capture_point.get_capture_progress(), capture_point.get_capture_team())
			index += 1

func _on_round_ended_received(round_index):
	_game_phase_in_progress = false
	player.game_in_progress = false
	player.move_back_to_spawnpoint()
	_stop_ghosts()
	
	var ghost_index = min(round_index-1,Constants.get_value("ghosts", "max_amount"))
	var my_replaced_ghost_index = ghost_index
	var enemies_replaced_ghost_indices = {}
	for enemy_id in enemies:
		enemies_replaced_ghost_indices[enemy_id] = ghost_index
	_disable_ghosts()
	level.reset()
	level.toggle_capture_points(false)
	
	GlobalActionManager.clear_action_instances()


func _on_round_start_received(round_index, server_time):
	#===========
	#ROUND START
	#===========
	Logger.info("Round "+str(round_index)+" started", "gameplay")
	game_result_screen.visible = false
	player.hud.round_start(round_index, server_time)
	
	# We have to disable this here because otherwise, the light never sees the ghosts for some reason
	player.set_overview_light_enabled(false)
	
	
	#===================
	#LATENCY DELAY PHASE
	#===================
	var time_diff = (Server.get_server_time() - server_time)
	Logger.info("Latency Delay "+str(round_index)+" with time difference of "+str(time_diff/1000.0)+" started", "gameplay")
	player.hud.latency_delay_phase_start(round_index, server_time, time_diff)
	# Delay to counteract latency
	var delay = Constants.get_value("gameplay", "latency_delay") - (time_diff  / 1000.0)
	# Wait for latency delay
	yield(get_tree().create_timer(delay), "timeout")
	
	
	#==========
	#PREP PHASE
	#==========
	Logger.info("Prep phase "+str(round_index)+" started", "gameplay")
	player.hud.prep_phase_start(round_index, Server.get_server_time())
	_prep_phase_in_progress = true
	
	# Display paths of my ghosts
	var ghost_paths = []
	for i in _my_ghosts:
		var curve = Curve3D.new()
		
		var record = _my_ghosts[i].record
		var data_array = record["F"]
		for path_i in range(0, data_array.size(), 30):
			curve.add_point(data_array[path_i]["P"])
		
		var path = preload("res://Players/GhostPath.tscn").instance()
		path.set_curve(curve)
		
		ghost_paths.append(path)
		add_child(path)
	
	player.move_camera_to_overview()


	#Default ghost index
	var default_ghost_index = min(round_index-1,Constants.get_value("ghosts", "max_amount"))
	move_player_to_spawnpoint(default_ghost_index)
	player.ghost_index = default_ghost_index
	for enemy_id in enemies:
		enemies[enemy_id].ghost_index = default_ghost_index

	# Add ghosts to scene and set their start position
	_enable_ghosts()
	_move_ghosts_to_spawn()

	# Wait for preparation phase
	yield(get_tree().create_timer(_prep_phase_time), "timeout")


	#===============
	#COUNTDOWN PHASE
	#===============
	
	# Delete paths again
	for ghost_path in ghost_paths:
		ghost_path.queue_free()
	ghost_paths.clear()
	
	player.follow_camera()
	
	Logger.info("Countdown phase "+str(round_index)+" started", "gameplay")
	_prep_phase_in_progress = false
	player.hud.countdown_phase_start(round_index, Server.get_server_time())
	Server.send_ghost_pick(player.ghost_index)
	countdown_screen.visible = true
	var countdown_phase_seconds = Constants.get_value("gameplay","countdown_phase_seconds")
	for i in range(countdown_phase_seconds):
		countdown_screen.get_node("CountdownText").text = str(countdown_phase_seconds-i)
		yield(get_tree().create_timer(1), "timeout")
	countdown_screen.visible = false
	
	
	#==========
	#GAME PHASE
	#==========
	Logger.info("Game phase "+str(round_index)+" started", "gameplay")
	_game_phase_in_progress = true
	player.hud.game_phase_start(round_index, Server.get_server_time())
	player.game_in_progress = true
	level.toggle_capture_points(true)
	
	_restart_ghosts(Server.get_server_time())



func move_player_to_spawnpoint(ghost_index:int)->void:
	Logger.info("Moving player to spawnpoint "+str(ghost_index), "spawnpoints")
	player.transform.origin = _get_spawn_point(player.game_id, ghost_index)
	player.spawn_point = _get_spawn_point(player.game_id, ghost_index)

func _get_spawn_point(game_id, ghost_index):
	var player_number = game_id + 1
	var spawn_point = level.get_spawn_points(player_number)[ghost_index]
	return spawn_point

func _apply_visibility_mask(character):
	if player:
		character.get_node("Mesh_Body").material_override.set_shader_param("visibility_mask", player.get_visibility_mask())


func _apply_visibility_always(character):
	character.get_node("Mesh_Body").material_override.set_shader_param("always_draw", true)


func _create_enemy_ghost(enemy_id, gameplay_record):
	Logger.info("Enemy ("+str(enemy_id)+") ghost record received with start time of " + str(gameplay_record["T"]), "ghost")
	
	var ghost = _create_ghost(gameplay_record)
	#Low Priority TODO: this works for two player only
	ghost.spawn_point = _get_spawn_point(1-player.game_id,gameplay_record["G"])
	ghost.add_to_group("Enemy")
	if _enemy_ghosts_dic[enemy_id].has([gameplay_record["G"]]):
		_enemy_ghosts_dic[enemy_id][gameplay_record["G"]].queue_free()
	_enemy_ghosts_dic[enemy_id][gameplay_record["G"]] = ghost
	
func _create_own_ghost(gameplay_record):
	Logger.info("Own ghost record received with start time of " + str(gameplay_record["T"]), "ghost")
	var ghost = _create_ghost(gameplay_record, true)
	ghost.spawn_point = _get_spawn_point(player.game_id,gameplay_record["G"])
	ghost.add_to_group("Friend")
	if _my_ghosts.has([gameplay_record["G"]]):
		_my_ghosts[gameplay_record["G"]] .queue_free()
	_my_ghosts[gameplay_record["G"]] = ghost

func _create_ghost(gameplay_record, friendly = false):
	var ghost = _player_ghost_scene.instance() if friendly else _ghost_scene.instance()
	ghost.action_manager = GlobalActionManager
	ghost.init(gameplay_record, Color.lightcoral if friendly else Color.lightblue)
	ghost.connect("ghost_attack", self, "_on_ghost_attack")
	return ghost

func _stop_ghosts()->void:
	for enemy_id in _enemy_ghosts_dic:
		for i in _enemy_ghosts_dic[enemy_id]:
			_enemy_ghosts_dic[enemy_id][i].stop_replay()
	for i in _my_ghosts:
		_my_ghosts[i].stop_replay()

func _disable_ghosts()->void:
	for enemy_id in _enemy_ghosts_dic:
		for i in _enemy_ghosts_dic[enemy_id]:
			if i != enemies[enemy_id].ghost_index:
				remove_child(_enemy_ghosts_dic[enemy_id][i])
	for i in _my_ghosts:
		if i != player.ghost_index:
			remove_child(_my_ghosts[i])

func _enable_ghosts() ->void:
	for enemy_id in _enemy_ghosts_dic:
		for i in _enemy_ghosts_dic[enemy_id]:
			if i != enemies[enemy_id].ghost_index:
				# Apply the visibility mask for enemy ghosts only (friendly ones are always visible)
				_apply_visibility_mask(_enemy_ghosts_dic[enemy_id][i])
				_add_ghost(_enemy_ghosts_dic[enemy_id][i])
	for i in _my_ghosts:
		if i != player.ghost_index:
			_add_ghost(_my_ghosts[i])
			_apply_visibility_always(_my_ghosts[i])


func _add_ghost(ghost):
	add_child(ghost)


func _on_ghost_attack(attacker, trigger):
	var action = GlobalActionManager.get_action_for_trigger(trigger, attacker.ghost_index)
	GlobalActionManager.set_active(action, true, attacker, get_tree().get_root())


func _move_ghosts_to_spawn() -> void:
	for enemy_id in _enemy_ghosts_dic:
		for i in _enemy_ghosts_dic[enemy_id]:
			_enemy_ghosts_dic[enemy_id][i].move_to_spawn_position()
	for i in _my_ghosts:
		_my_ghosts[i].move_to_spawn_position()

func _restart_ghosts(start_time)->void:
	for enemy_id in _enemy_ghosts_dic:
		for i in _enemy_ghosts_dic[enemy_id]:
			if i != enemies[enemy_id].ghost_index:
				_enemy_ghosts_dic[enemy_id][i].start_replay(start_time)
	for i in _my_ghosts:
		if i != player.ghost_index:
			_my_ghosts[i].start_replay(start_time)


func _spawn_player(player_id, spawn_point, game_id):
	set_physics_process(true)
	player = _spawn_character(_player_scene, spawn_point)
	player.spawn_point = spawn_point
	player.game_id =game_id
	player.player_id = player_id
	player.set_name(str(player_id))
	id = player_id
	
	# Apply visibility mask to all entities which have been here before the player
	for enemy in enemies.values():
		_apply_visibility_mask(enemy)
	for ghosts in _enemy_ghosts_dic.values():
		for ghost in ghosts.values():
			_apply_visibility_mask(ghost)
	
	
	# Initialize capture point HUD for current level
	for i in range(level.get_capture_points().size()):
		player.hud.add_capture_point()
	
	# Update the player id for the HUD
	player.hud.set_player_id(player_id)


func _spawn_enemy(enemy_id, spawn_point):
	var enemy = _spawn_character(_enemy_scene, spawn_point)
	enemy.set_name(str(enemy_id))
	_apply_visibility_mask(enemy)
	enemies[enemy_id] = enemy
	_enemy_ghosts_dic[enemy_id] = {}


func _despawn_enemy(enemy_id):
	enemies[enemy_id].queue_free()
	enemies.erase(enemy_id)
	for i in _enemy_ghosts_dic[enemy_id]:
		_enemy_ghosts_dic[enemy_id][i].queue_free()
	_enemy_ghosts_dic.erase(enemy_id)


func _spawn_character(character_scene, spawn_point):
	var character = character_scene.instance()
	character.transform.origin = spawn_point
	add_child(character)
	return character


func _update_character_positions(world_state):
	if not _game_phase_in_progress:
		return
	if time_of_last_world_state < world_state["T"]:
		time_of_last_world_state = world_state["T"]
		time_since_last_server_update = 0

		var enemy_states = world_state["S"]

		# Handle own player
		if enemy_states.has(id):
			var server_player = enemy_states[id]

			player.handle_network_update(server_player["P"], server_player["T"])

			enemy_states.erase(id)

		for enemy_id in enemy_states:
			if enemies.has(enemy_id):
				var enemy = enemies[enemy_id]

				# Set parameters for interpolation
				enemy.last_position = enemy.transform.origin
				enemy.last_velocity = enemy.velocity
				enemy.rotation.y = enemy_states[enemy_id]["R"]
				enemy.server_position = enemy_states[enemy_id]["P"]
				enemy.server_velocity = enemy_states[enemy_id]["V"]
				enemy.server_acceleration = enemy_states[enemy_id]["A"]


func _on_player_hit(hit_player_id):
	if hit_player_id == id:
		# Own player was hit
		player.receive_hit()
	else:
		enemies[hit_player_id].receive_hit()

func _on_ghost_hit(hit_ghost_player_owner, hit_ghost_id):
	if hit_ghost_player_owner == id:
		_my_ghosts[hit_ghost_id].receive_hit()
	else:
		_enemy_ghosts_dic[hit_ghost_player_owner][hit_ghost_id].receive_hit()


func _on_player_action(player_id, action_type):
	var player = enemies[player_id]
	var action = GlobalActionManager.get_action(action_type)
	GlobalActionManager.set_active(action, true, player, get_tree().root)

func _on_capture_point_captured(capturing_player_id, capture_point):
	level.get_capture_points()[capture_point].capture(capturing_player_id)
	
	if capturing_player_id == id:
		player.move_camera_to_overview()
		player.set_overview_light_enabled(true)
	
func _on_capture_point_team_changed(capturing_player_id, capture_point):
	level.get_capture_points()[capture_point].set_capturing_player(capturing_player_id)
	
func _on_capture_point_status_changed(capturing_player_id, capture_point, capture_progress):
	level.get_capture_points()[capture_point].set_capture_status(capturing_player_id, capture_progress)
	
func _on_capture_point_capture_lost(capturing_player_id, capture_point):
	level.get_capture_points()[capture_point].capture_lost(capturing_player_id)
	
	if capturing_player_id == id:
		player.follow_camera()
		player.set_overview_light_enabled(false)
