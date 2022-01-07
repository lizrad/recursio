extends Node


export var round_manager_path: NodePath
onready var round_manager: RoundManager = get_node(round_manager_path)

var is_in_game = false

const END_MUSIC_START = 11076
const FADE_TWEEN_LENGTH = 3.0


func _ready():
	var error = round_manager.connect("game_phase_started", self, "set_early_music")
	assert(error == OK)
	
	error = round_manager.connect("game_phase_stopped", self, "set_base_music_only")
	assert(error == OK)
	
	set_base_music_only()
	
	# Start all tracks at the same time, keeping them in sync from now on
	$BaseMusic.play()
	$EarlyGame.play()
	$EndGame.play()


func _process(_delta):
	# If we've progressed far enough this round, switch to the endgame music
	if Server.get_server_time() >= round_manager.get_deadline() - END_MUSIC_START \
			and is_in_game and not $Tween.is_active():
		set_end_music()


func set_base_music_only():
	interpolate_music_to(0.01, 0.01)
	is_in_game = false


func set_early_music():
	interpolate_music_to(1.0, 0.01)
	is_in_game = true


func set_end_music():
	interpolate_music_to(0.01, 1.0)
	is_in_game = true


func interpolate_music_to(early_value, end_value):
	# The somewhat complicated scaling with EXPO and varied easing is required to adapt to the
	# logarithmic scale of DB
	$Tween.remove_all()
	$Tween.interpolate_property($EarlyGame, "volume_db",
		null, linear2db(early_value), FADE_TWEEN_LENGTH,
		Tween.TRANS_EXPO, Tween.EASE_OUT if early_value == 1.0 else Tween.EASE_IN)
	$Tween.interpolate_property($EndGame, "volume_db",
		null, linear2db(end_value), FADE_TWEEN_LENGTH,
		Tween.TRANS_EXPO, Tween.EASE_OUT if end_value == 1.0 else Tween.EASE_IN)
	$Tween.start()
