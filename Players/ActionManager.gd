extends Node

var _actions = {}
var _map_input = {
	"player_shoot": Constants.ActionType.SHOOT,
	"player_melee": Constants.ActionType.MELEE,
	"player_dash": Constants.ActionType.DASH,
}

onready var _shot_scene = preload("res://Shared/Attacks/Shots/HitscanShot.tscn")
onready var _melee_scene = preload("res://Shared/Attacks/Melee/Melee.tscn")

# provide player and hud for up communication of signals
onready var player = get_parent()
onready var hud = player.get_node("HUD")

func _ready():
	# TEST: Action(ammo, cd, recharge, activation_max)
	# TODO: set from outside, add selected weapon type per configuration ingame
	var action = Action.new(10, 0.5, -1, 0)
	action.attack = _shot_scene
	_actions[Constants.ActionType.SHOOT] = action
	
	action = Action.new(2, 0.5, 5, 500)
	_actions[Constants.ActionType.DASH] = action
	
	action = Action.new(-1, 0.5, -1, 0)
	action.attack = _melee_scene
	_actions[Constants.ActionType.MELEE] = action

	for key in _actions:
		_actions[key].connect("ammunition_changed", self, "_on_ammu_changed", [key])
		_actions[key].connect("action_triggered", self, "_on_action_triggered", [key])
		_actions[key].connect("action_released", self, "_on_action_released", [key])
		# need to add actions to scene tree to be able to install a timer
		add_child(_actions[key])


# TODO: forward signal to ui
func _on_ammu_changed(ammo: int, type: int):
	assert(type in Constants.ActionType.values(), "_on_ammu_changed argument is expected to be an ActionType")
	Logger.debug("ammunition for type: " + str(type) + " changed to: " + str(ammo), "actions")

	hud.do_stuff()


func _on_action_triggered(type: int):
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


func _on_action_released(type: int):
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
