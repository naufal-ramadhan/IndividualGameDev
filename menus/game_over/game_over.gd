extends ColorRect

func _on_restart_pressed():
	$ClickSFX.play()
	await get_tree().create_timer(0.1).timeout
	
	get_tree().paused = false # Baru cairkan dunia
	get_tree().reload_current_scene()

func _on_main_menu_pressed():
	$ClickSFX.play()
	await get_tree().create_timer(0.1).timeout
	
	get_tree().paused = false # Baru cairkan dunia
	get_tree().change_scene_to_file("res://menus/main_menu/main_menu.tscn")
