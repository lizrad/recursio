extends Node

var _map_input = {
	"player_shoot": Enums.ActionType.SHOOT,
	"player_melee": Enums.ActionType.MELEE,
	"player_dash": Enums.ActionType.DASH,
}

onready var _current_weapon = Actions.shot

# provide player and hud for up communication of signals
onready var player = get_parent()
onready var hud = player.get_node("HUD")

func _ready():

	for key in Actions.types_to_actions:
		Logger.info("connecting key " + str(key) + " to events...", "actions")
		Actions.types_to_actions[key].connect("ammunition_changed", self, "_on_ammu_changed", [key])
		Actions.types_to_actions[key].connect("action_triggered", self, "_on_action_triggered", [key])
		Actions.types_to_actions[key].connect("action_released", self, "_on_action_released", [key])

	# need to add actions to scene tree to be able to install a timer
	for action in Actions.allActions.types_to_actions:
		add_child(action)

	# TODO: move to outer action initialization
	hud.update_ammo(Enums.ActionType.SHOOT, Actions.types_to_actions[Enums.ActionType.SHOOT].max_ammo)
	hud.update_ammo(Enums.ActionType.DASH, Actions.types_to_actions[Enums.ActionType.DASH].max_ammo)


# TODO: remove, only for testing purposes!
# later weapon selection will be set from server depending on current round
# and/or pre-setup configuration
func swap_weapon_type(weapon_type) -> void:
	if weapon_type == Enums.WeaponType.WALL:
		Actions.types_to_actions[Enums.ActionType.SHOOT] = Actions.wall
	else:
		Actions.types_to_actions[Enums.ActionType.SHOOT] = Actions.shot
	
	_current_weapon = Actions.types_to_actions[Enums.ActionType.SHOOT]
	Logger.info("weapon selected: " + _current_weapon.name, "actions")
	hud.update_ammo(Enums.ActionType.SHOOT, Actions.types_to_actions[Enums.ActionType.SHOOT].ammunition)


# TODO: forward signal to ui
# 	- selected weapon ammo
# 	- dash ammo
func _on_ammu_changed(ammo: int, type: int) -> void:
	assert(type in Enums.ActionType.values(), "_on_ammu_changed argument is expected to be an ActionType")
	Logger.debug("ammunition for type: " + str(type) + " changed to: " + str(ammo), "actions")

	hud.update_ammo(type, ammo)


func _on_action_triggered(type: int) -> void:
	assert(type in Enums.ActionType.values(), "_on_action_triggered argument is expected to be an ActionType")
	if Actions.types_to_actions.has(type):
		var action = Actions.types_to_actions[type] as Action
		Logger.debug("action triggered for type: " + str(type) + " on time: " + str(action.activation_time), "actions")

		# TODO: define common struct for Actions
		if type == Enums.ActionType.DASH:
			player.dash_start = action.activation_time
			var dash_state = {"T": Server.get_server_time(), "S": 1}
			Server.send_dash_state(dash_state)
		elif type == Enums.ActionType.SHOOT or type == Enums.ActionType.MELEE:
			var action_trigger = {"A": type, "T": Server.get_server_time()}
			Server.send_action_trigger(action_trigger)


func _on_action_released(type: int) -> void:
	assert(type in Enums.ActionType.values(), "_on_action_released argument is expected to be an ActionType")
	if Actions.types_to_actions.has(type):
		var action = Actions.types_to_actions[type] as Action
		Logger.debug("action released for type: " + str(type), "actions")

		if type == Enums.ActionType.DASH:
			Logger.info("dash released", "actions")
			player.dash_start = 0
			var dash_state = {"T": Server.get_server_time(), "S": 0}
			Server.send_dash_state(dash_state)


func handle_input() -> void:
	for input in _map_input:
		if Actions.types_to_actions.has(_map_input[input]):
			var action = Actions.types_to_actions[_map_input[input]] as Action
			if Input.is_action_pressed(input):
				var activate = (
					action.activation_max < 1
					or action.activation_time < 1
					or (action.activation_time + action.activation_max) > OS.get_ticks_msec()
				)

				Logger.debug(
					("activation for " + str(input) + " with max: " + str(action.activation_max) + " act_time: " + str(action.activation_time)
					+ " for OS.ticks: " + str(OS.get_ticks_msec()) + " -> triggered: " + str(activate)), "actions")

				action.set_active(activate, player, get_tree())
			elif action.activation_time > 0:
				Logger.debug(
					("activation for " + str(input) + " with max: " + str(action.activation_max) + " act_time: " + str(action.activation_time)
					+ " for OS.ticks: " + str(OS.get_ticks_msec()) + " -> triggered: False"), "actions")

				action.set_active(false, player, get_tree())
