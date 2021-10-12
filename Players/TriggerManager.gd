extends Node

# Handles Triggers and starts the corresponding Actions, as well as sending the
# triggers to the server.

var _current_fire_action = ActionManager.get_action(ActionManager.ActionType.HITSCAN)
var _current_special_movement_action = ActionManager.get_action(ActionManager.ActionType.DASH)
var _current_default_attack_action = ActionManager.get_action(ActionManager.ActionType.MELEE)

var _map_input = {
	"player_shoot": _current_fire_action,
	"player_melee": _current_default_attack_action,
	"player_dash": _current_special_movement_action
}

# provide player and hud for up communication of signals
onready var player = get_parent()
onready var hud = player.get_node("HUD")


func _ready():
	setup_action_connections(_current_fire_action, ActionManager.ActionType.HITSCAN)
	setup_action_connections(_current_special_movement_action, ActionManager.ActionType.DASH)
	setup_action_connections(_current_default_attack_action, ActionManager.ActionType.MELEE)

	# TODO: move to outer action initialization
	hud.update_ammo(ActionManager.Trigger.FIRE_START, _current_fire_action.max_ammo)
	hud.update_ammo(ActionManager.Trigger.SPECIAL_MOVEMENT_START, _current_special_movement_action.max_ammo)


func setup_action_connections(action, type):
	action.connect("ammunition_changed", self, "_on_ammo_changed", [action, type])
	action.connect("action_triggered", self, "_on_action_triggered", [action, type])
	action.connect("action_released", self, "_on_action_released", [action, type])


func swap_weapon_type(ghost_index) -> void:
	_current_fire_action.disconnect("ammunition_changed", self, "_on_ammo_changed")
	_current_fire_action = ActionManager.get_action_for_trigger(ActionManager.Trigger.FIRE_START, ghost_index)
	
	# Workaround: not updated otherwise
	_map_input["player_shoot"] = _current_fire_action
	
	# Re-subscribe to signals
	_current_fire_action.connect("ammunition_changed", self, "_on_ammo_changed", [ActionManager.Trigger.FIRE_START])
	Logger.info("weapon selected: " + _current_fire_action.name, "actions")
	hud.update_ammo(ActionManager.Trigger.FIRE_START, _current_fire_action.ammunition)


# TODO: forward signal to ui
# 	- selected weapon ammo
# 	- dash ammo
func _on_ammo_changed(ammo: int, type: int) -> void:
	Logger.debug("ammunition for type: " + str(type) + " changed to: " + str(ammo), "actions")

	hud.update_ammo(type, ammo)


func _on_action_triggered(action: Action, type: int) -> void:
	Logger.debug("action triggered for name: " + str(action.name) + " on time: " + str(action.activation_time), "actions")

	# TODO: define common struct for Actions
	if type == ActionManager.ActionType.DASH:
		player.dash_start = action.activation_time
		var dash_state = {"T": Server.get_server_time(), "S": 1}
		Server.send_dash_state(dash_state)
	else:
		var action_trigger = {"A": type, "T": Server.get_server_time()}
		Server.send_action_trigger(action_trigger)


func _on_action_released(action: Action, type: int) -> void:
	Logger.debug("action released for type: " + str(type), "actions")

	if type == ActionManager.ActionType.DASH:
		Logger.info("dash released", "actions")
		player.dash_start = 0
		var dash_state = {"T": Server.get_server_time(), "S": 0}
		Server.send_dash_state(dash_state)


func handle_input() -> void:
	for input in _map_input:
		var action = _map_input[input]
		
		if action:
			if Input.is_action_pressed(input):
				var activate = (
					action.activation_max < 1
					or action.activation_time < 1
					or (action.activation_time + action.activation_max) > OS.get_ticks_msec()
				)

				Logger.debug(
					("activation for " + str(input) + " with max: " + str(action.activation_max) + " act_time: " + str(action.activation_time)
					+ " for OS.ticks: " + str(OS.get_ticks_msec()) + " -> triggered: " + str(activate)), "actions")
				
				ActionManager.set_active(action, true, player, get_tree().root)
			elif action.activation_time > 0:
				Logger.debug(
					("activation for " + str(input) + " with max: " + str(action.activation_max) + " act_time: " + str(action.activation_time)
					+ " for OS.ticks: " + str(OS.get_ticks_msec()) + " -> triggered: False"), "actions")

				ActionManager.set_active(action, false, player, get_tree().root)
