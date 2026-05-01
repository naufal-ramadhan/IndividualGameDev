extends BaseItem

# Kita TIMPA (Override) fungsi kosong dari induknya
func apply_effect(player: Node2D):
	player.reserve_ammo += 70
	print("Max Ammo diambil! (+70 Peluru)")
