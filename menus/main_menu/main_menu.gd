extends Control

func _on_play_pressed():
	$ClickSFX.play()
	await get_tree().create_timer(0.05).timeout
	get_tree().change_scene_to_file("res://levels/Level1.tscn")

func _on_quit_pressed():
	$ClickSFX.play()
	await get_tree().create_timer(0.05).timeout
	get_tree().quit()
