extends Node
class_name GameManager

# These are optional
onready var _game_end_screen
var _countdown_screen

var _level: Level

var _player 
var _enemy 
var _countdown_time: float = Constants.get_value("gameplay", "countdown_phase_seconds")

func _ready():
	if has_node("../../GameEndScreen"):
		_game_end_screen = get_node("../../GameEndScreen")
	
	if has_node("../../CountdownScreen"):
		_countdown_screen = get_node("../../CountdownScreen")
	
	var _error = Server.connect("capture_point_captured", self, "_on_capture_point_captured") 
	_error = Server.connect("capture_point_team_changed", self, "_on_capture_point_team_changed") 
	_error = Server.connect("capture_point_status_changed", self, "_on_capture_point_status_changed") 
	_error = Server.connect("capture_point_capture_lost", self, "_on_capture_point_capture_lost") 
	_error = Server.connect("ghost_hit", self, "_on_ghost_hit") 
	_error = Server.connect("quiet_ghost_hit", self, "_on_ghost_hit") 
	_error = Server.connect("player_hit", self, "_on_player_hit") 
	# TODO: this connection is messy af and the server should probably send a specific message when an opponent disconnect happens, 
	# but I don't know enough about the whole room management thing to play around with that signal flow
	_error = Server.connect("game_room_joined", self, "_on_opponent_disconnected")
	_error = Server.connect("server_disconnected", self, "_on_server_disconnected")
	_error = Server.connect("game_result", self, "_on_game_result")

var _player_kills: Array = [0,0]
var _player_deaths: Array = [0,0]
var _ghost_kills: Array = [0,0]
var _ghost_deaths: Array = [0,0]


func _on_game_result(winning_player_index) -> void:
	if _game_end_screen:
			_game_end_screen.set_stats(_player.team_id, _player_kills, _player_deaths, _ghost_kills, _ghost_deaths)
			_game_end_screen.show_stats()
			_game_end_screen.enable_room_button()
			_game_end_screen.enable_title_button()
			_game_end_screen.show()
	if winning_player_index == _player.player_id:
		Logger.info("Player won!", "gameplay")
		if _game_end_screen:
			_game_end_screen.set_panel_color("player_main")
			_game_end_screen.set_title("You Won!")
	else:
		Logger.info("Player lost!", "gameplay")
		if _game_end_screen:
			_game_end_screen.set_panel_color("enemy_main")
			_game_end_screen.set_title("You Lost!")

func _on_opponent_disconnected(_player_id_name_dic, _game_room_id):
	Logger.info("Opponent disconnected!", "connection")
	if _game_end_screen:
		_game_end_screen.set_panel_color("ui_error")
		_game_end_screen.enable_room_button()
		_game_end_screen.enable_title_button()
		_game_end_screen.set_title("Opponent disconnected!")
		_game_end_screen.hide_stats()
		_game_end_screen.show_connection_lost_text()
		_game_end_screen.show()

func _on_server_disconnected():
	Logger.info("Server disconnected!", "connection")
	if _game_end_screen:
		_game_end_screen.set_panel_color("ui_error")
		_game_end_screen.disable_room_button()
		_game_end_screen.enable_title_button()
		_game_end_screen.set_title("Server disconnected!")
		_game_end_screen.hide_stats()
		_game_end_screen.show_connection_lost_text()
		_game_end_screen.show()

func _on_player_hit(hit_player_id, perpetrator_player_id, perpetrator_timeline_index):
	if hit_player_id == _player.player_id:
		_player_deaths[_player.team_id] += 1
	else:
		_player_deaths[_enemy.team_id] += 1
	_check_for_perpetrator(perpetrator_player_id, perpetrator_timeline_index)

func _on_ghost_hit(victim_player_id, _victim_timeline_index, perpetrator_player_id, perpetrator_timeline_index) -> void:
	if victim_player_id == _player.player_id:
		_ghost_deaths[_player.team_id] += 1
	else:
		_ghost_deaths[_enemy.team_id] += 1
	_check_for_perpetrator(perpetrator_player_id, perpetrator_timeline_index)

func _check_for_perpetrator(perpetrator_player_id, perpetrator_timeline_index):
	if perpetrator_player_id == _player.player_id:
		if perpetrator_timeline_index == _player.timeline_index:
			_player_kills[_player.team_id] += 1
		else:
			_ghost_kills[_player.team_id] += 1
	else:
		if perpetrator_timeline_index == _enemy.timeline_index:
			_player_kills[_enemy.team_id] += 1
		else:
			_ghost_kills[_enemy.team_id] += 1

func _process(delta):
	if _countdown_screen and _countdown_screen.visible:
		_countdown_screen.update_text(int(_countdown_time))
		_countdown_time -= delta
		# Hide if countdown is finished
		if _countdown_time <= 0.0:
			hide_countdown_screen()

func set_level(level: Level):
	_level = level


func show_countdown_screen() -> void:
	if _countdown_screen:
		_countdown_screen.show()


func hide_countdown_screen() -> void:
	if _countdown_screen:
		_countdown_screen.hide()
	_countdown_time = Constants.get_value("gameplay","countdown_phase_seconds")


func get_spawn_points(team_id) -> Array:
	return _level.get_spawn_points(team_id)


func get_spawn_point(team_id, timeline_index) -> Node:
	return _level.get_spawn_points(team_id)[timeline_index]


func get_capture_points() -> Array:
	return _level.get_capture_points()


func toggle_spawn_points(toggle: bool) -> void:
	_level.toggle_spawn_points(toggle)


func toggle_capture_points(toggle: bool) -> void:
	_level.toggle_capture_points(toggle)


func set_player(player):
	_player = player
	_level.show_spawn_point_weapon_type(_player.team_id)


func set_enemy(enemy):
	_enemy = enemy


func reset() -> void:
	if _game_end_screen and _countdown_screen:
		_game_end_screen.hide()
		_countdown_screen.hide()
	# Reset level
	_level.reset()
	_level.toggle_capture_points(false)
	_level.toggle_spawn_points(true)


func _on_capture_point_captured(capturing_player_id, capture_point):
	_level.get_capture_points()[capture_point].capture(capturing_player_id)


func _on_capture_point_team_changed(capturing_player_id, capture_point):
	_level.get_capture_points()[capture_point].set_capturing_player(capturing_player_id)


func _on_capture_point_status_changed(capturing_player_id, capture_point, capture_progress):
	_level.get_capture_points()[capture_point].set_capture_status(capturing_player_id, capture_progress)


func _on_capture_point_capture_lost(capturing_player_id, capture_point):
	_level.get_capture_points()[capture_point].capture_lost(capturing_player_id)

