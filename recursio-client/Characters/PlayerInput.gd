extends Node

export(float) var inner_deadzone := 0.1
export(float) var outer_deadzone := 0.9
export(float) var rotate_threshold := 0.0

onready var _player: Player = get_parent()
onready var _action_manager = _player.get_action_manager()


var _trigger_dic : Dictionary = {
	"player_shoot": ActionManager.Trigger.FIRE_START,
	"player_melee": ActionManager.Trigger.DEFAULT_ATTACK_START,
	"player_dash": ActionManager.Trigger.SPECIAL_MOVEMENT_START
}

var _fire_action = ActionManager.get_action(ActionManager.ActionType.HITSCAN)
var _default_attack_action = ActionManager.get_action(ActionManager.ActionType.MELEE)
var _special_movement_action = ActionManager.get_action(ActionManager.ActionType.DASH)

func _ready():
	# Subscribe to Action Events
	_connect_to_action_signals(_fire_action, ActionManager.Trigger.FIRE_START)
	_connect_to_action_signals(_default_attack_action, ActionManager.Trigger.DEFAULT_ATTACK_START)
	_connect_to_action_signals(_special_movement_action, ActionManager.Trigger.SPECIAL_MOVEMENT_START)



func _physics_process(delta):
	var input = DeadZones.apply_2D(_get_input("player_move"), inner_deadzone, outer_deadzone)
	var movement_vector = Vector3(input.y, 0.0, -input.x)
	InputManager.add_movement_to_input_frame(input)
	
	var rotate_input = DeadZones.apply_2D(_get_input("player_look"), 1.0, 0.0)
	var rotate_vector = Vector3(rotate_input.y, 0.0, -rotate_input.x)
	InputManager.add_rotation_to_input_frame(rotate_input)
	
	_player.apply_input(movement_vector, rotate_vector, _get_buttons_pressed())


func swap_weapon_type(timeline_index) -> void:
	_disconnect_from_action_signals(_fire_action)
	_fire_action = ActionManager.get_action_for_trigger(ActionManager.Trigger.FIRE_START, timeline_index)
	
	# Re-subscribe to signals
	_connect_to_action_signals(_fire_action, ActionManager.Trigger.FIRE_START)
	Logger.info("Weapon selected: " + _fire_action.name, "actions")
	
	_update_player_hud()


func _update_player_hud():
	pass


# Reads the input of the given type e.g. "player_move" or "player_look"
func _get_input(type) -> Vector2:
	return Vector2(
		Input.get_action_strength(type + "_up") - Input.get_action_strength(type + "_down"),
		Input.get_action_strength(type + "_right") - Input.get_action_strength(type + "_left")
	)


# Returns a binary representation of all buttons pressed
func _get_buttons_pressed() -> int:
	var buttons : Bitmask = Bitmask.new(0)
	for trigger in _trigger_dic:
		var action = _trigger_dic[trigger]
		
		if Input.is_action_pressed(trigger):
			buttons.add(action)
		
	return buttons.mask


func _connect_to_action_signals(action, type):
	action.connect("ammunition_changed", self, "_on_ammo_changed", [action, type])
	action.connect("action_triggered", self, "_on_action_triggered", [action, type])
	action.connect("action_released", self, "_on_action_released", [action, type])

func _disconnect_from_action_signals(action):
	action.disconnect("ammunition_changed", self, "_on_ammo_changed")
	action.disconnect("action_triggered", self, "_on_action_triggered")
	action.disconnect("action_released", self, "_on_action_released")


func _on_ammo_changed(ammo: int, action: Action, type: int) -> void:
	Logger.debug("Ammunition for type: " + str(type) + " changed to: " + str(ammo), "actions")
	_update_player_hud()


func _on_action_triggered(action: Action, type: int) -> void:
	Logger.debug("Action triggered for name: " + str(action.name) + " on time: " + str(action.activation_time), "actions")
	InputManager.add_trigger_to_input_frame(type)


func _on_action_released(action: Action, type: int) -> void:
	Logger.debug("Action released for type: " + str(type), "actions")
	InputManager.remove_trigger_from_input_frame(type)

