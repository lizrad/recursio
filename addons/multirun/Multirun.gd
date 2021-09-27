tool
extends EditorPlugin

var panel1
var panel2
var panel3
var pids = []

func _enter_tree():
	var editor_node = get_tree().get_root().get_child(0)
	var gui_base = editor_node.get_gui_base()
	var icon_transition = gui_base.get_icon("TransitionSync", "EditorIcons") #ToolConnect
	var icon_transition_auto = gui_base.get_icon("TransitionSyncAuto", "EditorIcons")
	var icon_load = gui_base.get_icon("Load", "EditorIcons")
	var icon_stop = gui_base.get_icon("Stop", "EditorIcons")
	
	panel2 = _add_tooblar_button("_loaddir_pressed", icon_load, icon_load)
	panel1 = _add_tooblar_button("_multirun_pressed", icon_transition, icon_transition_auto)
	panel3 = _add_tooblar_button("_stop_pressed", icon_stop, icon_stop)
	
	_add_setting("debug/multirun/number_of_windows", TYPE_INT, 2)
	_add_setting("debug/multirun/window_distance_x", TYPE_INT, 256)
	_add_setting("debug/multirun/window_distance_y", TYPE_INT, 64)
	_add_setting("debug/multirun/add_custom_args", TYPE_BOOL, false)
	_add_setting("debug/multirun/first_window_args", TYPE_STRING, "")
	_add_setting("debug/multirun/other_window_args", TYPE_STRING, "")

func _multirun_pressed():
	var window_count : int = ProjectSettings.get_setting("debug/multirun/number_of_windows")
	var window_dist_x : int = ProjectSettings.get_setting("debug/multirun/window_distance_x")
	var window_dist_y : int = ProjectSettings.get_setting("debug/multirun/window_distance_y")
	var add_custom_args : bool = ProjectSettings.get_setting("debug/multirun/add_custom_args")
	var first_args : String = ProjectSettings.get_setting("debug/multirun/first_window_args")
	var other_args : String = ProjectSettings.get_setting("debug/multirun/other_window_args")
	var commands = ["--position", "50,10"]
	if first_args && add_custom_args:
		for arg in first_args.split(" "):
			commands.push_front(arg)

	var main_run_args = ProjectSettings.get_setting("editor/main_run_args")
	if main_run_args != first_args:
		ProjectSettings.set_setting("editor/main_run_args", first_args)
	var interface = get_editor_interface()
	interface.play_main_scene()
	if main_run_args != first_args:
		ProjectSettings.set_setting("editor/main_run_args", main_run_args)

	kill_pids()
	for i in range(window_count-1):
		commands = ["--position", str(50 + (i+1) * window_dist_x) + "," + str(10 + (i+1) * window_dist_y)]
		if other_args && add_custom_args:
			for arg in other_args.split(" "):
				commands.push_front(arg)
		pids.append(OS.execute(OS.get_executable_path(), commands, false))

func _loaddir_pressed():
	OS.shell_open(OS.get_user_data_dir())
	
func _stop_pressed():
	kill_pids()
	var interface = get_editor_interface()
	interface.stop_playing_scene()

func _exit_tree():
	_remove_panels()
	kill_pids()
	
func kill_pids():
	for pid in pids:
		OS.kill(pid)
	pids = []

func _remove_panels():
	if panel1:
		remove_control_from_container(CONTAINER_TOOLBAR, panel1)
		panel1.free()
	if panel2:
		remove_control_from_container(CONTAINER_TOOLBAR, panel2)
		panel2.free()
	if panel3:
		remove_control_from_container(CONTAINER_TOOLBAR, panel3)
		panel3.free()

func _unhandled_input(event):	
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_F4:
			_multirun_pressed()

func _add_tooblar_button(action:String, icon_normal, icon_pressed):
	var panel = PanelContainer.new()
	var b = TextureButton.new();
	b.texture_normal = icon_normal
	b.texture_pressed = icon_pressed
	b.connect("pressed", self, action)
	panel.add_child(b)
	add_control_to_container(CONTAINER_TOOLBAR, panel)
	return panel
	
func _add_setting(name:String, type, value):
	if ProjectSettings.has_setting(name):
		return
	ProjectSettings.set(name, value)
	var property_info = {
		"name": name,
		"type": type
	}
	ProjectSettings.add_property_info(property_info)
