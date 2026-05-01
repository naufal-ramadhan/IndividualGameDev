extends BaseItem

# Kita TIMPA fungsi kosong dari induknya dengan efek darah
func apply_effect(player: Node2D):
	player.current_health += 50
	player.current_health = clamp(player.current_health, 0, player.MAX_HEALTH)
	print("Kevlar diambil! (Health Penuh)")
