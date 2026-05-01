extends CharacterBody2D

# ==========================================
# KONSTANTA
# ==========================================
const SPEED = 200.0
const RUN_SPEED = 320.0
const STAMINA_DRAIN_RATE = 20.0 
const STAMINA_DRAIN_RUN = 10.0 
const STAMINA_REGEN_RATE = 15.0
const MIN_STAMINA_RECOVERY = 30.0 
const MAX_AMMO = 7
const ZOOM_DEFAULT = Vector2(2.2, 2.2)
const ZOOM_SHIELD = Vector2(2.5, 2.5)  
const MAX_HEALTH = 100.0
const BASH_DAMAGE = 10.0
const BASH_KNOCKBACK = 1200.0

# ==========================================
# VARIABEL STATUS (STATE)
# ==========================================
var current_stamina = 100.0
var current_ammo = MAX_AMMO
var current_health = MAX_HEALTH

# Gerbang Logika (Gatekeepers)
var is_shielding = false
var is_shooting = false
var is_running = false
var is_reloading = false
var is_exhausted = false
var is_hurt = false
var is_dead = false
var is_bashing = false

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# ==========================================
# REFERENSI NODE & SCENE
# ==========================================
@onready var anim = $CharacterVisualAnimated 
@onready var shield_sensor = $ShieldSensor
@onready var muzzle = $Muzzle
@onready var camera = $Camera
@onready var ammo_label = $UI/AmmoLabel
@onready var stamina_bar = $UI/StaminaBar
@onready var health_bar = $UI/HealthBar

@export var bullet_scene: PackedScene

# ==========================================
# FUNGSI INISIALISASI
# ==========================================
func _ready():
	# Posisi default saat hadap kanan
	shield_sensor.position.x = 30
	muzzle.position.x = 20

# ==========================================
# 1. MESIN FISIKA (PERGERAKAN & GRAVITASI)
# ==========================================
func _physics_process(delta):
	# Prioritas 1: Kematian mutlak (tapi tetap kena gravitasi)
	if is_dead:
		velocity.x = 0
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		update_animations()
		return

	# Hukum Alam: Gravitasi
	if not is_on_floor():
		velocity.y += gravity * delta

	# Prioritas 2: Terluka (Stagger)
	if is_hurt:
		velocity.x = 0
		move_and_slide()
		update_animations()
		return

	# Prioritas 3: Input Pergerakan Pemain
	var direction = Input.get_axis("move_left", "move_right")
	
	# Syarat bisa lari: Tombol ditekan, ada arah, tidak sibuk aksi lain, stamina cukup
	is_running = Input.is_action_pressed("run") and direction != 0 and not is_shielding and not is_reloading and not is_shooting and current_stamina > 0
	var current_speed = RUN_SPEED if is_running else SPEED
	
	# Kunci pergerakan jika sedang melakukan aksi
	if is_shielding or is_shooting or is_reloading or is_bashing:
		velocity.x = 0
	else:
		if direction != 0:
			velocity.x = direction * current_speed
			flip_character(direction)
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
	
	move_and_slide()
	update_animations()

# ==========================================
# 2. MESIN LOGIKA (INPUT, STAMINA, UI)
# ==========================================
func _process(delta):
	# UI & Kamera jalan terus
	update_ui()
	handle_camera(delta)

	# Jika mati/sakit, pemain tidak bisa input apa-apa
	if is_dead or is_hurt:
		return

	handle_stamina(delta)
	handle_combat_inputs()

func handle_stamina(delta):
	if current_stamina <= 0:
		is_exhausted = true
	elif current_stamina >= MIN_STAMINA_RECOVERY:
		is_exhausted = false
	
	if Input.is_action_pressed("shield") and not is_exhausted and not is_reloading:
		is_shielding = true
		current_stamina -= STAMINA_DRAIN_RATE * delta
	else:
		is_shielding = false
		if is_running:
			current_stamina -= STAMINA_DRAIN_RUN * delta
		elif current_stamina < 100.0:
			current_stamina += STAMINA_REGEN_RATE * delta

	current_stamina = clamp(current_stamina, 0.0, 100.0)

func handle_combat_inputs():
	if Input.is_action_just_pressed("shoot") and not is_shielding and not is_reloading and not is_bashing:
		shoot()
		
	if Input.is_action_just_pressed("reload") and current_ammo < MAX_AMMO and not is_reloading and not is_shielding and not is_bashing:
		reload()

	if Input.is_action_just_pressed("shield_bash") and not is_bashing and not is_reloading and not is_shooting:
		shield_bash()

func handle_camera(delta):
	var target_zoom = ZOOM_SHIELD if is_shielding else ZOOM_DEFAULT
	camera.zoom = camera.zoom.lerp(target_zoom, 5.0 * delta)

func update_ui():
	ammo_label.text = "AMMO: " + str(current_ammo) + " / " + str(MAX_AMMO)
	stamina_bar.value = current_stamina
	if health_bar:
		health_bar.value = current_health

# ==========================================
# 3. PUSAT MANAJEMEN ANIMASI (VISUAL)
# ==========================================
func update_animations():
	# Prioritas Mutlak
	if is_dead:
		if anim.animation != "dead": anim.play("dead")
		return
		
	if is_hurt:
		if anim.animation != "hurt": anim.play("hurt")
		return

	# Animasi Trigger/Aksi (Didelegasikan ke fungsinya masing-masing)
	if is_reloading or is_shooting or is_bashing:
		return 

	# Animasi Berkelanjutan (Continuous)
	if is_shielding:
		anim.play("shield") 
	elif abs(velocity.x) > 0:
		if is_running:
			anim.play("run")
		else:
			anim.play("walk")
	else:
		anim.play("idle")

func flip_character(direction):
	if direction > 0:
		anim.flip_h = false
		shield_sensor.position.x = 30
		muzzle.position.x = abs(muzzle.position.x)
	elif direction < 0:
		anim.flip_h = true
		shield_sensor.position.x = -40
		muzzle.position.x = -abs(muzzle.position.x)

# ==========================================
# 4. FUNGSI AKSI & PERTARUNGAN
# ==========================================
func shoot():
	if current_ammo > 0:
		is_shooting = true
		current_ammo -= 1
		anim.play("shoot")
		print("DOR! Sisa peluru: ", current_ammo)
		
		if bullet_scene != null:
			var bullet = bullet_scene.instantiate()
			bullet.direction = -1 if anim.flip_h else 1
			bullet.global_position = muzzle.global_position
			get_tree().root.add_child(bullet)
		
		await get_tree().create_timer(0.3).timeout 
		is_shooting = false
	else:
		print("Peluru Habis! Tekan R")

func reload():
	is_reloading = true
	anim.play("reload")
	print("Reloading...")
	
	await get_tree().create_timer(1.0).timeout 
	
	current_ammo = MAX_AMMO
	is_reloading = false
	print("Reload Selesai! Peluru Penuh.")

func shield_bash():
	is_bashing = true
	anim.play("shield_bash")
	
	var targets = shield_sensor.get_overlapping_bodies()
	for body in targets:
		if body.name == "Player": continue
		
		if body.has_method("take_damage"):
			body.take_damage(BASH_DAMAGE) 
			
			if body.has_method("apply_knockback"):
				var knockback_dir = -1 if anim.flip_h else 1
				body.apply_knockback(knockback_dir * BASH_KNOCKBACK, 1.5)
	await get_tree().create_timer(0.4).timeout
	is_bashing = false

func take_damage(amount: float, attacker: Node2D = null):
	if is_dead: return

	if is_shielding and attacker != null:
		var is_facing_right = not anim.flip_h 
		
		var is_attacker_in_front = false
		if is_facing_right and attacker.global_position.x > global_position.x:
			is_attacker_in_front = true
		elif not is_facing_right and attacker.global_position.x < global_position.x:
			is_attacker_in_front = true
			
		if is_attacker_in_front:
			print("Serangan dari DEPAN diblokir!")
			return
		else:
			print("Aduh! Ditembak dari BELAKANG!")

	current_health -= amount
	current_health = clamp(current_health, 0, MAX_HEALTH)

	if current_health <= 0:
		die()
	else:
		is_hurt = true
		anim.modulate = Color(1, 0.5, 0.5) 
		
		await get_tree().create_timer(0.4).timeout
		
		anim.modulate = Color(1, 1, 1)
		is_hurt = false

func die():
	is_dead = true
	# Tidak memanggil anim.play("dead") di sini karena diurus update_animations
	print("SWAT Down! Mission Failed.")
	
	# Matikan deteksi fisik peluru/musuh
	set_collision_layer_value(1, false)
