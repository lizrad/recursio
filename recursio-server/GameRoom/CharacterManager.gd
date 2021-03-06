extends Node
class_name CharacterManager

signal world_state_updated(world_state)
signal player_killed(hit_data)

var _player_scene = preload("res://Shared/Characters/PlayerBase.tscn")

# Player id <-> Player
var player_dic = {}
var player_inputs = {}

# Offset at which the world is updated (used for rendering everything in the past)
var world_processing_offset

onready var Server = get_node("/root/Server")
onready var _game_manager: GameManager = get_node("../GameManager")
onready var _action_manager: ActionManager = get_node("../ActionManager")
onready var _round_manager: RoundManager = get_node("../RoundManager")
onready var _world_state_manager: WorldStateManager = get_node("../WorldStateManager")


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

			for i in input_data.size():
				var input_frame: InputFrame = input_data.get_previous()

				if input_frame == null:
					continue

				if input_frame.timestamp > base_time:
					break
				elif not player.previously_applied_packets.get_data().has(input_frame.timestamp):
					# TODO: To prevent cheating, we also need to check whether the
					# timestamp distances are sensible, otherwise the player could
					# pack in additional packets
					player.previously_applied_packets.append(input_frame.timestamp)
					player.apply_input(input_frame.movement, input_frame.rotation, input_frame.buttons)
					player.timestamp_of_previous_packet = input_frame.timestamp
			input_data.reset_iteration_index()

	if player_inputs.size() == player_dic.size():
		var world_state: WorldState = _world_state_manager.create_world_state(player_dic)
		emit_signal("world_state_updated", world_state)

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

func spawn_player(player_id, team_id, player_user_name) -> void:
	var spawn_point = _game_manager.get_spawn_point(team_id, 0).global_transform.origin
	var player: PlayerBase = _player_scene.instance()
	player.player_base_init(_action_manager)
	player.player_id = player_id
	player.user_name = player_user_name
	player.team_id = team_id
	player.spawn_point = spawn_point
	add_child(player)
	var _error = player.connect("hit", self, "_on_player_hit")
	_error =player.connect("wall_spawn", self, "_on_wall_spawn", [player_id])

	# Triggering spawns of enemies on all clients
	for other_player_id in player_dic:
		var other_spawn_point = player_dic[other_player_id].spawn_point
		var other_team_id = player_dic[other_player_id].team_id
		Server.spawn_enemy_on_client(player_id, other_player_id, other_spawn_point, other_team_id)
		Server.spawn_enemy_on_client(other_player_id, player_id, spawn_point, team_id)

	player_dic[player_id] = player
	player.move_to_spawn_point()
	Server.spawn_player_on_client(player_id, spawn_point, team_id)

func reset_wall_indices():
	for player_id in player_dic:
		player_dic[player_id].reset_wall_indices()

# propagate_to_picking_player is necessary because there are some moments where picking is 
# server driven and some where it is client driven, to avoid endless loops of switching 
# timelines because server and client are out of face because of a big latency we use this 
# parameter to decide whether we send picks to the player itself
func set_timeline_index(picking_player_id, timeline_index, propagate_to_picking_player):
	Logger.info("Setting timeline index for player "+str(picking_player_id)+" to "+str(timeline_index),"ghost_picking")
	var player = player_dic[picking_player_id]
	player.timeline_index = timeline_index
	player.spawn_point = _game_manager.get_spawn_point(player.team_id, timeline_index).global_transform.origin
	player.move_to_spawn_point()
	_propagate_current_timelines(picking_player_id, propagate_to_picking_player)

func propagate_all_timelines():
	for player_id in player_dic:
		_propagate_current_timelines(player_id, true)

func _propagate_current_timelines(picking_player_id, propagate_to_picking_player):
	for player_id in player_dic:
		for client_id in player_dic:
			if not propagate_to_picking_player and picking_player_id == client_id and picking_player_id == player_id:
				continue
			Server.send_timeline_pick(client_id, player_id, player_dic[player_id].timeline_index)


func _on_player_hit(hit_data: HitData):
	Logger.info("Player hit!", "attacking")
	emit_signal("player_killed", hit_data)
	for player_id in player_dic:
		Server.send_player_hit(player_id, hit_data)

func _on_wall_spawn(position, rotation, wall_index, player_id):
	Server.send_wall_spawn(position, rotation, wall_index, player_id)

func team_id_to_player_id(team_id):
	for player in player_dic.values():
		if player.team_id == team_id:
			return player.player_id
	return -1
