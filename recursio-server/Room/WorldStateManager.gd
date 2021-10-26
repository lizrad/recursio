extends Node
class_name WorldStateManager

signal world_state_updated(world_state)

onready var _server: Server = get_node("/root/Server")
onready var _player_manager: PlayerManager = get_node("../PlayerManager")

var _player_states : Dictionary = {}
var world_processing_offset = 0 # to be set from the Room


func _physics_process(_delta):
	if _player_manager.players.size() >= 2:
		emit_signal("world_state_updated", _create_world_state())


func _create_world_state():
	var time = _server.get_server_time()
	var player_states = {}
	for player_id in _player_manager.players:
		# Skip if given player hasn't send any inputs yet
		# TODO: Should be possible to set and send the player_state anyways
		#if not _player_manager.player_inputs.has(player_id):
		#	continue
		
		var player_state: PlayerState = PlayerState.new()
		player_state.timestamp = _player_manager.player_inputs[player_id].get_closest_or_earlier(time - world_processing_offset).timestamp \
				if _player_manager.player_inputs.has(player_id) else 0
		player_state.id = player_id
		player_state.position = _player_manager.players[player_id].transform.origin
		player_state.velocity = _player_manager.players[player_id].velocity
		player_state.acceleration = _player_manager.players[player_id].acceleration
		player_state.rotation = _player_manager.players[player_id].rotation.y
		player_state.rotation_velocity = _player_manager.players[player_id].rotation_velocity
		
		player_states[player_id] = player_state
	
	var world_state: WorldState = WorldState.new()

	world_state.timestamp = time - world_processing_offset
	world_state.player_states = player_states
	
	return world_state
