extends CharacterBody2D

# --- KONSTANTA ---
const SPEED = 110.0 
const GRAVITY = 900.0
const MELEE_DAMAGE = 15.0

# --- VARIABEL STATUS ---
var player_target = null 
var is_chasing = false
var is_attacking = false
var is_hurt = false
var is_dead = false
var can_attack = true

# --- REFERENSI NODE ---
# Sesuaikan dengan nama di Tree Scene kamu
@onready var anim = $CharacterVisualAnimated 
@onready var detector = $PlayerDetector
# Pastikan kamu sudah menambahkan Area2D bernama AttackRange di bawah root
@onready var attack_range = $AttackRange 

func _ready():
	# Koneksi Sinyal
	detector.body_entered.connect(_on_player_entered)
	detector.body_exited.connect(_on_player_exited)
	attack_range.body_entered.connect(_on_attack_range_entered)

func _physics_process(delta):
	if is_dead or is_hurt:
		return

	# 1. Gravitasi
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# 2. Logika Pergerakan & Animasi
	if is_attacking:
		velocity.x = 0
	elif is_chasing and player_target != null:
		var direction = sign(player_target.global_position.x - global_position.x)
		velocity.x = direction * SPEED
		
		# Flip Visual & Hitbox
		anim.flip_h = direction < 0 
		attack_range.position.x = abs(attack_range.position.x) * direction
		
		anim.play("run")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		play_idle_logic()

	move_and_slide()

# --- LOGIKA ANIMASI IDLE (Variasi 1 & 2) ---
func play_idle_logic():
	# Jika tidak sedang main animasi idle2, mainkan idle1 secara default
	if anim.animation != "idle2" or not anim.is_playing():
		# Kadang-kadang (Random) bisa ganti ke idle2 kalau mau lebih hidup
		if randf() < 0.005: # Peluang kecil setiap frame untuk main idle2
			anim.play("idle2")
		else:
			anim.play("idle1")

# --- LOGIKA SERANGAN ---
func _on_attack_range_entered(body):
	if body.name == "Player" and can_attack and not is_dead:
		attack(body)

func attack(target):
	is_attacking = true
	can_attack = false
	
	# RANDOM ATTACK: Pilih antara attack1, attack2, atau attack3
	var attack_list = ["attack1", "attack2", "attack3"]
	var random_attack = attack_list.pick_random()
	anim.play(random_attack)
	
	print("Gangster pake: ", random_attack)
	
	# Beri damage ke Player
	if target.has_method("take_damage"):
		target.take_damage(MELEE_DAMAGE)
	
	# Tunggu sampai animasi serangan selesai (asumsi rata-rata 0.6 detik)
	await get_tree().create_timer(0.6).timeout
	is_attacking = false
	
	# Cooldown sebelum mukul lagi
	await get_tree().create_timer(1.0).timeout
	can_attack = true

# --- SENSOR DETEKSI ---
func _on_player_entered(body):
	if body.name == "Player":
		player_target = body
		is_chasing = true

func _on_player_exited(body):
	if body.name == "Player":
		player_target = null
		is_chasing = false

# --- FUNGSI JIKA GANGSTER DIPUKUL PLAYER (Nanti digunakan) ---
func take_damage(amount):
	if is_dead: return
	
	is_hurt = true
	# anim.play("hurt") # Aktifkan jika sudah ada animasinya
	print("Gangster: Aduh!")
	
	# Logika HP Gangster bisa ditambah di sini nanti
	
	await get_tree().create_timer(0.3).timeout
	is_hurt = false
