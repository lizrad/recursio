extends Node

export(float) var inner_deadzone := 0.1
export(float) var outer_deadzone := 0.9
export(float) var rotate_threshold := 0.0

onready var _player: Player = get_parent()
onready var _action_manager = _player.get_action_manager()

# Maps the actual button to the internal enums
var _trigger_dic : Dictionary = {
	"player_shoot": ActionManager.Trigger.FIRE_START,
	"player_melee": ActionManager.Trigger.DEFAULT_ATTACK_START,
	"player_dash": ActionManager.Trigger.SPECIAL_MOVEMENT_START
}

var _player_ghost_pick_trigger : String = "player_switch"

# Action for pressing fire
var _fire_action = _action_manager.get_action(ActionManager.ActionType.HITSCAN)
# Action for melee
var _default_attack_action = _action_manager.get_action(ActionManager.ActionType.MELEE)
# Action for dash
var _special_movement_action = _action_manager.get_action(ActionManager.ActionType.DASH)


func _ready():
	# Subscribe to Action Events
	_fire_action.connect("ammunition_changed", self, "_on_fire_ammo_changed")
	_special_movement_action.connect("ammunition_changed", self, "_on_special_movement_ammo_changed")



func _physics_process(delta):
	var input = DeadZones.apply_2D(_get_input("player_move"), inner_deadzone, outer_deadzone)
	var movement_vector = Vector3(input.y, 0.0, -input.x)
	InputManager.add_movement_to_input_frame(input)
	
	var rotate_input = DeadZones.apply_2D(_get_input("player_look"), 1.0, 0.0)
	var rotate_vector = Vector3(rotate_input.y, 0.0, -rotate_input.x)
	InputManager.add_rotation_to_input_frame(rotate_input)
	
	var buttons_pressed: int = _get_buttons_pressed()
	_player.apply_input(movement_vector, rotate_vector, buttons_pressed)
	InputManager.set_triggers_in_input_frame(buttons_pressed)
	
	if Input.is_action_pressed(_player_ghost_pick_trigger):
		var timeline_index: int = (_player.timeline_index + 1) % (Constants.get_value("ghosts","max_amount") + 1)
		_player.timeline_index = timeline_index
		_swap_weapon_type(timeline_index)
		
		InputManager.pick_player_timeline(timeline_index)


# Changes the weapon depending on the given timeline index
func _swap_weapon_type(timeline_index) -> void:
	_fire_action.disconnect("ammunition_changed", self, "_on_fire_ammo_changed")
	_fire_action = _action_manager.get_action_for_trigger(ActionManager.Trigger.FIRE_START, timeline_index)
	
	# Re-subscribe to signals
	_fire_action.connect("ammunition_changed", self, "_on_fire_ammo_changed")
	Logger.info("Weapon selected: " + _fire_action.name, "actions")
	
	_player.update_weapon_type_hud(_fire_action)



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


func _on_fire_ammo_changed(ammo: int) -> void:
	Logger.debug("Fire ammunition changed to: " + str(ammo))
	_player.update_fire_action_ammo_hud(ammo)

func _on_special_movement_ammo_changed(ammo: int) -> void:
	Logger.debug("Special movement ammunition changed to: " + str(ammo))
	_player.update_special_movement_ammo_hud(ammo)


