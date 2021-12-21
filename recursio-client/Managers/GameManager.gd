extends Node
class_name GameManager

# These are optional
onready var _game_end_screen
var _countdown_screen

var _level: Level

var _team_id := -1
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


func hide_game_result_screen() -> void:
	if _game_end_screen:
		_game_end_screen.hide()

func set_stats(player_kills: Array, player_deaths: Array, ghost_kills: Array, ghost_deaths: Array):
	if _game_end_screen:
		_game_end_screen.set_stats(_team_id, player_kills, player_deaths, ghost_kills, ghost_deaths)


func show_win() -> void:
	Logger.info("Player won!", "gameplay")
	if _game_end_screen:
		_game_end_screen.set_panel_color("player_main")
		_game_end_screen.enable_room_button()
		_game_end_screen.enable_title_button()
		_game_end_screen.set_title("You Won!")
		_game_end_screen.show_stats()
		_game_end_screen.show()


func show_loss() -> void:
	Logger.info("Player lost!", "gameplay")
	if _game_end_screen:
		_game_end_screen.set_panel_color("enemy_main")
		_game_end_screen.enable_room_button()
		_game_end_screen.enable_title_button()
		_game_end_screen.set_title("You Lost!")
		_game_end_screen.show_stats()
		_game_end_screen.show()

func show_enemy_disconnect() -> void:
	Logger.info("Enemy disconnected!", "connection")
	if _game_end_screen:
		_game_end_screen.set_panel_color("ui_error")
		_game_end_screen.enable_room_button()
		_game_end_screen.enable_title_button()
		_game_end_screen.set_title("Opponent disconnected!")
		_game_end_screen.hide_stats()
		_game_end_screen.show()


func show_player_disconnect() -> void:
	Logger.info("Server disconnected!", "connection")
	if _game_end_screen:
		_game_end_screen.set_panel_color("ui_error")
		_game_end_screen.disable_room_button()
		_game_end_screen.enable_title_button()
		_game_end_screen.set_title("Server disconnected!")
		_game_end_screen.hide_stats()
		_game_end_screen.show()

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


func set_team_id(team_id):
	_team_id = team_id
	# display spawnpoint weapon type only for active team
	_level.show_spawn_point_weapon_type(_team_id)
	# TODO: should be reset if team_id changes


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

