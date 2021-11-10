extends PanelContainer
class_name GameRoomSearch

signal btn_create_game_room_pressed()
signal btn_back_pressed()
signal btn_join_game_room_pressed()


onready var _room_filter: LineEdit = get_node("Content/TopBar/LineEdit_GameRoomFilter")
onready var _game_room_list: GameRoomList = get_node("Content/ItemList_GameRooms")

onready var _btn_create_room: Button = get_node("Content/TopBar/Btn_CreateGameRoom")
onready var _btn_refresh_game_rooms: Button = get_node("Content/TopBar/Btn_Refresh")
onready var _btn_back: Button = get_node("Content/TopBar/Btn_Back")
onready var _btn_join_game_room: Button = get_node("Content/BottomBar/Btn_JoinGameRoom")


func _ready():	
	_room_filter.connect("text_changed", self, "_on_filter_text_changed")
	
	_btn_create_room.connect("pressed", self, "_on_create_game_room_pressed")
	_btn_refresh_game_rooms.connect("pressed", self, "_on_send_get_game_rooms")
	_btn_back.connect("pressed", self, "_on_back_pressed")
	_btn_join_game_room.connect("pressed", self, "_on_join_game_room_pressed")
	
	Server.connect("game_room_created", self, "_on_game_room_created")
	Server.connect("game_rooms_received", self, "_on_game_rooms_received")


func _on_filter_text_changed(new_text):
	_game_room_list.filter_by(new_text)


func _on_create_game_room_pressed():
	emit_signal("btn_create_game_room_pressed")


func _on_game_room_created(game_room_id, game_room_name):
	_game_room_list.add_game_room(game_room_id, game_room_name)


func _on_send_get_game_rooms():
	Server.send_get_game_rooms()


func _on_back_pressed():
	self.hide()
	emit_signal("btn_back_pressed")


func _on_join_game_room_pressed():
	if _game_room_list.get_selected_game_room() != -1:
		Server.send_join_game_room(_game_room_list.get_selected_game_room())
		emit_signal("btn_join_game_room_pressed")


func _on_game_rooms_received(game_room_dic):
	for room_id in game_room_dic:
		_game_room_list.add_game_room(room_id, game_room_dic[room_id])
