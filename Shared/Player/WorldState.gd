extends Object
class_name WorldState

var timestamp: int
var player_states: Dictionary = {}

# Fills the object with the data from the given array
func from_array(data: Array)-> WorldState:
	timestamp = data[0]
	for i in range(1, data.size()):
		var player_state: PlayerState = PlayerState.new().from_array(data[i])
		player_states[player_state.id] = player_state
	return self


func to_array()-> Array:
	var data: Array = [timestamp]
	for player_id in player_states:
		data.append(player_states[player_id].to_array())
	return data
