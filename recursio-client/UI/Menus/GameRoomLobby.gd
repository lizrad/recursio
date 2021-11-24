extends PanelContainer
class_name GameRoomLobby

export var icon_ready: Texture
export var icon_not_ready: Texture

signal btn_leave_pressed()

onready var _game_room_name: Label = get_node("Content/TopBar/GameRoomName")
onready var _player_list: ItemList = get_node("Content/PlayerList")

onready var _btn_ready: Button = get_node("Content/BottomBar/Btn_Ready")
onready var _btn_leave: Button = get_node("Content/BottomBar/Btn_Leave")

var _game_room_id: int
var _player_id_index_dic: Dictionary = {}

var _player_is_ready: bool = false

func _ready():
	var _error = _btn_ready.connect("pressed", self, "_on_btn_ready_pressed")
	_error = _btn_leave.connect("pressed", self, "_on_leave_pressed")


func init(game_room_id, game_room_name) -> void:
	_game_room_id = game_room_id
	_game_room_name.text = game_room_name


func reset():
	_player_id_index_dic.clear()
	toggle_ready_button(false)


func reset_players():
	for player_id in _player_id_index_dic:
		set_player_ready(player_id, false)
	toggle_ready_button(false)


func set_players(player_id_name_dic, client_id) -> void:
	_player_list.clear()
	_player_id_index_dic.clear()
	var index = 0
	for player_id in player_id_name_dic:
		_player_list.add_item(player_id_name_dic[player_id] + " (#%s)" %player_id, icon_not_ready, false)
		if client_id == player_id:
			_player_list.set_item_custom_bg_color(index, Color(1, 1, 1, 0.05))
		_player_id_index_dic[player_id] = index
		index += 1


func set_player_ready(player_id: int, is_ready: bool):
	_player_list.set_item_icon(_player_id_index_dic[player_id], icon_ready if is_ready else icon_not_ready)


func toggle_ready_button(player_is_ready: bool) -> void:
	_btn_ready.text = "Cancel" if player_is_ready else "Ready"
	_btn_ready.disabled = false
	_player_is_ready = player_is_ready


func _on_btn_ready_pressed() -> void:
	_btn_ready.disabled = true
	if(_player_is_ready):
		Server.send_game_room_not_ready(_game_room_id)
	else:
		Server.send_game_room_ready(_game_room_id)


func _on_leave_pressed() -> void:
	Server.send_leave_game_room(_game_room_id)
	self.hide()
	toggle_ready_button(false)
	emit_signal("btn_leave_pressed")
