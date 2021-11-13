extends PanelContainer
class_name GameRoomCreation

signal btn_create_game_room_pressed(game_room_name)
signal btn_back_pressed()

onready var _btn_create_room: Button = get_node("Content/BottomBar/Btn_CreateRoom")
onready var _btn_back: Button = get_node("Content/BottomBar/Btn_Back")

onready var _game_room_name: LineEdit = get_node("Content/VBoxContainer/GameRoomName")


func _ready():
	var _error = _btn_create_room.connect("pressed", self, "_on_create_game_room_pressed")
	_error = _btn_back.connect("pressed", self, "_on_back_pressed")


# OVERRIDE #
func show():
	_game_room_name.grab_focus()
	.show()


func _on_create_game_room_pressed():
	emit_signal("btn_create_game_room_pressed", _game_room_name.text)


func _on_back_pressed():
	self.hide()
	emit_signal("btn_back_pressed")
