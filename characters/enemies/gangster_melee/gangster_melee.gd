extends CharacterBody2D

# --- KONSTANTA ---
const SPEED = 110.0 
const PATROL_SPEED = 50.0 # Kecepatan saat santai/patroli
const GRAVITY = 900.0
const MELEE_DAMAGE = 15.0

# --- SETTING DI EDITOR ---
# Klik musuh di Scene Level, lihat Inspector kanan. Kamu bisa centang/uncentang ini!
@export var can_patrol: bool = false 

# --- VARIABEL STATUS ---
var player_target = null 
var is_chasing = false
var is_attacking = false
var is_hurt = false
var is_dead = false
var can_attack = true
var player_in_attack_range = false # TAMBAHAN: Untuk ngecek pemain masih nempel

# --- VARIABEL PATROLI ---
var patrol_direction = 1
var patrol_timer = 0.0
var is_patrol_resting = false

# --- REFERENSI NODE ---
@onready var anim = $CharacterVisualAnimated 
@onready var detector = $PlayerDetector
@onready var attack_range = $AttackRange 

func _ready():
	detector.body_entered.connect(_on_player_entered)
	detector.body_exited.connect(_on_player_exited)
	
	# Hubungkan sinyal masuk dan keluar dari kotak pukul
	attack_range.body_entered.connect(_on_attack_range_entered)
	attack_range.body_exited.connect(_on_attack_range_exited) # Sinyal Baru!

func _physics_process(delta):
	if is_dead or is_hurt:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if is_attacking:
		velocity.x = 0
	elif is_chasing and player_target != null:
		# --- LOGIKA MENGEJAR ---
		var direction = sign(player_target.global_position.x - global_position.x)
		
		# Selalu pastikan musuh menatap ke arah Player
		flip_character(direction)
		
		if player_in_attack_range:
			velocity.x = 0
			play_idle_logic()
		else:
			velocity.x = direction * SPEED
			anim.play("run")
		
		if player_in_attack_range and can_attack:
			attack(player_target)
			
	else:
		# --- LOGIKA SANTAI / PATROLI ---
		if can_patrol:
			do_patrol(delta)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			play_idle_logic()

	move_and_slide()

# Fungsi untuk mengatur hadap visual (dipisah biar rapi)
func flip_character(direction):
	if direction > 0: # Hadap Kanan
		anim.flip_h = false
		attack_range.position.x = 34
	elif direction < 0: # Hadap Kiri
		anim.flip_h = true
		attack_range.position.x = -6

# --- LOGIKA PATROLI BARU ---
func do_patrol(delta):
	patrol_timer -= delta
	
	# Kalau waktu habis, ganti kegiatan (dari jalan jadi diam, atau sebaliknya)
	if patrol_timer <= 0:
		is_patrol_resting = !is_patrol_resting
		if is_patrol_resting:
			patrol_timer = randf_range(2.0, 4.0) # Diam istirahat 2-4 detik
		else:
			patrol_timer = randf_range(3.0, 6.0) # Jalan keliling 3-6 detik
			# 50% peluang putar balik saat mulai jalan lagi
			if randf() > 0.5:
				patrol_direction *= -1

	# Jalankan pergerakannya
	if is_patrol_resting:
		velocity.x = move_toward(velocity.x, 0, PATROL_SPEED)
		play_idle_logic()
	else:
		velocity.x = patrol_direction * PATROL_SPEED
		flip_character(patrol_direction)
		# Kalau punya animasi jalan santai ("walk"), pakai itu. Kalau ga ada, pakai "run".
		anim.play("walk") 

func play_idle_logic():
	if anim.animation != "idle2" or not anim.is_playing():
		if randf() < 0.005:
			anim.play("idle2")
		else:
			anim.play("idle1")

# --- SENSOR SERANGAN ---
func _on_attack_range_entered(body):
	if body.name == "Player":
		player_in_attack_range = true

func _on_attack_range_exited(body):
	if body.name == "Player":
		player_in_attack_range = false

func attack(target):
	is_attacking = true
	can_attack = false

	var attack_list = ["attack1", "attack2", "attack3"]
	var random_attack = attack_list.pick_random()
	anim.play(random_attack)
	
	print("Gangster pake: ", random_attack)
	
	if target.has_method("take_damage"):
		target.take_damage(MELEE_DAMAGE)

	await get_tree().create_timer(0.6).timeout
	is_attacking = false
	
	await get_tree().create_timer(1.0).timeout
	can_attack = true

# --- SENSOR DETEKSI (MATA) ---
func _on_player_entered(body):
	if body.name == "Player":
		player_target = body
		is_chasing = true

func _on_player_exited(body):
	if body.name == "Player":
		player_target = null
		is_chasing = false

func take_damage(amount):
	if is_dead: return
	
	is_hurt = true
	anim.play("hurt")
	print("Gangster: Aduh!")
	
	await get_tree().create_timer(0.3).timeout
	is_hurt = false
