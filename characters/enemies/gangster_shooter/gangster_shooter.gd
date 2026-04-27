extends PatrollingEnemy

# ==========================================
# PENGATURAN SENJATA (Diatur via Inspector Editor)
# ==========================================
@export_category("Weapon Settings")
@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.2     # Jeda antar peluru
@export var damage_mult: float = 1.0
@export var burst_count: int = 3       # Jumlah peluru per tembakan
@export var reload_delay: float = 2.0  # Waktu jeda (cooldown) setelah nembak
@export var windup_time: float = 0.0

# SAKELAR AJAIB: 
# ON (Centang) = Animasi nembak diulang per peluru (Cocok untuk Pistol/Shotgun)
# OFF (Kosong) = Animasi main sekali dan ditahan (Cocok untuk SMG/Assault Rifle)
@export var animate_per_shot: bool = false 

# ==========================================
# VARIABEL STATUS KHUSUS SHOOTER
# ==========================================
# (hp, is_dead, is_hurt, patrol_speed, chase_speed sudah diwarisi dari PatrollingEnemy)
var is_shooting = false
var can_shoot = true
var player_in_shoot_range = false

# ==========================================
# REFERENSI NODE
# ==========================================
@onready var anim = $CharacterVisualAnimated 
@onready var detector = $PlayerDetector
@onready var shoot_range = $ShootRange 
@onready var muzzle = $Muzzle # Node Marker2D untuk tempat keluar peluru

# ==========================================
# INISIALISASI
# ==========================================
func _ready():
	detector.body_entered.connect(_on_player_entered)
	shoot_range.body_entered.connect(_on_shoot_range_entered)
	shoot_range.body_exited.connect(_on_shoot_range_exited)

# ==========================================
# MESIN UTAMA (OTAK AI SHOOTER)
# ==========================================
func _physics_process(delta):
	# 1. Kalau mati, stop mikir
	if is_dead:
		velocity.x = 0
		if not is_on_floor(): velocity.y += gravity * delta
		move_and_slide()
		update_animations()
		return

	# 2. Fisika Dasar & Knockback
	velocity.x += knockback_force.x
	knockback_force.x = move_toward(knockback_force.x, 0, 800 * delta)
	if not is_on_floor(): velocity.y += gravity * delta

	# 3. Kalau kena hit, cancel semua gerakan (termasuk nembak)
	if is_hurt:
		move_and_slide() 
		update_animations() 
		return 

	# 4. Logika AI
	if is_shooting:
		velocity.x = 0 # Harus berhenti jalan kalau lagi nembak
		
	elif is_chasing and player_target != null:
		var direction = sign(player_target.global_position.x - global_position.x)
		flip_character(direction)
		
		if player_in_shoot_range:
			velocity.x = 0 # Berhenti lari kalau Player sudah masuk jarak tembak
			if can_shoot:
				shoot_burst(direction)
		else:
			velocity.x = direction * chase_speed # Kejar kalau masih di luar jangkauan
			
	else:
		# Panggil fungsi patroli warisan dari bapaknya (PatrollingEnemy)
		if can_patrol:
			do_patrol(delta)
		else:
			velocity.x = move_toward(velocity.x, 0, chase_speed) 

	# 5. Eksekusi
	move_and_slide()
	update_animations()

# ==========================================
# LOGIKA MENEMBAK (BURST & SAKELAR ANIMASI)
# ==========================================
func shoot_burst(direction):
	is_shooting = true
	can_shoot = false

	# JIKA SMG: Mainkan animasi nahan senjata sekali saja di awal
	if not animate_per_shot:
		anim.play("shoot")

	for i in range(burst_count):
		if is_dead or is_hurt:
			break 
			
		# JIKA PISTOL: Mainkan animasi setiap kali pelatuk ditarik
		if animate_per_shot:
			anim.stop() 
			anim.play("shoot")
		
		# --- FASE 1: WIND-UP (SIAP-SIAP NEMBAK) ---
		# Hanya berjalan jika windup_time disetel > 0 di Inspector
		if windup_time > 0.0:
			await get_tree().create_timer(windup_time).timeout
			# Cek lagi, kalau pas lagi angkat pistol dia dipukul Player, batal nembak!
			if is_dead or is_hurt:
				break
		
		# --- FASE 2: PELURU KELUAR ---
		if bullet_scene != null:
			var bullet = bullet_scene.instantiate()
			bullet.direction = direction
			bullet.global_position = muzzle.global_position
			
			# SEKARANG PASTI JALAN: Kalikan damage asli peluru (25) dengan multiplier di Inspector (misal 0.2)
			if "damage" in bullet:
				bullet.damage = bullet.damage * damage_mult
				
			get_tree().root.add_child(bullet)
			
		# --- FASE 3: JEDA / SISA ANIMASI ---
		# Untuk SMG: Ini jeda berondongan. Untuk Pistol: Ini sisa waktu buat nurunin senjata.
		await get_tree().create_timer(fire_rate).timeout
	
	is_shooting = false
	
	await get_tree().create_timer(reload_delay).timeout
	can_shoot = true
# ==========================================
# MANAJEMEN ANIMASI (VISUAL)
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

# Override dari PatrollingEnemy: Shooter harus membalikkan Muzzle-nya juga
func flip_character(direction):
	if direction > 0: 
		anim.flip_h = false
		muzzle.position.x = abs(muzzle.position.x)
		shoot_range.position.x = 34
	elif direction < 0: 
		anim.flip_h = true
		muzzle.position.x = -abs(muzzle.position.x)
		shoot_range.position.x = -223

# ==========================================
# OVERRIDE & SINYAL SENSOR
# ==========================================
func die():
	# Jalankan logika hantu dari BaseEnemy
	super.die()
	
	# Matikan sensor khusus Shooter
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
