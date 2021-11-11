extends PanelContainer
class_name GameRoomUI

signal btn_ready_pressed()
signal btn_leave_pressed()

onready var _game_room_name: Label = get_node("Content/TopBar/GameRoomName")
onready var _player_list: ItemList = get_node("Content/PlayerList")

onready var _btn_ready: Button = get_node("Content/BottomBar/Btn_Ready")
onready var _btn_leave: Button = get_node("Content/BottomBar/Btn_Leave")

var _game_room_id

func _ready():
	_btn_ready.connect("pressed", self, "_on_ready_pressed")
	_btn_leave.connect("pressed", self, "_on_leave_pressed")


func init(game_room_id, game_room_name) -> void:
	_game_room_id = game_room_id
	_game_room_name.text = game_room_name


func set_players(player_id_name_dic) -> void:
	_player_list.clear()
	for player_id in player_id_name_dic:
		_player_list.add_item(player_id_name_dic[player_id] + "#" + str(player_id))


func _on_ready_pressed() -> void:
	_btn_ready.disabled = true
	Server.send_game_room_ready(_game_room_id)
	emit_signal("btn_ready_pressed")


func _on_leave_pressed() -> void:
	Server.send_leave_game_room(_game_room_id)
	self.hide()
	emit_signal("btn_leave_pressed")
