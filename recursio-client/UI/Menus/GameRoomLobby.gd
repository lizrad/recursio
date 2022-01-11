extends PanelContainer
class_name GameRoomLobby

export var icon_ready: Texture
export var icon_not_ready: Texture

signal btn_leave_pressed()

onready var _game_room_name: Label = get_node("Content/TopBar/GameRoomName")
onready var _player_list: ItemList = get_node("Content/HBoxContainer/PlayerList")

onready var _btn_ready: Button = get_node("Content/BottomBar/Btn_Ready")
onready var _btn_leave: Button = get_node("Content/BottomBar/Btn_Leave")


onready var _level_names = [
	"|---|",
	"|- -|",
	"%*"
]

onready var _level_preview_icons = [
	preload("res://Resources/Icons/level/LevelH.png"),
	preload("res://Resources/Icons/level/LevelHGap.png"),
	preload("res://Resources/Icons/level/LevelHGap.png")
]

onready var _level_preview: TextureRect = get_node("Content/HBoxContainer/VBoxContainer/LevelPreview")
onready var _level_list: OptionButton = get_node("Content/HBoxContainer/VBoxContainer/HBoxContainer2/LevelList")
onready var _fog_of_war: CheckButton = get_node("Content/HBoxContainer/VBoxContainer/HBoxContainer/FogOfWarToggle")

var selected_level_index: int = 0

var _game_room_id: int
var _player_id_index_dic: Dictionary = {}

var _player_is_ready: bool = false

var _waiting_for_level_select: bool = false
var _waiting_for_fog_of_war_select: bool = false

func _ready():
	var _error = _btn_ready.connect("pressed", self, "_on_btn_ready_pressed")
	_error = _btn_leave.connect("pressed", self, "_on_leave_pressed")

	_error = connect("visibility_changed", self, "_on_visibility_changed")
	
	_level_preview.texture = _level_preview_icons[0]
	
	for level_name in _level_names:
		_level_list.add_item(level_name)
	
	
	_error = _level_list.connect("item_selected", self, "_on_level_selected")
	_error = _fog_of_war.connect("pressed", self, "_on_fog_of_war_pressed")


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


func grab_ready_button_focus() -> void:
	_btn_ready.grab_focus()


func set_is_owner(is_owner: bool) -> void:
	_level_list.disabled = !is_owner
	_fog_of_war.disabled = !is_owner


func set_selected_level(level_index: int) -> void:
	reset_players()
	selected_level_index = level_index
	_level_list.selected = level_index
	_level_preview.texture = _level_preview_icons[level_index]
	_waiting_for_level_select = false


func set_fog_of_war(is_enabled: bool) -> void:
	reset_players()
	Constants.fog_of_war_enabled = is_enabled
	_fog_of_war.pressed = is_enabled
	_waiting_for_fog_of_war_select = false


func enable_ready_button() -> void:
	if not _waiting_for_level_select and not _waiting_for_fog_of_war_select:
		_btn_ready.disabled = false


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


func _on_visibility_changed() -> void:
	if visible:
		_btn_ready.grab_focus()
	else:
		set_fog_of_war(true)
		set_selected_level(0)


func _on_level_selected(index: int) -> void:
	selected_level_index = index
	_btn_ready.disabled = true
	_waiting_for_fog_of_war_select = true
	Server.send_level_selected(index)


func _on_fog_of_war_pressed() -> void:
	_btn_ready.disabled = true
	_waiting_for_fog_of_war_select = true
	Server.send_fog_of_war_toggled(_fog_of_war.pressed)
