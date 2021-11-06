extends Node
class_name WorldStateManager

var world_processing_offset = 0 # to be set from the GameRoom


func create_world_state(player_dic, player_inputs) -> WorldState:
	var time = OS.get_system_time_msecs()
	var player_states = {}
	for player_id in player_dic:
		
		var last_processed_packet_timestamp = player_dic[player_id].timestamp_of_previous_packet
		
		var player_state: PlayerState = PlayerState.new()
		player_state.timestamp = last_processed_packet_timestamp
		player_state.id = player_id
		player_state.position = player_dic[player_id].position
		player_state.velocity = player_dic[player_id].velocity
		player_state.acceleration = player_dic[player_id].acceleration
		player_state.rotation_y = player_dic[player_id].rotation_y
		player_state.buttons.mask = player_dic[player_id].last_triggers.mask
		
		player_dic[player_id].last_triggers.mask = 0
		player_states[player_id] = player_state
	
	var world_state: WorldState = WorldState.new()

	world_state.timestamp = time - world_processing_offset
	world_state.player_states = player_states
	
	return world_state
