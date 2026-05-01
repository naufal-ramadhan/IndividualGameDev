extends ColorRect

func _on_restart_pressed():
	# Mengulang level dari awal
	get_tree().reload_current_scene()

func _on_main_menu_pressed():
	# Kembali ke Main Menu
	get_tree().change_scene_to_file("res://menus/main_menu/main_menu.tscn")
