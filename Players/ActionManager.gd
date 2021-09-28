extends Node

enum ActionType { SHOOT, DASH, MELEE }

var _actions = {}
var _map_input = { 
					"player_shoot": ActionType.SHOOT,
					"player_melee": ActionType.MELEE, 
					"player_dash": ActionType.DASH,
				 }

func _ready():
	# TEST: ActionType(ammo, cd, recharge):
	_actions[ActionType.SHOOT] = Action.new(10, 0.2, -1)
	_actions[ActionType.DASH] = Action.new(2, 1, 5)
	_actions[ActionType.MELEE] = Action.new(-1, 0.2, -1)

	# need to add actions to scene tree to be able to install a timer
	for key in _actions:
		_actions[key].connect("ammunition_changed", self, "_on_ammu_changed")
		add_child(_actions[key])


# TODO: forward signal with action type
func _on_ammu_changed(ammo : int):
	print("ammunition changed to ", ammo)


func handle_input() -> void:

	for input in _map_input:
		if Input.is_action_pressed(input):
			if _actions.has(_map_input[input]):
				_actions[_map_input[input]].activate()
