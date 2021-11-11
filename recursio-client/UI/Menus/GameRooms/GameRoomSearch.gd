extends PanelContainer
class_name GameRoomSearch

signal btn_create_game_room_pressed()
signal btn_back_pressed()
signal btn_join_game_room_pressed()


onready var _room_filter: LineEdit = get_node("Content/TopBar/LineEdit_GameRoomFilter")
onready var _game_room_list: ItemList = get_node("Content/ItemList_GameRooms")

onready var _btn_create_room: Button = get_node("Content/TopBar/Btn_CreateGameRoom")
onready var _btn_refresh_game_rooms: Button = get_node("Content/TopBar/Btn_Refresh")
onready var _btn_back: Button = get_node("Content/TopBar/Btn_Back")
onready var _btn_join_game_room: Button = get_node("Content/BottomBar/Btn_JoinGameRoom")

# Game Room ID - Game Room Name
var _game_room_dic := {}


func _ready():	
	_room_filter.connect("text_changed", self, "_on_filter_text_changed")
	
	_btn_create_room.connect("pressed", self, "_on_create_game_room_pressed")
	_btn_refresh_game_rooms.connect("pressed", self, "_on_send_get_game_rooms")
	_btn_back.connect("pressed", self, "_on_back_pressed")
	_btn_join_game_room.connect("pressed", self, "_on_join_game_room_pressed")


func add_game_room(game_room_id, game_room_name) -> void:
	_game_room_list.add_item(game_room_name + "#" + str(game_room_id))
	_game_room_list.set_item_metadata(_game_room_list.get_item_count() - 1, game_room_id)
	_game_room_dic[game_room_id] = game_room_name


func set_game_rooms(game_room_dic) -> void:
	_game_room_list.clear()
	for game_room_id in game_room_dic:
		var game_room_name = game_room_dic[game_room_id]
		_game_room_list.add_item(game_room_name + "#" + str(game_room_id))
		_game_room_list.set_item_metadata(_game_room_list.get_item_count() - 1, game_room_id)
		_game_room_dic[game_room_id] = game_room_name


func get_selected_game_room() -> int:
	var selected_game_rooms = _game_room_list.get_selected_items()
	if selected_game_rooms.size() == 0:
		return -1
	else:
		return _game_room_list.get_item_metadata(selected_game_rooms[0])


func get_game_room_name(game_room_id) -> String:
	return _game_room_dic[game_room_id]


func _on_filter_text_changed(new_text) -> void:
	pass


func _on_create_game_room_pressed() -> void:
	emit_signal("btn_create_game_room_pressed")


func _on_send_get_game_rooms() -> void:
	Server.send_get_game_rooms()


func _on_back_pressed() -> void:
	self.hide()
	emit_signal("btn_back_pressed")


func _on_join_game_room_pressed() -> void:
	if get_selected_game_room() != -1:
		emit_signal("btn_join_game_room_pressed")
		self.hide()