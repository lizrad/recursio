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


func get_action(action_type):
	var instance = action_resources[action_type].duplicate()
	instance.ammunition = instance.max_ammo
	
	return instance


func get_action_type_for_trigger(trigger, ghost_index):
	if trigger == Trigger.FIRE_START:
		if ghost_index == Constants.get_value("ghosts", "wall_placing_ghost_index"):
			return ActionType.WALL
		else:
			return ActionType.HITSCAN
	elif trigger == Trigger.SPECIAL_MOVEMENT_START:
		return ActionType.DASH
	elif trigger == Trigger.DEFAULT_ATTACK_START:
		return ActionType.MELEE


func get_action_for_trigger(trigger, ghost_index):
	return get_action(get_action_type_for_trigger(trigger, ghost_index))


func clear_action_instances():
	for instance in _instanced_actions:
		if instance.get_ref():
			instance.get_ref().queue_free()


func set_active(action: Action, value: bool, user: Spatial, action_scene_parent: Node) -> void:
	Logger.debug("Action " + action.name + " set active for value: " + str(value), "actions")

	if not value:
		action.activation_time = 0
		action.emit_signal("action_released")
		return

	if action.blocked:
		return

	if action.ammunition < 0:
		# This action does not use ammo
		pass
	elif action.ammunition > 0:
		Logger.info("Activate Action with remaining ammo: " + str(action.ammunition), "actions")
	else:
		# No ammo left
		return

	# block spaming
	action.blocked = true

	if action.sound:
		# TODO: play attached action sound...
		pass

	action.activation_time = OS.get_ticks_msec()
	
	# fire actual action -> TODO: maybe as class hierarchy?
	if action.attack:
		Logger.info("instancing new attack named "+ action.name, "actions")
		var spawn = action.attack.instance()
		spawn.initialize(user)
		spawn.global_transform = user.global_transform
		action_scene_parent.add_child(spawn)
		_instanced_actions.append(weakref(spawn))

		# TODO: if has recoil configured -> apply on player

	action.emit_signal("action_triggered")

	if action.ammunition > 0:
		action.ammunition -= 1
		action.emit_signal("ammunition_changed", action.ammunition)

	# re-enable
	if action.cooldown > 0:
		yield(get_tree().create_timer(action.cooldown), "timeout")
		action.blocked = false

	# refill ammu
	if action.recharge_time > 0 and action.ammunition < action.max_ammo:
		yield(get_tree().create_timer(action.recharge_time), "timeout")
		action.ammunition += 1
		action.emit_signal("ammunition_changed", action.ammunition)

