extends Control

func _on_play_pressed():
	# Ganti "res://main_level.tscn" dengan nama scene utama game kamu!
	get_tree().change_scene_to_file("res://levels/Level1.tscn")

func _on_quit_pressed():
	get_tree().quit()
