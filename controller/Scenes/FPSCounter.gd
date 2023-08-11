extends ColorRect


func _process(delta):
	$"FPS Counter".text = str(Engine.get_frames_per_second())
