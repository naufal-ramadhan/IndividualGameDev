extends BaseEnemy
class_name PatrollingEnemy

# Buka akses ke Inspector agar bisa di-tweak untuk beda-beda musuh
@export var can_patrol: bool = false
@export var patrol_speed: float = 50.0
@export var chase_speed: float = 110.0

var patrol_direction = 1
var patrol_timer = 0.0
var is_patrol_resting = false

# Fungsi ini akan dipanggil oleh anak-anaknya saat AI aktif
func do_patrol(delta):
	patrol_timer -= delta
	if patrol_timer <= 0:
		is_patrol_resting = !is_patrol_resting
		if is_patrol_resting:
			patrol_timer = randf_range(2.0, 4.0)
		else:
			patrol_timer = randf_range(3.0, 6.0)
			if randf() > 0.5:
				patrol_direction *= -1

	if is_patrol_resting:
		velocity.x = move_toward(velocity.x, 0, patrol_speed)
	else:
		velocity.x = patrol_direction * patrol_speed
		flip_character(patrol_direction) # Memanggil fungsi anak

# Fungsi template/virtual agar tidak error saat dipanggil oleh do_patrol.
# Ini akan ditimpa (override) oleh anak-anaknya yang punya gambar berbeda.
func flip_character(direction):
	pass
