extends CharacterBase
class_name Ghost

onready var _collision_shape: CollisionShape = get_node("CollisionShape")
# TODO: split and move to client only
onready var _minimap := load("res://Resources/Icons/icon_ghost_minimap.png")
onready var _minimap_dead := load("res://Resources/Icons/icon_dead_ghost_minimap.png")

var record := {}

var _start_time := -1
var _previous_frame_time =-1
var _replaying = false
var _current_frame = -1
var _dashing = false

var action_manager

signal ghost_attack

func init(gameplay_record: Dictionary, ghost_color: Color):
	record = gameplay_record.duplicate(true)
	self.ghost_index = gameplay_record["G"]
	if has_node("Mesh_Body"):
		if $Mesh_Body and $Mesh_Body.material_override:
			$Mesh_Body.material_override.set_shader_param("color", ghost_color)
	else:
		Logger.warn("Ghost Mesh_Body not accessible (node not in scene tree)", "ghost")

func stop_replay():
	_replaying = false

func start_replay(start_time):
	_start_time = start_time
	_replaying = true
	_current_frame = 0
	_previous_frame_time = record["T"]
	_collision_shape.disabled = false
	rotation = Vector3.ZERO

	# TODO: split and move to client only
	if has_node("MiniMapIcon"):
		$MiniMapIcon.set_texture(_minimap)

func _physics_process(delta):
	if not _replaying:
		return

	if _current_frame >= record["F"].size():
		return

	var time_diff = _start_time - record["T"]
	while _current_frame<record["F"].size() and record["F"][_current_frame]["T"]+time_diff<=Server.get_server_time() :
		_apply_frame(record["F"][_current_frame])
		_current_frame+=1


func move_to_spawn_position():
	transform.origin = spawn_point
	rotation.y = 0


func _apply_frame(frame: Dictionary):
	var delta = frame["T"] - _previous_frame_time
	_previous_frame_time = frame["T"]
	self.velocity = (frame["P"] - transform.origin)/delta
	transform.origin = frame["P"]
	rotation.y = frame["R"]

	if frame["D"] == action_manager.Trigger.SPECIAL_MOVEMENT_START:
		_dashing = true
		set_action_status(action_manager.ActionType.DASH, true)
	if frame["D"] == action_manager.Trigger.SPECIAL_MOVEMENT_END:
		_dashing = false
		set_action_status(action_manager.ActionType.DASH, false)
	
	if frame["A"] != action_manager.Trigger.NONE:
		if frame["A"] == action_manager.Trigger.DEFAULT_ATTACK_START:
			emit_signal("ghost_attack", self, action_manager.Trigger.DEFAULT_ATTACK_START)
			set_action_status(action_manager.ActionType.MELEE, true)
		elif frame["A"] == action_manager.Trigger.FIRE_START:
			emit_signal("ghost_attack", self, action_manager.Trigger.FIRE_START)
			var action_type = action_manager.get_action_type_for_trigger(action_manager.Trigger.FIRE_START, ghost_index)
			set_action_status(action_type, true)


func receive_hit():
	if not is_inside_tree():
		return

	Logger.info("Ghost was hit!", "attacking")
	emit_signal("hit")
	_replaying = false
	# Disable collsions
	_collision_shape.disabled = true
	# Show ghost as dead
	if has_node("Mesh_Body") and $Mesh_Body:
		$Mesh_Body.rotate_z(90)

	# TODO: split and move to client
	if has_node("MiniMapIcon"):
		$MiniMapIcon.set_texture(_minimap_dead)
