extends Node
class_name CharacterManager

var _player_scene = preload("res://Shared/Characters/PlayerBase.tscn")
var _ghost_scene = preload("res://Shared/Characters/GhostBase.tscn")

# Player id <-> Player
var player_dic = {}
# Player id <-> {Timeline_index <-> Ghost}
var ghost_dic = {}
var player_inputs = {}

# Offset at which the world is updated (used for rendering everything in the past)
var world_processing_offset

onready var Server = get_node("/root/Server")
onready var _game_manager: GameManager = get_node("../GameManager")
onready var _action_manager: ActionManager = get_node("../ActionManager")
onready var _round_manager: RoundManager = get_node("../RoundManager")


func _physics_process(_delta):
	# If the game phase hasn't started, skip
	if _round_manager.get_current_phase() != _round_manager.Phases.GAME:
		return
	
	var base_time = Server.get_server_time() - world_processing_offset

	# Apply received inputs to players
	for player_id in player_inputs:
		if player_dic.has(player_id):
			var input_data: InputData = player_inputs[player_id]
			var player: PlayerBase = player_dic[player_id]
			
			var i = 0
			
			while i < input_data.size():
				var input_frame: InputFrame = input_data.get_elemet(i)
				
				if input_frame.timestamp > base_time:
					break
				elif not player.previously_applied_packets.get_data().has(input_frame.timestamp):
					# TODO: To prevent cheating, we also need to check whether the
					# timestamp distances are sensible, otherwise the player could
					# pack in additional packets
					player.previously_applied_packets.append(input_frame.timestamp)
					player.apply_input(input_frame.movement, input_frame.rotation, input_frame.buttons.mask)
					player.timestamp_of_previous_packet = input_frame.timestamp

				i += 1


func reset() -> void:
	# Delete all ghosts
	for player_id in ghost_dic:
			for i in ghost_dic[player_id]:
				ghost_dic[player_id][i].queue_free()
			ghost_dic[player_id].clear()
	
	# Reset all players
	for player_id in player_dic:
		var player: PlayerBase = player_dic[player_id]
		_game_manager.get_spawn_point(player.team_id, 0)
		player.reset()

	player_inputs.clear()


func update_player_input_data(player_id, new_input_data: InputData):
	if player_inputs.has(player_id):
		# Player input data has to come in the correct order
		# Clock on client can't run more than 25ms fast
		if (player_inputs[player_id].timestamp < new_input_data.timestamp
			&& new_input_data.timestamp - Server.get_server_time() < 25):  
			
			player_inputs[player_id] = new_input_data
	else:
		player_inputs[player_id] = new_input_data


func move_players_to_spawn_point() -> void:
	for player_id in player_dic:
		player_dic[player_id].move_to_spawn_point()


func spawn_player(player_id, team_id) -> void:
	var spawn_point = _game_manager.get_spawn_point(team_id, 0)
	var player: PlayerBase = _player_scene.instance()
	player.player_base_init(_action_manager)
	player.player_id = player_id
	player.team_id = team_id
	player.timeline_index = 0
	player.spawn_point = spawn_point
	ghost_dic[player_id] = {}
	add_child(player)
	player.connect("hit", self, "_on_player_hit", [player_id])

	# Triggering spawns of enemies on all clients
	for other_player_id in player_dic:
		var other_spawn_point = player_dic[other_player_id].spawn_point
		Server.spawn_enemy_on_client(player_id, other_player_id, other_spawn_point)
		Server.spawn_enemy_on_client(other_player_id, player_id, spawn_point)

	player_dic[player_id] = player
	player.move_to_spawn_point()
	Server.spawn_player_on_client(player_id, spawn_point, team_id)


func despawn_player(player_id) -> void:
	player_inputs.erase(player_id)
	for i in ghost_dic[player_id]:
		ghost_dic[player_id][i].queue_free()
	ghost_dic.erase(player_id)
	player_dic[player_id].queue_free()
	player_dic.erase(player_id)
	for other_player_id in player_dic:
		Server.despawn_enemy_on_client(other_player_id, player_id)


func create_ghosts() -> void:
	for player_id in player_dic:
		_create_ghost_from_player(player_dic[player_id])


func set_block_player_input(blocked: bool) -> void:
	for player_id in player_dic:
		player_dic[player_id].block_movement = blocked


func set_timeline_index(player_id, timeline_index):
	Logger.info("Setting ghost index for player "+str(player_id)+" to "+str(timeline_index),"ghost_picking")
	player_dic[player_id].timeline_index = timeline_index
	player_dic[player_id].spawn_point = _game_manager.get_spawn_point(player_dic[player_id].team_id, timeline_index)
	player_dic[player_id].move_to_spawn_point()

func propagate_player_picks():
	Logger.info("Propagating ghost picks", "ghost_picking")
	for player_id in player_dic:
		var player_pick = player_dic[player_id].timeline_index
		var enemy_pick
		for enemy_id in player_dic:
			if enemy_id != player_id:
				enemy_pick = player_dic[enemy_id].timeline_index
		Server.send_ghost_pick(player_id, player_pick, enemy_pick)


func enable_ghosts() -> void:
	for player_id in ghost_dic:
			for timeline_index in ghost_dic[player_id]:
				if player_dic[player_id].timeline_index == timeline_index:
					continue
				_add_ghost(ghost_dic[player_id][timeline_index])


func disable_ghosts() -> void:
	for player_id in ghost_dic:
			for timeline_index in ghost_dic[player_id]:
				if player_dic[player_id].timeline_index == timeline_index:
					continue
				_remove_ghost(ghost_dic[player_id][timeline_index])


func start_ghosts() -> void:
	for player_id in ghost_dic:
			for timeline_index in ghost_dic[player_id]:
				if player_dic[player_id].timeline_index == timeline_index:
					continue
				ghost_dic[player_id][timeline_index].start_playing(Server.get_server_time())


func stop_ghosts() -> void:
	for player_id in ghost_dic:
			for timeline_index in ghost_dic[player_id]:
				if player_dic[player_id].timeline_index == timeline_index:
					continue
				ghost_dic[player_id][timeline_index].start_playing(Server.get_server_time())


func _create_ghost_from_player(player) -> void:
	var record_data = player.get_record_data()
	var ghost = _ghost_scene.instance()
	ghost.ghost_base_init(_action_manager, record_data)
	ghost.player_id = player.player_id
	ghost.spawn_point = player.spawn_point
	ghost.team_id = player.team_id
	ghost.round_index = _round_manager.round_index
	
	if ghost_dic[player.player_id].has(player.timeline_index):
		ghost_dic[player.player_id][player.timeline_index].queue_free()
	
	ghost_dic[player.player_id][player.timeline_index] = ghost
	
	_add_ghost(ghost)
	
	Server.send_player_ghost_record_to_client(player.player_id, player.timeline_index, record_data)
	for client_id in player_dic:
		if client_id != player.player_id:
			Server.send_enemy_ghost_record_to_client(client_id, player.timeline_index, record_data)
		
	player.reset_record_data()

func _add_ghost(ghost) -> void:
	add_child(ghost)
	ghost.connect("hit", self, "_on_ghost_hit", [ghost.timeline_index, ghost.player_id])


func _remove_ghost(ghost) -> void:
	remove_child(ghost)
	ghost.disconnect("hit", self, "_on_ghost_hit")


func _on_player_hit(hit_player_id):
	Logger.info("Player hit!", "attacking")
	player_dic[hit_player_id].move_to_spawn_point()
	
	for player_id in player_dic:
		Server.send_player_hit(player_id, hit_player_id)


func _on_ghost_hit(ghost_id, owning_player_id):
	Logger.info("Ghost hit!", "attacking")
	
	for player_id in player_dic:
		Server.send_ghost_hit(player_id, owning_player_id, ghost_id)













