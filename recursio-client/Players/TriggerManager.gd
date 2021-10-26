extends Node

# Handles Triggers and starts the corresponding Actions, as well as sending the
# triggers to the server.

var _current_fire_action = GlobalActionManager.get_action(GlobalActionManager.ActionType.HITSCAN)
var _current_special_movement_action = GlobalActionManager.get_action(GlobalActionManager.ActionType.DASH)
var _current_default_attack_action = GlobalActionManager.get_action(GlobalActionManager.ActionType.MELEE)

var _map_input = {
	"player_shoot": _current_fire_action,
	"player_melee": _current_default_attack_action,
	"player_dash": _current_special_movement_action
}

# provide player and hud for up communication of signals
onready var player = get_parent()
onready var hud = player.get_node("HUD")


func _ready():
	setup_action_connections(_current_fire_action, GlobalActionManager.Trigger.FIRE_START)
	setup_action_connections(_current_special_movement_action, GlobalActionManager.Trigger.SPECIAL_MOVEMENT_START)
	setup_action_connections(_current_default_attack_action, GlobalActionManager.Trigger.DEFAULT_ATTACK_START)

	# TODO: move to outer action initialization
	hud.update_ammo_type(_current_fire_action.img_bullet);
	hud.update_ammo(GlobalActionManager.Trigger.FIRE_START, _current_fire_action.max_ammo)
	hud.update_ammo(GlobalActionManager.Trigger.SPECIAL_MOVEMENT_START, _current_special_movement_action.max_ammo)


func setup_action_connections(action, type):
	action.connect("ammunition_changed", self, "_on_ammo_changed", [action, type])
	action.connect("action_triggered", self, "_on_action_triggered", [action, type])
	action.connect("action_released", self, "_on_action_released", [action, type])


func swap_weapon_type(ghost_index) -> void:
	_current_fire_action.disconnect("ammunition_changed", self, "_on_ammo_changed")
	_current_fire_action = GlobalActionManager.get_action_for_trigger(GlobalActionManager.Trigger.FIRE_START, ghost_index)
	
	# Workaround: not updated otherwise
	_map_input["player_shoot"] = _current_fire_action
	
	# Re-subscribe to signals
	setup_action_connections(_current_fire_action, GlobalActionManager.Trigger.FIRE_START)
	
	Logger.info("weapon selected: " + _current_fire_action.name, "actions")
	hud.update_ammo_type(_current_fire_action.img_bullet);
	hud.update_ammo(GlobalActionManager.Trigger.FIRE_START, _current_fire_action.ammunition)


func _on_ammo_changed(ammo: int, action: Action, type: int) -> void:
	Logger.debug("ammunition for type: " + str(type) + " changed to: " + str(ammo), "actions")

	hud.update_ammo(type, ammo)


func _on_action_triggered(action: Action, type: int) -> void:
	player.set_action_status(GlobalActionManager.get_action_type_for_trigger(type, player.ghost_index),true)
	Logger.debug("action triggered for name: " + str(action.name) + " on time: " + str(action.activation_time), "actions")
	InputManager.add_trigger_to_input_frame(type)


func _on_action_released(action: Action, type: int) -> void:
	player.set_action_status(GlobalActionManager.get_action_type_for_trigger(type, player.ghost_index),false)
	Logger.debug("action released for type: " + str(type), "actions")
	InputManager.remove_trigger_from_input_frame(type)


func handle_input() -> void:
	for input in _map_input:
		var action = _map_input[input]
		
		if not action:
			return
		
		# Either enable or disable the action
		if Input.is_action_pressed(input):
			Logger.debug("Action " + str(input) + " pressed", "actions")
			GlobalActionManager.set_active(action, true, player, get_tree().root)
		elif action.activation_time > 0:
			Logger.debug("Action " + str(input) + " released", "actions")
			GlobalActionManager.set_active(action, false, player, get_tree().root)
