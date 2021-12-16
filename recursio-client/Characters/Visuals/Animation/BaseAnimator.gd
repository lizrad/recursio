extends Node
class_name BaseAnimator

signal animation_over

export var _root_pivot_node_path = NodePath("../RootPivot")
export var _front_pivot_node_path = NodePath("../RootPivot/BackPivot")
export var _middle_pivot_node_path = NodePath("../RootPivot/MiddlePivot")
export var _back_pivot_node_path = NodePath("../RootPivot/FrontPivot")
onready var _root_pivot = get_node(_root_pivot_node_path)
onready var _back_pivot = get_node(_front_pivot_node_path)
onready var _middle_pivot = get_node(_middle_pivot_node_path)
onready var _front_pivot = get_node(_back_pivot_node_path)

onready var _pivots = [_root_pivot, _back_pivot, _middle_pivot, _front_pivot]

var _keyframes = {}
var _default_positions = {}
var _default_rotations = {}
var _default_scales = {}

func _ready():
	for pivot in _pivots:
		_default_positions[pivot] = pivot.transform.origin
		_default_rotations[pivot] = pivot.transform.basis.get_euler()
		_default_scales[pivot] = pivot.scale
	_reset_keyframes()


func _reset_keyframes():
	for pivot in _pivots:
		_keyframes[pivot] = Transform(
			Basis(_default_rotations[pivot]),
			_default_positions[pivot]
		)
		_keyframes[pivot].basis = _keyframes[pivot].basis.scaled(_default_scales[pivot])


func _disable_signal_warnings() -> void:
	assert(false) # this only exists so the signals don't throw warnings and should never be called
	emit_signal("animation_over")
