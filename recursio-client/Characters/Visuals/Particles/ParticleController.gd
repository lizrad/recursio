extends Particles

export var time_until_cleanup = 1.0

export var _time_existing = 0.0

func start():
	restart()
	_time_existing = 0.0

func stop():
	emitting = false

func _process(delta):
	_time_existing += delta
	if time_until_cleanup >=0 and _time_existing >= time_until_cleanup:
		get_parent().remove_child(self)
