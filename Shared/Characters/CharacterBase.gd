extends Node
class_name CharacterBase

signal hit(perpetrator)
signal dying()
signal spawning()

signal non_vfx_spawn()
signal velocity_changed(velocity, front_vector, right_vector)
signal timeline_index_changed(timeline_index)
signal action_status_changed(action_type, status)
signal animation_status_changed(status)

var currently_dying: bool = false setget set_dying
var currently_spawning: bool = false setget set_spawning
var player_id: int
# The team id defines which side the player starts on
var team_id: int = -1
# The timeline this character belongs to
var timeline_index: int = -1 setget set_timeline_index
# The spawn point of this character
var spawn_point: Vector3
# The round this character got created in
var round_index: int = -1
# tracks activation for triggers
var last_triggers: int = 0


var position: Vector3 setget set_position, get_position
var rotation_y: float setget set_rotation_y, get_rotation_y
var velocity: Vector3 setget set_velocity

var _actions = {}


# Underlying kinematic body
onready var kb: KinematicBody = get_node("KinematicBody")
onready var _collision_shape: CollisionShape = get_node("KinematicBody/CollisionShape")

var _action_manager
var _death_timer
var _auto_respawn_on_death = false
var _spawn_timer

var _spawn_imminent = false;
var _spawn_deadline = -1;

func _ready():
	_death_timer = Timer.new()
	_spawn_timer = Timer.new()
	_death_timer.wait_time = Constants.get_value("gameplay", "death_time")
	_spawn_timer.wait_time = Constants.get_value("gameplay", "spawn_time")
	_death_timer.one_shot = true
	_spawn_timer.one_shot = true
	_death_timer.connect("timeout", self, "_on_death_timer_timeout")
	_spawn_timer.connect("timeout", self, "_on_spawn_timer_timeout")
	add_child(_death_timer)
	add_child(_spawn_timer)

func _process(delta):
	if _spawn_imminent:
		_spawn_deadline -= delta
		if _spawn_deadline <= 0:
			_spawn_imminent = false
			emit_signal("spawning")

func character_base_init(action_manager) -> void:
	_action_manager = action_manager

func reset() -> void:
	self.velocity = Vector3.ZERO
	self.position = spawn_point
	self.rotation_y = 0
	self.timeline_index = 0


func move_to_spawn_point() -> void:
	set_position(spawn_point)
	var val = PI/2 + (team_id * PI)
	set_rotation_y(val)


# Returns the position of the underlying kinematic body
func get_position() -> Vector3:
	return kb.transform.origin


# Returns the y-rotation of the underlying kinematic body
func get_rotation_y() -> float:
	return kb.rotation.y;


# Sets the position of the underlying kinematic body
func set_position(new_position: Vector3) -> void:
	kb.transform.origin = new_position


# Sets the y-rotation of the underlying kinematic body
func set_rotation_y(new_rotation_y: float) -> void:
	kb.rotation.y = new_rotation_y


func set_velocity(new_velocity):
	emit_signal("velocity_changed", velocity, -kb.transform.basis.z, kb.transform.basis.x)
	velocity = new_velocity


func set_timeline_index(new_timeline_index: int):
	timeline_index = new_timeline_index
	emit_signal("timeline_index_changed", new_timeline_index)

func hit(perpetrator) -> void:
	emit_signal("hit", perpetrator)
	set_dying(true)


# quiet_hit is used to tell a character it is hit, without it triggering the hit signal
# this is necessary because lots of gameplay functionality listens to hit (eg. recording 
# of the death in the ghostmanager class) we do nott want this during special gameplay 
# moments (for now only when a death is triggered by a previous death recording from the ghostmanager)
func quiet_hit(perpetrator) -> void:
	set_dying(true)

func set_dying(new_dying_status: bool):
	Logger.info("Setting currently_dying to "+str(new_dying_status)+".", "death_and_spawn")
	currently_dying = new_dying_status
	if currently_dying:
		_collision_shape.disabled = true
		_death_timer.start()
		emit_signal("dying")

func _on_death_timer_timeout():
	Logger.info("Death timer timeout.", "death_and_spawn")
	set_dying(false)
	if _auto_respawn_on_death:
		set_spawning(true)

func set_spawning(new_spawning_status: bool):
	Logger.info("Setting currently_spawning to "+str(new_spawning_status)+".", "death_and_spawn")
	currently_spawning = new_spawning_status
	if currently_spawning:
		move_to_spawn_point()
		_spawn_timer.start()
		emit_signal("spawning")

func _on_spawn_timer_timeout():
	Logger.info("Spawn timer timeout.", "death_and_spawn")
	_collision_shape.disabled = false
	set_spawning(false)

func toggle_animation(value):
	emit_signal("animation_status_changed", value)

func trigger_actions(buttons: int) -> void:
	if currently_dying or currently_spawning:
		return

	# Go through buttons and trigger actions for them
	var number_of_bits = log(buttons) / log(2) + 1
	for bit_index in number_of_bits:
		# Triggers are represented as powers of two
		var trigger = int(pow(2, bit_index))
		var bit = buttons & trigger
		if not bit:
			continue

		var action = _get_action(trigger, timeline_index)
		var success = _action_manager.set_active(action, self, kb, get_parent())
		if success:
			var type = _action_manager.get_action_type_for_trigger(trigger, timeline_index)
			emit_signal("action_status_changed", type, true)
			last_triggers |= trigger


func get_action_manager():
	return _action_manager


# Always returns the same Action instance for the same trigger and timeline index. This preserves ammo count etc.
func _get_action(trigger, action_timeline_index):
	var id = action_timeline_index * 10 + trigger
	
	# Cache the action if it hasn't been cached yet
	if not _actions.has(id):
		_actions[id] = _action_manager.create_action_duplicate_for_trigger(trigger, action_timeline_index)

	return _actions[id]

func get_body():
	return kb

func wall_spawned(_wall):
	pass

func visual_delayed_spawn(delay: float):
	_spawn_imminent = true
	_spawn_deadline = delay

func visual_kill():
	emit_signal("dying")


# non_vfx_spawn is used to spawn a character without triggering any animations or particles
# this is necessary because when a character dies, it remains invisible until it spawns again, 
# but there are moments during gameplay where we don't want to see the whole spawn procedure 
# (eg. when dead ghost appear again during the prep phase)
func non_vfx_spawn():
	emit_signal("non_vfx_spawn")

func is_collision_active() -> bool:
	return !_collision_shape.disabled
