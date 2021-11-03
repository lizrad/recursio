tool
extends EditorPlugin

const logger_plugin_scene = preload("res://addons/recursio-loggerplugin/LoggerPlugin.tscn")
const module_config_scene = preload("res://addons/recursio-loggerplugin/Module.tscn")
const module_mode_toggle_scene = preload("res://addons/recursio-loggerplugin/ModuleModeToggle.tscn")

var logger_plugin_instance

var config

var modes := ["VERBOSE","DEBUG", "INFO", "WARN", "ERROR"]

func _enter_tree():
	logger_plugin_instance = logger_plugin_scene.instance()
	# Add the main panel to the editor's main viewport.
	get_editor_interface().get_editor_viewport().add_child(logger_plugin_instance)
	# Hide the main panel. Very much required.
	make_visible(false)
	logger_plugin_instance.get_node("TitelBar/Refresh").connect("pressed",self,"_refresh")
	logger_plugin_instance.get_node("TitelBar/Editable").connect("toggled",self,"_toggle_editable")

func build():
	logger_plugin_instance.get_node("TitelBar/Editable").pressed = false
	return true
	
func _ready():
	_add_modes()
	_refresh()
	_is_editable()
	
func _add_modes():
	var mode_instance = module_config_scene.instance()
	mode_instance.get_node("ModuleName").text = "Modes:"
	for i in range(modes.size()):
		var toggle = module_mode_toggle_scene.instance()
		toggle.text = modes[i]
		toggle.connect("toggled",self,"_on_mode_toggled", [i])
		mode_instance.add_child(toggle)
	logger_plugin_instance.get_node("ModesBackground/ModesScrollContainer/Modes").add_child(mode_instance)

func _refresh():
	_refresh_config()
	_refresh_modules()
	_refresh_modes()
	_is_editable()
	
func _refresh_modules():
	_clear_modules()
	_load_modules()

func _refresh_config():
	config = ConfigFile.new()
	var err = config.load(LoggerPluginSingleton.CONFIG_PATH)
	if err:
		print("Could not load the config in '%s'; exited with error %d." % [LoggerPluginSingleton.CONFIG_PATH, err])
		return err

func _clear_modules():
	for module in logger_plugin_instance.get_node("ModulesBackground/ModulesScrollContainer/Modules").get_children():
		module.queue_free()

func _load_modules():
	if not config.has_section(Logger.PLUGIN_NAME):
		return
	var modules = config.get_value(Logger.PLUGIN_NAME, Logger.config_fields.modules)
	for i in range(modules.size()):
		if modules[i].has("name"):
			_add_new_module(modules[i].name, i, modules[i].output_strategies)

func _add_new_module(module_name, module_index, output_strategies):
	var module_instance = module_config_scene.instance()
	module_instance.get_node("ModuleName").text = module_name
	for i in range(output_strategies.size()):
		var toggle = module_mode_toggle_scene.instance()
		toggle.pressed = output_strategies[i]
		toggle.text = modes[i]
		toggle.connect("toggled",self,"_on_module_button_toggled", [toggle, module_index, i])
		module_instance.add_child(toggle)
	logger_plugin_instance.get_node("ModulesBackground/ModulesScrollContainer/Modules").add_child(module_instance)

func _refresh_modes():
	if not config.has_section(Logger.PLUGIN_NAME):
		return
	var modes_status =[false,false,false,false,false]
	var modules = config.get_value(Logger.PLUGIN_NAME, Logger.config_fields.modules)
	for module in modules:
		if module.has("name"):
			for i in range(module.output_strategies.size()):
				if module.output_strategies[i]:
					modes_status[i]=true
	var i = 0
	for mode in logger_plugin_instance.get_node("ModesBackground/ModesScrollContainer/Modes").get_children()[0].get_children():
		if mode is CheckButton:
			mode.disconnect("toggled",self,"_on_mode_toggled")
			mode.pressed = modes_status[i]
			mode.connect("toggled",self,"_on_mode_toggled", [i])
			i+=1

func _on_module_button_toggled(active: bool, button: CheckButton, module_index: int, mode_index:int):
	if _is_editable():
		var modules = config.get_value(Logger.PLUGIN_NAME, Logger.config_fields.modules)
		modules[module_index].output_strategies[mode_index] = int(active)
		config.save(LoggerPluginSingleton.CONFIG_PATH)
	_refresh()

func _is_editable() ->bool:
	_refresh_config()
	var editable = false
	if config.has_section_key(LoggerPluginSingleton.PLUGIN_NAME, LoggerPluginSingleton.GAME_RUNNNIG):
		if not config.get_value(LoggerPluginSingleton.PLUGIN_NAME, LoggerPluginSingleton.GAME_RUNNNIG):
			editable = true
	logger_plugin_instance.get_node("TitelBar/Editable").disconnect("toggled", self, "_toggle_editable")
	logger_plugin_instance.get_node("TitelBar/Editable").pressed = editable
	logger_plugin_instance.get_node("TitelBar/Editable").connect("toggled", self, "_toggle_editable")
	return editable

func _toggle_editable(active):
	_refresh_config()
	config.set_value(LoggerPluginSingleton.PLUGIN_NAME, LoggerPluginSingleton.GAME_RUNNNIG, not active)
	config.save(LoggerPluginSingleton.CONFIG_PATH)

func _on_mode_toggled(active: bool, mode_index:int):
	if not config.has_section(Logger.PLUGIN_NAME):
		return
	if _is_editable():
		var modules = config.get_value(Logger.PLUGIN_NAME, Logger.config_fields.modules)
		for module in modules:
			if module.has("name"):
				module.output_strategies[mode_index] = int(active)
		config.save(LoggerPluginSingleton.CONFIG_PATH)
	_refresh()
	pass

func _exit_tree():
	if logger_plugin_instance:
		logger_plugin_instance.queue_free()

func has_main_screen():
	return true

func make_visible(visible):
	if logger_plugin_instance:
		logger_plugin_instance.visible = visible

func get_plugin_name():
	return "Logger"

func get_plugin_icon():
	return get_editor_interface().get_base_control().get_icon("Node", "EditorIcons")
