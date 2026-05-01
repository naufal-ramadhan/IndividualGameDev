extends BaseItem

func apply_effect(player: Node2D):
	# Contoh: Mengubah variabel status di Player jadi mode dewa selama 10 detik
	player.activate_nuke() 
	print("Insta-Kill Aktif!")
