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
@onready var anim = $CharacterVisualAnimated 
@onready var detector = $PlayerDetector
@onready var attack_range = $AttackRange 

func _ready():
	detector.body_entered.connect(_on_player_entered)
	detector.body_exited.connect(_on_player_exited)
	attack_range.body_entered.connect(_on_attack_range_entered)

func _physics_process(delta):
	if is_dead or is_hurt:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if is_attacking:
		velocity.x = 0
	elif is_chasing and player_target != null:
		var direction = sign(player_target.global_position.x - global_position.x)
		
		if abs(player_target.global_position.x - global_position.x) < 15:
			velocity.x = 0
		else:
			velocity.x = direction * SPEED
		
		if direction > 0: # Hadap Kanan
			anim.flip_h = false
			attack_range.position.x = 34
		elif direction < 0: # Hadap Kiri
			anim.flip_h = true
			attack_range.position.x = -14
		
		anim.play("run")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		play_idle_logic()

	move_and_slide()

# --- LOGIKA ANIMASI IDLE (Variasi 1 & 2) ---
func play_idle_logic():
	if anim.animation != "idle2" or not anim.is_playing():
		if randf() < 0.005:
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
	anim.play("hurt")
	print("Gangster: Aduh!")
	
	# Logika HP Gangster bisa ditambah di sini nanti
	
	await get_tree().create_timer(0.3).timeout
	is_hurt = false
