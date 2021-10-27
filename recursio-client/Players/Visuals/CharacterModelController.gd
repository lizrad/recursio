extends Node

onready var animator = get_node("Animator")

func on_action_status_changed(action_type, status):
	animator.action_status_changed(action_type, status)

func on_velocity_changed(velocity, front_vector, right_vector):
	animator.velocity_changed(velocity, front_vector, right_vector)
