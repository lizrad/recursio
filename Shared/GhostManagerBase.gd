extends Node
class_name GhostManager

#warning-ignore:unused_signal
signal ghost_hit(hit_data)
#warning-ignore:unused_signal
signal quiet_ghost_hit(hit_data)
#warning-ignore:unused_signal
signal new_record_data_applied(player)

onready var _server = get_node("/root/Server")
onready var _max_ghosts = Constants.get_value("ghosts", "max_amount")


var _game_manager
var _round_manager
var _action_manager
var _character_manager

# Timeline index <-> ghost
# holds every ghost 
var _ghosts: Array = []

var _game_phase_start_time = -1


func _ready():
	set_physics_process(false)


func _physics_process(delta):
	_update_ghosts(delta)
	


func init(game_manager,round_manager,action_manager, character_manager):
	_game_manager = game_manager
	_round_manager = round_manager
	_action_manager = action_manager
	_character_manager = character_manager
	set_physics_process(true)
	_spawn_all_ghosts()
	_disable_all_ghosts()
	_move_ghosts_to_spawn()


func on_preparation_phase_started() -> void:
	_stop_ghosts()
	_move_ghosts_to_spawn()


func on_countdown_phase_started() -> void:
	pass


func on_game_phase_started() -> void:
	_game_phase_start_time = _server.get_server_time()
	_start_ghosts(_game_phase_start_time)


func on_game_phase_stopped() -> void:
	_use_new_record_data()


# ABSTRACT #
func _spawn_all_ghosts():
	assert(false) #this must be overwritten in child class


# ABSTRACT #
func _enable_active_ghosts() -> void:
	assert(false) #this must be overwritten in child class


# ABSTRACT #
func _use_new_record_data():
	assert(false) #this must be overwritten in child class


# ABSTRACT #
func _on_ghost_hit(_hit_data: HitData):
	assert(false) #this must be overwritten in child class


# gets called every physics frame
func _update_ghosts(delta):
	for ghost in _ghosts:
		ghost.update(delta)


func _create_ghost(player_id, team_id, timeline_index, spawn_point, ghost_scene):
	var ghost = ghost_scene.instance()
	add_child(ghost)
	ghost.init(_action_manager, player_id, team_id, timeline_index, spawn_point)
	return ghost


func _update_ghost_record(ghost_array, timeline_index, record_data, round_index):
	ghost_array[timeline_index].set_record_data(record_data)
	ghost_array[timeline_index].round_index = round_index


func _move_ghosts_to_spawn() -> void:
	for ghost in _ghosts:
		ghost.move_to_spawn_point()


func refresh_active_ghosts():
	_disable_all_ghosts()
	_enable_active_ghosts()


func _disable_all_ghosts() -> void:
	for ghost in _ghosts:
		ghost.disable_body()


func _start_ghosts(start_time) -> void:
	for ghost in _ghosts:
		ghost.start_playing(start_time)


func _stop_ghosts() -> void:
	for ghost in _ghosts:
		ghost.stop_playing()





