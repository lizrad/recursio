extends Node

enum ActionType { SHOOT, DASH, MELEE }

var _actions = {}
var _map_input = { 
					"player_shoot": ActionType.SHOOT,
					"player_melee": ActionType.MELEE, 
					"player_dash": ActionType.DASH,
				 }

var _dash_start := 0.0

onready var player = get_parent()


func _ready():
	# TEST: Action(ammo, cd, recharge, activation_max)
	# TODO: set from outside, add selected weapon type per configuration ingame
	var action = Action.new(10, 0.5, -1, 0)
	_actions[ActionType.SHOOT] = action
	_actions[ActionType.DASH] = Action.new(2, 0.5, 5, 1000)
	_actions[ActionType.MELEE] = Action.new(-1, 0.5, -1, 0)

	for key in _actions:
		_actions[key].connect("ammunition_changed", self, "_on_ammu_changed", [key])
		_actions[key].connect("action_triggered", self, "_on_action_triggered", [key])
		_actions[key].connect("action_released", self, "_on_action_released", [key])
		# need to add actions to scene tree to be able to install a timer
		add_child(_actions[key])


# TODO: forward signal to ui
func _on_ammu_changed(ammo : int, type : int):
	assert(type in ActionType.values(), "_on_ammu_changed argument is expected to be an ActionType")
	print("ammunition for type: ", type, " changed to: ", ammo)


func _on_action_triggered(type : int):
	assert(type in ActionType.values(), "_on_action_triggered argument is expected to be an ActionType")
	if _actions.has(type):
		var action = _actions[type] as Action
		print("action triggered for type: ", type, " on time: ", action.activation_time)

		if type == ActionType.DASH:
			player.dash_start = action.activation_time


func _on_action_released(type : int):
	assert(type in ActionType.values(), "_on_action_released argument is expected to be an ActionType")
	if _actions.has(type):
		var action = _actions[type] as Action
		#print("action released for type: ", type)

		if type == ActionType.DASH:
			player.dash_start = 0

func handle_input() -> void:

	for input in _map_input:
		if _actions.has(_map_input[input]):
			var action = _actions[_map_input[input]] as Action
			if Input.is_action_pressed(input):
				var activate = action.activation_max < 1 or action.activation_time < 1 or (action.activation_time + action.activation_max) > OS.get_ticks_msec()
				#print("activation for ", input, " with max: ", action.activation_max, " act_time: ", action.activation_time, " for OS.ticks: ", OS.get_ticks_msec(), " -> triggered: ", activate)
				action.set_active(activate)
			elif action.activation_time > 0:
				#print("activation for ", input, " with max: ", action.activation_max, " act_time: ", action.activation_time, " for OS.ticks: ", OS.get_ticks_msec(), " -> triggered: False")
				action.set_active(false)
