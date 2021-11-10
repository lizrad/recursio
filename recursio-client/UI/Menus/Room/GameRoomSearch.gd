extends PanelContainer
class_name GameRoomSearch

signal btn_back_pressed()


onready var _room_filter: LineEdit = get_node("Content/TopBar/LineEdit_RoomFilter")
onready var _game_room_list: GameRoomList = get_node("Content/ItemList_GameRooms")

onready var _btn_create_room: Button = get_node("Content/TopBar/Btn_CreateRoom")
onready var _btn_refresh_rooms: Button = get_node("Content/TopBar/Btn_Refresh")
onready var _btn_back: Button = get_node("Content/TopBar/Btn_Back")


func _ready():
	_room_filter.connect("text_changed", self, "_on_filter_text_changed")
	
	_btn_create_room.connect("pressed", self, "_on_send_create_room")
	_btn_refresh_rooms.connect("pressed", self, "_on_send_refresh_rooms")
	_btn_back.connect("pressed", self, "_on_back_pressed")
	
	Server.connect("room_created", self, "_on_create_room")
	Server.connect("rooms_refreshed", self, "_on_refresh_rooms")


func _on_filter_text_changed(new_text):
	_game_room_list.filter_by(new_text)


func _on_send_create_room():
	Server.send_create_room()


func _on_create_room():
	pass


func _on_send_refresh_rooms():
	Server.send_refresh_rooms()


func _on_refresh_rooms(room_dic):
	for room_id in room_dic:
		_game_room_list.add_room_item(room_id, room_dic[room_id])


func _on_back_pressed():
	emit_signal("btn_back_pressed")
