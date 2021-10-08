extends Node

var _map_input = {
	"player_shoot": Constants.ActionType.SHOOT,
	"player_melee": Constants.ActionType.MELEE,
	"player_dash": Constants.ActionType.DASH,
}

onready var _shot_scene = preload("res://Shared/Attacks/Shots/HitscanShot.tscn")
onready var _wall_scene = preload("res://Shared/Attacks/Shots/Wall.tscn")
onready var _melee_scene = preload("res://Shared/Attacks/Melee/Melee.tscn")

# preconfigured actions
# Action(ammo, cd, recharge, activation_max, action_scene)
# TODO: - unify ms/s input params
onready var _action_shot = Action.new("hitscan", 10, 0.5, -1, 0, _shot_scene)
onready var _action_wall = Action.new("wall", 3, 0.5, -1, 0, _wall_scene)
onready var _action_dash = Action.new("dash", 2, 0.5, 5, 500, null)
onready var _action_melee = Action.new("melee", -1, 0.5, -1, 0, _melee_scene)
onready var _all_actions = [ _action_shot, _action_wall, _action_melee, _action_dash ]
	
# TODO: - set from outside
#		- add selected weapon type per configuration ingame
onready var _actions = { 
	Constants.ActionType.SHOOT: _action_shot, 
	Constants.ActionType.MELEE: _action_melee, 
	Constants.ActionType.DASH: _action_dash
}
onready var _current_weapon = _action_shot

# provide player and hud for up communication of signals
onready var player = get_parent()
onready var hud = player.get_node("HUD")

func _ready():
	
	for key in _actions:
		_all_actions[key].connect("ammunition_changed", self, "_on_ammu_changed", [key])
		_all_actions[key].connect("action_triggered", self, "_on_action_triggered", [key])
		_all_actions[key].connect("action_released", self, "_on_action_released", [key])

	# need to add actions to scene tree to be able to install a timer
	for action in _all_actions:
		add_child(action)


# TODO: remove, only for testing purposes!
# later weapon selection will be set from server depending on current round
# and/or pre-setup configuration
func swap_weapon_type() -> void:
	_actions[Constants.ActionType.SHOOT] = _action_shot if _current_weapon == _action_wall else _action_wall
	_current_weapon = _actions[Constants.ActionType.SHOOT]
	Logger.info("weapon selected: " + _current_weapon.name, "actions")


# TODO: forward signal to ui
# 	- selected weapon ammo
# 	- dash ammo
func _on_ammu_changed(ammo: int, type: int) -> void:
	assert(type in Constants.ActionType.values(), "_on_ammu_changed argument is expected to be an ActionType")
	Logger.debug("ammunition for type: " + str(type) + " changed to: " + str(ammo), "actions")

	hud.do_stuff()


func _on_action_triggered(type: int) -> void:
	assert(type in Constants.ActionType.values(), "_on_action_triggered argument is expected to be an ActionType")
	if _actions.has(type):
		var action = _actions[type] as Action
		Logger.debug(
			"action triggered for type: " + str(type) + " on time: " + str(action.activation_time),
			"actions"
		)

		# TODO: define common struct for Actions
		if type == Constants.ActionType.DASH:
			player.dash_start = action.activation_time
			var dash_state = {"T": Server.get_server_time(), "S": 1}
			Server.send_dash_state(dash_state)
		elif type == Constants.ActionType.SHOOT or type == Constants.ActionType.MELEE:
			var action_trigger = {"A": type, "T": Server.get_server_time()}
			Server.send_action_trigger(action_trigger)


func _on_action_released(type: int) -> void:
	assert(type in Constants.ActionType.values(), "_on_action_released argument is expected to be an ActionType")
	if _actions.has(type):
		var action = _actions[type] as Action
		Logger.debug("action released for type: " + str(type), "actions")

		if type == Constants.ActionType.DASH:
			Logger.info("dash released", "actions")
			player.dash_start = 0
			var dash_state = {"T": Server.get_server_time(), "S": 0}
			Server.send_dash_state(dash_state)


func handle_input() -> void:
	for input in _map_input:
		if _actions.has(_map_input[input]):
			var action = _actions[_map_input[input]] as Action
			if Input.is_action_pressed(input):
				var activate = (
					action.activation_max < 1
					or action.activation_time < 1
					or (action.activation_time + action.activation_max) > OS.get_ticks_msec()
				)

				Logger.debug(
					(
						"activation for "
						+ str(input)
						+ " with max: "
						+ str(action.activation_max)
						+ " act_time: "
						+ str(action.activation_time)
						+ " for OS.ticks: "
						+ str(OS.get_ticks_msec())
						+ " -> triggered: "
						+ str(activate)
					),
					"actions"
				)

				action.set_active(activate)
			elif action.activation_time > 0:
				Logger.debug(
					(
						"activation for "
						+ str(input)
						+ " with max: "
						+ str(action.activation_max)
						+ " act_time: "
						+ str(action.activation_time)
						+ " for OS.ticks: "
						+ str(OS.get_ticks_msec())
						+ " -> triggered: False"
					),
					"actions"
				)

				action.set_active(false)
