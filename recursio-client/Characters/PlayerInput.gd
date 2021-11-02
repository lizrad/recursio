extends Node

export(float) var inner_deadzone := 0.1
export(float) var outer_deadzone := 0.9
export(float) var rotate_threshold := 0.0

onready var _player: Player = get_parent().get_parent()


# Maps the actual button to the internal enums
var _trigger_dic : Dictionary = {
	"player_shoot": ActionManager.Trigger.FIRE_START,
	"player_melee": ActionManager.Trigger.DEFAULT_ATTACK_START,
	"player_dash": ActionManager.Trigger.SPECIAL_MOVEMENT_START
}

var _action_manager

var _player_timeline_pick_trigger : String = "player_switch"

# Action for pressing fire
var _fire_action
# Action for melee
var _default_attack_action
# Action for dash
var _special_movement_action

var _player_initialized: bool = false

func _ready():
	_player.connect("initialized", self, "_on_player_initialized")
	_player.connect("timeline_index_changed", self, "_on_timeline_changed")


func _physics_process(delta):
	if not _player_initialized:
		return
	
	var input = DeadZones.apply_2D(_get_input("player_move"), inner_deadzone, outer_deadzone)
	var movement_vector = Vector3(input.y, 0.0, -input.x)
	InputManager.add_movement_to_input_frame(movement_vector)
	
	var rotate_input = DeadZones.apply_2D(_get_input("player_look"), inner_deadzone, outer_deadzone)
	var rotate_vector = Vector3(rotate_input.y, 0.0, -rotate_input.x)
	InputManager.add_rotation_to_input_frame(rotate_vector)
	
	var buttons_pressed: int = _get_buttons_pressed()
	_player.apply_input(movement_vector, rotate_vector, buttons_pressed)
	InputManager.set_triggers_in_input_frame(buttons_pressed)
	

	if Input.is_action_just_pressed(_player_timeline_pick_trigger):
		if _player.get_round_manager().get_current_phase() == RoundManager.Phases.PREPARATION:
			var timeline_index: int = (_player.timeline_index + 1) % (Constants.get_value("ghosts","max_amount") + 1)
			_player.timeline_index = timeline_index


func _on_player_initialized():
	_action_manager = _player.get_action_manager()
	_fire_action = _action_manager.get_action(ActionManager.ActionType.HITSCAN)
	_default_attack_action = _action_manager.get_action(ActionManager.ActionType.MELEE)
	_special_movement_action = _action_manager.get_action(ActionManager.ActionType.DASH)
	
	# Subscribe to Action Events
	_fire_action.connect("ammunition_changed", self, "_on_fire_ammo_changed")
	_special_movement_action.connect("ammunition_changed", self, "_on_special_movement_ammo_changed")
	
	_player_initialized = true


func _on_timeline_changed(timeline_index) -> void:
	_swap_weapon_type(timeline_index)



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
		
		if Input.is_action_just_pressed(trigger):
			buttons.add(action)
		
	return buttons.mask


func _on_fire_ammo_changed(ammo: int) -> void:
	Logger.debug("Fire ammunition changed to: " + str(ammo))
	_player.update_fire_action_ammo_hud(ammo)

func _on_special_movement_ammo_changed(ammo: int) -> void:
	Logger.debug("Special movement ammunition changed to: " + str(ammo))
	_player.update_special_movement_ammo_hud(ammo)


