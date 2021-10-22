extends CharacterBase
class_name Ghost

onready var _collision_shape: CollisionShape = get_node("CollisionShape")

var record := {}

var _start_time := -1
var _replaying = false
var _current_frame = -1
var _dashing = false

var action_manager

signal ghost_attack

func init(gameplay_record: Dictionary, ghost_color: Color):
	record = gameplay_record.duplicate(true)
	ghost_index = gameplay_record["G"]
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

	_collision_shape.disabled = false
	rotation = Vector3.ZERO

	if has_node("Sprite3D"):
		$Sprite3D.visible = true
	if has_node("Sprite3DDead"):
		$Sprite3DDead.visible = false

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
	Logger.debug("Moving ghost to "+str(frame["P"]), "ghost")
	transform.origin = frame["P"]
	rotation.y = frame["R"]

	if frame["D"] == action_manager.Trigger.SPECIAL_MOVEMENT_START:
		_dashing = true
	if frame["D"] == action_manager.Trigger.SPECIAL_MOVEMENT_END:
		_dashing = false
	
	if frame["A"] != action_manager.Trigger.NONE:
		if frame["A"] == action_manager.Trigger.DEFAULT_ATTACK_START:
			emit_signal("ghost_attack", self, action_manager.Trigger.DEFAULT_ATTACK_START)
		elif frame["A"] == action_manager.Trigger.FIRE_START:
			emit_signal("ghost_attack", self, action_manager.Trigger.FIRE_START)


func receive_hit():
	if not is_inside_tree():
		return

	Logger.info("Ghost was hit!", "attacking")
	emit_signal("hit")
	_replaying = false
	# Disable collsions
	_collision_shape.disabled = true
	# Show ghost as dead
	if has_node("Sprite3D"):
		$Sprite3D.visible = false
	if has_node("Sprite3DDead"):
		$Sprite3DDead.visible = true
	rotate_z(90)
