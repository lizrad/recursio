extends Spatial

onready var _swap_icon = get_node("Viewport/Swap")
onready var _ready_icon = get_node("Viewport/Ready")

func _ready() -> void:
	var _error = InputManager.connect("controller_changed", self, "_on_controller_changed")
	_on_controller_changed(InputManager.get_current_controller())


func _on_controller_changed(controller) -> void:
	$Viewport/Swap.texture = load("res://Resources/Icons/" + controller + "/swap.png")
	$Viewport/Ready.texture = load("res://Resources/Icons/" + controller + "/accept.png")


func set_active(val: bool) -> void:
	set_process(val)
	visible = val

func show_swap_overlay():
	_swap_icon.show()
	
func show_ready_overlay():
	_ready_icon.show()

func hide_swap_overlay():
	_swap_icon.hide()
	
func hide_ready_overlay():
	_ready_icon.hide()
