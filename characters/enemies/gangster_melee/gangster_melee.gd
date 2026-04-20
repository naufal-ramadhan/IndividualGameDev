extends CharacterBody2D

# ==========================================
# KONSTANTA & PENGATURAN EDITOR
# ==========================================
const SPEED = 110.0 
const PATROL_SPEED = 50.0 # Kecepatan saat santai/patroli
const MELEE_DAMAGE = 15.0

@export var can_patrol: bool = false # Centang di Inspector jika musuh ini boleh patroli

# ==========================================
# VARIABEL STATUS (STATE)
# ==========================================
var hp = 100.0
var knockback_force = Vector2.ZERO
var player_target = null 

# Gerbang Logika (Gatekeepers)
var is_chasing = false
var is_attacking = false
var is_hurt = false
var is_dead = false
var can_attack = true
var player_in_attack_range = false

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Variabel AI Patroli
var patrol_direction = 1
var patrol_timer = 0.0
var is_patrol_resting = false

# ==========================================
# REFERENSI NODE
# ==========================================
@onready var anim = $CharacterVisualAnimated 
@onready var detector = $PlayerDetector
@onready var attack_range = $AttackRange 

# ==========================================
# FUNGSI INISIALISASI
# ==========================================
func _ready():
	# Hubungkan semua sensor mata dan jarak pukul
	detector.body_entered.connect(_on_player_entered)
	#detector.body_exited.connect(_on_player_exited)
	
	attack_range.body_entered.connect(_on_attack_range_entered)
	attack_range.body_exited.connect(_on_attack_range_exited)

# ==========================================
# FUNGSI MESIN UTAMA (OTAK AI)
# ==========================================
func _physics_process(delta):
	# 1. KASTA TERTINGGI: KEMATIAN
	# Kalau mati, AI berhenti berpikir total. Hanya sisa fisika gravitasi.
	if is_dead:
		velocity.x = 0
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		update_animations()
		return

	# 2. HUKUM ALAM (Fisika & Knockback)
	# Selalu berjalan terlepas musuh sadar atau pingsan
	velocity.x += knockback_force.x
	knockback_force.x = move_toward(knockback_force.x, 0, 800 * delta)
	
	if not is_on_floor():
		velocity.y += gravity * delta

	# 3. KASTA KEDUA: RASA SAKIT (INTERRUPT)
	# AI berhenti memikirkan hal lain saat kesakitan, tapi tetap terdorong secara fisik
	if is_hurt:
		move_and_slide() 
		update_animations() 
		return 

	# 4. KASTA KETIGA: TINDAKAN AI (Mengejar/Patroli)
	if is_attacking:
		velocity.x = 0 # Berhenti melangkah saat memukul
		
	elif is_chasing and player_target != null:
		var direction = sign(player_target.global_position.x - global_position.x)
		flip_character(direction)
		
		# Cek apakah sudah cukup dekat untuk memukul
		if player_in_attack_range:
			velocity.x = 0
			if can_attack: 
				attack(player_target)
		else:
			velocity.x = direction * SPEED # Lari ke arah player
			
	else:
		# Logika saat Player tidak terlihat
		if can_patrol:
			do_patrol(delta)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED) # Diam jaga pintu

	# 5. EKSEKUSI FINAL
	move_and_slide()
	update_animations()


# ==========================================
# PUSAT MANAJEMEN ANIMASI (VISUAL)
# ==========================================
func update_animations():
	# Prioritas 1: Kematian mutlak
	if is_dead:
		if anim.animation != "dead":
			anim.play("dead")
		return

	# Prioritas 2: Terluka (Stagger)
	if is_hurt:
		anim.play("hurt")
		return

	# Prioritas 3: Menyerang 
	# (Kita biarkan return agar animasi acak tidak ditimpa oleh run/walk)
	if is_attacking:
		return 

	# Prioritas 4: Pergerakan Kaki
	if abs(velocity.x) > 5.0: # Jika kecepatan cukup tinggi
		if is_chasing:
			anim.play("run")
		else:
			anim.play("walk")
			
	# Prioritas 5: Diam di tempat (Idle)
	else:
		play_idle_logic()

func play_idle_logic():
	# Jangan potong animasi idle2 (garuk kepala/napas panjang) jika sedang diputar
	if anim.animation == "idle2" and anim.is_playing():
		return
		
	# Peluang 0.5% setiap frame untuk memainkan variasi idle
	if randf() < 0.005:
		anim.play("idle2")
	else:
		anim.play("idle1")

# ==========================================
# FUNGSI BANTUAN (HELPERS)
# ==========================================
func flip_character(direction):
	if direction > 0: # Kanan
		anim.flip_h = false
		attack_range.position.x = 34
	elif direction < 0: # Kiri
		anim.flip_h = true
		attack_range.position.x = -6

func do_patrol(delta):
	patrol_timer -= delta
	
	if patrol_timer <= 0:
		is_patrol_resting = !is_patrol_resting
		if is_patrol_resting:
			patrol_timer = randf_range(2.0, 4.0) 
		else:
			patrol_timer = randf_range(3.0, 6.0) 
			if randf() > 0.5: # 50% kemungkinan putar balik
				patrol_direction *= -1

	if is_patrol_resting:
		velocity.x = move_toward(velocity.x, 0, PATROL_SPEED)
	else:
		velocity.x = patrol_direction * PATROL_SPEED
		flip_character(patrol_direction)

# ==========================================
# FUNGSI INTERAKSI & PERTARUNGAN
# ==========================================
func attack(target):
	is_attacking = true
	can_attack = false

	# Pilih gaya pukulan secara acak (Dipanggil HANYA SEKALI per serangan)
	var attack_list = ["attack1", "attack2", "attack3"]
	var random_attack = attack_list.pick_random()
	anim.play(random_attack) 
	
	if target.has_method("take_damage"):
		target.take_damage(MELEE_DAMAGE)

	# Tunggu sampai animasi memukul selesai
	await get_tree().create_timer(0.6).timeout
	is_attacking = false
	
	# Cooldown napas sebelum bisa memukul lagi
	await get_tree().create_timer(1.0).timeout
	can_attack = true

func take_damage(amount):
	if is_dead: return
	
	hp -= amount
	is_hurt = true
	velocity.x = 0 # Terkejut, hentikan kecepatan asli
	
	# Fitur Balas Dendam: Cari siapa yang menembak dari jauh!
	if not is_chasing:
		var p = get_tree().get_first_node_in_group("player")
		if p:
			player_target = p
			is_chasing = true

	if hp <= 0:
		die()
	else:
		# Durasi efek stagger / lumpuh
		await get_tree().create_timer(0.3).timeout
		is_hurt = false

func apply_knockback(amount: float):
	if is_dead: return
	
	knockback_force.x = amount
	is_hurt = true	
	# Durasi lumpuh akibat terdorong
	await get_tree().create_timer(0.4).timeout
	is_hurt = false
	
func die():
	is_dead = true
	
	# SOLUSI ANTI NO-CLIP:
	# Matikan Layer agar tidak bisa ditabrak player/peluru lagi,
	# tapi biarkan Mask di Layer 1 (World) agar mayat tetap berpijak di lantai.
	collision_layer = 0
	collision_mask = 1 
	
	# Matikan sensor agar mayat tidak memukul atau melotot
	attack_range.set_deferred("monitoring", false)
	detector.set_deferred("monitoring", false)
	
	# Turunkan urutan gambar agar mayat selalu di belakang kaki pemain yang hidup
	z_index = -1
	
	print("Tango Down!")
	
	# Hapus mayat setelah 30 detik untuk menghemat memori
	await get_tree().create_timer(30.0).timeout
	queue_free()

# ==========================================
# SINYAL SENSOR
# ==========================================
func _on_attack_range_entered(body):
	if body.name == "Player":
		player_in_attack_range = true

func _on_attack_range_exited(body):
	if body.name == "Player":
		player_in_attack_range = false

func _on_player_entered(body):
	if body.name == "Player":
		player_target = body
		is_chasing = true

#func _on_player_exited(body):
	#if body.name == "Player":
		#player_target = null
		#is_chasing = false
