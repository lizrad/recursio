extends Node
class_name ActionManager

enum Trigger {
	NONE = 						 0,
	FIRE_START = 				 2,
	FIRE_END = 					-1,
	SPECIAL_MOVEMENT_START =	 4,
	SPECIAL_MOVEMENT_END = 		-2,
	DEFAULT_ATTACK_START = 		 8,
	DEFAULT_ATTACK_END = 		-3
}

enum ActionType {
	HITSCAN,
	WALL,
	DASH,
	MELEE
}

# Preconfigured Actions
# Action(ammo, cd, recharge, activation_max, action_scene)
var action_resources = {
	ActionType.HITSCAN: preload("res://Shared/Actions/HitscanShot.tres"),
	ActionType.WALL: preload("res://Shared/Actions/Wall.tres"),
	ActionType.DASH: preload("res://Shared/Actions/Dash.tres"),
	ActionType.MELEE: preload("res://Shared/Actions/Melee.tres")
}

var _instanced_actions = []
var _actions = []


func _process(_delta):
	for action in _actions:
		if action.blocked && action.activation_time + action.cooldown * 1000 <= OS.get_system_time_msecs():
			action.blocked = false

		# Recharge is disabled
		if action.recharge_time >= 0 && action.trigger_times.size() > 0:
			var trigger_time = action.trigger_times[0]
			# Check if recharge time is over
			if trigger_time + action.recharge_time * 1000 <= OS.get_system_time_msecs()\
			and action.ammunition < action.max_ammo:
				action.ammunition += 1
				action.emit_signal("ammunition_changed", action.ammunition)
				action.trigger_times.remove(0)


func get_action_type_for_trigger(trigger, timeline_index):
	if trigger == Trigger.FIRE_START:
		if timeline_index == Constants.get_value("ghosts", "wall_placing_timeline_index"):
			return ActionType.WALL
		else:
			return ActionType.HITSCAN
	elif trigger == Trigger.SPECIAL_MOVEMENT_START:
		return ActionType.DASH
	elif trigger == Trigger.DEFAULT_ATTACK_START:
		return ActionType.MELEE


func get_max_ammo_for_trigger(trigger, timeline_index):
	return get_action_for_trigger(trigger, timeline_index).max_ammo

func get_img_bullet_for_trigger(trigger, timeline_index):
	return get_action_for_trigger(trigger, timeline_index).img_bullet

func get_action_for_trigger(trigger, timeline_index) -> Action:
	return get_action(get_action_type_for_trigger(trigger, timeline_index))
	
func get_action(action_type) -> Action:
	return action_resources[action_type]
	
func create_action_duplicate_for_trigger(trigger, timeline_index) -> Action:
	return create_action_duplicate(get_action_type_for_trigger(trigger, timeline_index))

func create_action_duplicate(action_type) -> Action:
	var instance = action_resources[action_type].duplicate() as Action
	instance.ammunition = instance.max_ammo
	return instance


func clear_action_instances():
	for instance in _instanced_actions:
		if instance.get_ref():
			instance.get_ref().queue_free()

	_instanced_actions.clear()
	for action in _actions:
		action.ammunition = action.max_ammo
		action.blocked = false
		action.trigger_times = []


func set_active(action: Action, character: CharacterBase, tree_position: Spatial, action_scene_parent: Node) -> bool:
	Logger.debug("Action " + action.name + " set active", "actions")

	if action.blocked:
		return false

	# No ammo left
	if action.ammunition == 0:
		return false

	# Fire actual action
	if action.attack:
		Logger.info("instancing new attack named " + action.name, "actions")
		var spawn = action.attack.instance()
		action_scene_parent.add_child(spawn)

		spawn.global_transform = tree_position.global_transform
		spawn.initialize(character)
		_instanced_actions.append(weakref(spawn))
		# TODO: if has recoil configured -> apply on player

	action.emit_signal("action_triggered")
	
	# Block spaming
	action.blocked = true
	action.activation_time = OS.get_system_time_msecs()
	
	if action.recharge_time >= 0:
		action.trigger_times.append(action.activation_time)

	if action.ammunition > 0:
		action.ammunition -= 1
		action.emit_signal("ammunition_changed", action.ammunition)

	if not _actions.has(action):
		_actions.append(action)

	return true
