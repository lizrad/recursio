extends Panel
class_name GameEndScreen


onready var _start_menu: StartMenu = get_node("/root/StartMenu")
onready var _back_to_title_button: SoundButton = get_node("GameEndScreenContainer/ElementsList/Buttons/BackToTitleButton")
onready var _back_to_room_button: SoundButton = get_node("GameEndScreenContainer/ElementsList/Buttons/BackToRoomButton")
onready var _title: Label = get_node("GameEndScreenContainer/ElementsList/Title")
onready var _title_background_panel: Panel = get_node("GameEndScreenContainer/ElementsList/Title/TitleBackgroundPanel")
onready var _player_kill_stats: StatsUI = get_node("GameEndScreenContainer/ElementsList/PlayerKillStats")
onready var _player_death_stats: StatsUI = get_node("GameEndScreenContainer/ElementsList/PlayerDeathStats")
onready var _ghost_kill_stats: StatsUI = get_node("GameEndScreenContainer/ElementsList/GhostKillStats")
onready var _ghost_death_stats: StatsUI = get_node("GameEndScreenContainer/ElementsList/GhostDeathStats")
onready var connection_lost_container: Control = get_node("GameEndScreenContainer/ElementsList/ConnectionLostContainer")


func _ready() -> void:
	var _error = _back_to_title_button.connect("pressed", self, "_on_back_to_title_button_pressed");
	_error = _back_to_room_button.connect("pressed", self, "_on_back_to_room_button_pressed");
	
	_player_kill_stats.set_title("Player Kills")
	_player_kill_stats.set_descriptions("You", "Opponent")
	_player_death_stats.set_title("Player Deaths")
	_player_death_stats.set_descriptions("You", "Opponent")
	_ghost_kill_stats.set_title("Ghost Kills")
	_ghost_kill_stats.set_descriptions("Yours", "Opponents")
	_ghost_death_stats.set_title("Ghost Deaths")
	_ghost_death_stats.set_descriptions("Yours", "Opponents")


func set_stats(player_team_id: int, _player_kills: Array, _player_deaths: Array, _ghost_kills: Array, _ghost_deaths: Array) -> void:
	var enemy_team_id = abs(player_team_id-1)
	_player_kill_stats.set_values(_player_kills[player_team_id], _player_kills[enemy_team_id])
	_player_death_stats.set_values(_player_deaths[player_team_id], _player_deaths[enemy_team_id])
	_ghost_kill_stats.set_values(_ghost_kills[player_team_id], _ghost_kills[enemy_team_id])
	_ghost_death_stats.set_values(_ghost_deaths[player_team_id], _ghost_deaths[enemy_team_id])


func set_title(title: String) -> void:
	_title.text = title


func set_panel_color(color_name: String) -> void:
	ColorManager.color_object_by_property(color_name, _title_background_panel, "self_modulate")


func enable_room_button() -> void:
	_back_to_room_button.disabled = false


func disable_room_button() -> void:
	_back_to_room_button.disabled = true


func enable_title_button() -> void:
	_back_to_title_button.disabled = false


func disable_title_button() -> void:
	_back_to_title_button.disabled = true


func show_stats() -> void:
	_player_kill_stats.show()
	_player_death_stats.show()
	_ghost_kill_stats.show()
	_ghost_death_stats.show()


func hide_stats() -> void:
	_player_kill_stats.hide()
	_player_death_stats.hide()
	_ghost_kill_stats.hide()
	_ghost_death_stats.hide()


func show_connection_lost_text() -> void:
	connection_lost_container.show()


func hide_connection_lost_text() -> void:
	connection_lost_container.hide()


func _on_back_to_title_button_pressed() -> void:
	Server.disconnect_from_server(true)
	_start_menu.return_to_title()


func _on_back_to_room_button_pressed() -> void:
	_start_menu.return_to_game_room_lobby()
