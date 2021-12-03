extends OmniLight


export var max_radius := 50.0
export var radius_diff := 7.0
export var radius_grow_speed := 50.0

var enabled = false

var _audio_played_this_pulse = false


func _physics_process(delta):
	if enabled:
		omni_range += radius_grow_speed * delta
		$Subtractive.omni_range = omni_range - radius_diff
		visible = true
		
		if omni_range > 10.0 and not _audio_played_this_pulse:
			var audio_player = AudioStreamPlayer.new()
			audio_player.stream = preload("res://Resources/Audio/Effects/Pulse.ogg")
			add_child(audio_player)
			audio_player.connect("finished", audio_player, "queue_free")
			audio_player.play()
			_audio_played_this_pulse = true
		
		if omni_range > max_radius:
			omni_range = 0
			$Subtractive.omni_range = 0
			_audio_played_this_pulse = false
	else:
		omni_range = 0
		$Subtractive.omni_range = 0
		visible = false
		_audio_played_this_pulse = false
