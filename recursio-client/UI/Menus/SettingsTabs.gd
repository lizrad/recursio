extends TabContainer
class_name SettingsTabs


onready var next_foci_for_back_button = [
	NodePath("../SettingsTabs/Video/FullScreen/FullScreenCheckButton"),
	NodePath("../SettingsTabs/Audio/MainVolume/VolumeSlider"),
	$Colors.get_next_focus_for_back_button()]
onready var previous_foci_for_back_button = [
	NodePath("../SettingsTabs/Video/Debug/DebugCheckButton"),
	NodePath("../SettingsTabs/Audio/EffectsVolume/VolumeSlider"),
	$Colors.get_previous_focus_for_back_button()]
onready var default_tab_foci = [
	get_node("Video/FullScreen/FullScreenCheckButton"),
	get_node("Audio/MainVolume/VolumeSlider"),
	$Colors.get_default_tab_focus()]
onready var _back_button = get_node("../BackButton")


func _ready() -> void:
	var _error = self.connect("tab_changed",self,"_on_tab_changed")


func _input(_event: InputEvent) -> void:
	if not get_parent().get_parent().visible:
		return
	
	if Input.is_action_just_pressed("ui_page_up"):
		var tab_number = min(get_tab_count()-1, current_tab + 1)
		current_tab = tab_number
	if Input.is_action_just_pressed("ui_page_down"):
		var tab_number = max(0, current_tab - 1)
		current_tab = tab_number


func _on_tab_changed(tab: int) -> void:
	default_tab_foci[tab].grab_focus()
	_back_button.focus_neighbour_bottom = next_foci_for_back_button[tab]
	_back_button.focus_next = next_foci_for_back_button[tab]
	_back_button.focus_neighbour_top = previous_foci_for_back_button[tab]
	_back_button.focus_previous = previous_foci_for_back_button[tab]
