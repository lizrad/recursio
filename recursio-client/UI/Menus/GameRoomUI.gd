extends PanelContainer
class_name GameRoomUI

export var icon_ready: Texture
export var icon_not_ready: Texture

signal btn_ready_pressed()
signal btn_not_ready_pressed()
signal btn_leave_pressed()

onready var _game_room_name: Label = get_node("Content/TopBar/GameRoomName")
onready var _player_list: ItemList = get_node("Content/PlayerList")

onready var _btn_ready: Button = get_node("Content/BottomBar/Btn_Ready")
onready var _btn_leave: Button = get_node("Content/BottomBar/Btn_Leave")

var _game_room_id: int
var _player_id_index_dic: Dictionary = {}

func _ready():
	var _error = _btn_ready.connect("pressed", self, "_on_ready_pressed")
	_error = _btn_leave.connect("pressed", self, "_on_leave_pressed")


func init(game_room_id, game_room_name) -> void:
	_game_room_id = game_room_id
	_game_room_name.text = game_room_name


func set_players(player_id_name_dic, client_id) -> void:
	_player_list.clear()
	_player_id_index_dic.clear()
	var index = 0
	for player_id in player_id_name_dic:
		_player_list.add_item(player_id_name_dic[player_id] + "#" + str(player_id), icon_not_ready)
		if client_id == player_id:
			_player_list.set_item_custom_bg_color(index, Color(1, 1, 1, 0.05))
		_player_id_index_dic[player_id] = index
		index += 1


func set_player_ready(player_id: int, is_ready: bool):
	_player_list.set_item_icon(_player_id_index_dic[player_id], icon_ready if is_ready else icon_not_ready)


func switch_to_not_ready_button() -> void:
	_btn_ready.disconnect("pressed", self, "_on_ready_pressed")
	var _error = _btn_ready.connect("pressed", self, "_on_not_ready_pressed")
	_btn_ready.text = "Cancel"
	_btn_ready.disabled = false


func switch_to_ready_button() -> void:
	_btn_ready.disconnect("pressed", self, "_on_not_ready_pressed")
	var _error = _btn_ready.connect("pressed", self, "_on_ready_pressed")
	_btn_ready.text = "Ready"
	_btn_ready.disabled = false


func _on_ready_pressed() -> void:
	_btn_ready.disabled = true
	Server.send_game_room_ready(_game_room_id)
	emit_signal("btn_ready_pressed")


func _on_not_ready_pressed() -> void:
	_btn_ready.disabled = true
	Server.send_game_room_not_ready(_game_room_id)
	emit_signal("btn_not_ready_pressed")


func _on_leave_pressed() -> void:
	Server.send_leave_game_room(_game_room_id)
	self.hide()
	switch_to_ready_button()
	emit_signal("btn_leave_pressed")
