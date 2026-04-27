extends PatrollingEnemy

# ==========================================
# PENGATURAN SENJATA (Flekibel via Editor)
# ==========================================
@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.2     # Jeda antar peluru (Makin kecil = makin cepat)
@export var burst_count: int = 3       # Jumlah peluru sekali tarik pelatuk
@export var reload_delay: float = 2.0  # Jeda "Reload" setelah burst selesai

var is_shooting = false
var can_shoot = true
var player_in_shoot_range = false

@onready var anim = $CharacterVisualAnimated 
@onready var detector = $PlayerDetector
@onready var shoot_range = $ShootRange 
@onready var muzzle = $Muzzle # Titik keluar peluru

func _ready():
	detector.body_entered.connect(_on_player_entered)
	shoot_range.body_entered.connect(_on_shoot_range_entered)
	shoot_range.body_exited.connect(_on_shoot_range_exited)

# ==========================================
# MESIN UTAMA (AI SHOOTER)
# ==========================================
func _physics_process(delta):
	if is_dead:
		velocity.x = 0
		if not is_on_floor(): velocity.y += gravity * delta
		move_and_slide()
		update_animations()
		return

	velocity.x += knockback_force.x
	knockback_force.x = move_toward(knockback_force.x, 0, 800 * delta)
	if not is_on_floor(): velocity.y += gravity * delta

	# Jika kena hit, hentikan pergerakan (TAPI script tembak juga harus dibatalkan)
	if is_hurt:
		move_and_slide() 
		update_animations() 
		return 

	if is_shooting:
		velocity.x = 0 # Berhenti bergerak saat menembak
	elif is_chasing and player_target != null:
		var direction = sign(player_target.global_position.x - global_position.x)
		flip_character(direction)
		
		if player_in_shoot_range:
			velocity.x = 0 # Stop lari kalau sudah masuk jarak tembak
			if can_shoot:
				shoot_burst(direction)
		else:
			# Lari mendekat kalau target di luar jarak tembak
			velocity.x = direction * chase_speed 
	else:
		if can_patrol:
			do_patrol(delta)
		else:
			velocity.x = move_toward(velocity.x, 0, chase_speed) 

	move_and_slide()
	update_animations()

# ==========================================
# LOGIKA MENEMBAK (BURST SYSTEM)
# ==========================================
func shoot_burst(direction):
	is_shooting = true
	can_shoot = false

	# Lakukan perulangan sebanyak jumlah peluru
	for i in range(burst_count):
		# PENTING: Batal nembak kalau di pertengahan burst musuh ini mati atau kena hit Player!
		if is_dead or is_hurt:
			break 
			
		anim.play("shoot")
		
		# Spawn Peluru
		if bullet_scene != null:
			var bullet = bullet_scene.instantiate()
			bullet.direction = direction
			bullet.global_position = muzzle.global_position
			get_tree().root.add_child(bullet)
			
		# Tunggu jeda antar peluru (Fire Rate)
		await get_tree().create_timer(fire_rate).timeout
	
	is_shooting = false
	
	# Fase "Reload" / Cooldown sebelum bisa mulai burst lagi
	await get_tree().create_timer(reload_delay).timeout
	can_shoot = true

# ==========================================
# MANAJEMEN ANIMASI & ARAH
# ==========================================
func update_animations():
	if is_dead:
		if anim.animation != "dead": anim.play("dead")
		return
	if is_hurt:
		if anim.animation != "hurt": anim.play("hurt")
		return
	if is_shooting:
		return 

	if abs(velocity.x) > 5.0: 
		if is_chasing: anim.play("run")
		else: anim.play("walk")
	else:
		play_idle_logic()

func play_idle_logic():
	if anim.animation == "idle2" and anim.is_playing(): return
	if randf() < 0.005: anim.play("idle2")
	else: anim.play("idle1")

func flip_character(direction):
	if direction > 0: 
		anim.flip_h = false
		muzzle.position.x = abs(muzzle.position.x)
	elif direction < 0: 
		anim.flip_h = true
		muzzle.position.x = -abs(muzzle.position.x)

# ==========================================
# OVERRIDE & SENSOR
# ==========================================
func die():
	super.die()
	shoot_range.set_deferred("monitoring", false)
	detector.set_deferred("monitoring", false)

func _on_shoot_range_entered(body):
	if body.name == "Player": player_in_shoot_range = true

func _on_shoot_range_exited(body):
	if body.name == "Player": player_in_shoot_range = false

func _on_player_entered(body):
	if body.name == "Player":
		player_target = body
		is_chasing = true
