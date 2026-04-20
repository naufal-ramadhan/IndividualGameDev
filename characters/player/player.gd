extends CharacterBody2D

# --- KONSTANTA ---
const SPEED = 200.0
const RUN_SPEED = 320.0
const STAMINA_DRAIN_RATE = 20.0 
const STAMINA_DRAIN_RUN = 10.0 
const STAMINA_REGEN_RATE = 15.0
const MIN_STAMINA_RECOVERY = 30.0 
const MAX_AMMO = 7
const ZOOM_DEFAULT = Vector2(2.2, 2.2) # Zoom normal saat jalan
const ZOOM_SHIELD = Vector2(2.5, 2.5)  # Zoom in saat pakai tameng

# --- VARIABEL STATUS ---
var current_stamina = 100.0
var current_ammo = MAX_AMMO
var is_shielding = false
var is_shooting = false
var is_running = false
var is_reloading = false
var is_exhausted = false

# --- REFERENSI NODE ---
@onready var anim = $CharacterVisualAnimated 
@onready var shield_sensor = $ShieldSensor
@onready var muzzle = $Muzzle
@onready var camera = $Camera
@onready var ammo_label = $UI/AmmoLabel
@onready var stamina_bar = $UI/StaminaBar

# --- REFERENSI SCENE ---
@export var bullet_scene: PackedScene

func _ready():
	shield_sensor.position.x = 15
	muzzle.position.x = 20

func _physics_process(delta):
	var direction = Input.get_axis("move_left", "move_right")
	
	is_running = Input.is_action_pressed("run") and direction != 0 and not is_shielding and not is_reloading and not is_shooting and current_stamina > 0
	var current_speed = RUN_SPEED if is_running else SPEED
	
	if is_shielding or is_shooting or is_reloading:
		velocity.x = 0
	else:
		if direction:
			velocity.x = direction * current_speed
			if direction > 0:
				anim.flip_h = false
				shield_sensor.position.x = 15
				muzzle.position.x = abs(muzzle.position.x)
			else:
				anim.flip_h = true
				shield_sensor.position.x = -15
				muzzle.position.x = -abs(muzzle.position.x)
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
	
	move_and_slide()
	update_animations(direction)

func _process(delta):
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

	if Input.is_action_just_pressed("shoot") and not is_shielding and not is_reloading:
		shoot()
		
	if Input.is_action_just_pressed("reload") and current_ammo < MAX_AMMO and not is_reloading and not is_shielding:
		reload()

	var target_zoom = ZOOM_DEFAULT
	if is_shielding:
		target_zoom = ZOOM_SHIELD
	camera.zoom = camera.zoom.lerp(target_zoom, 5.0 * delta)
	
	ammo_label.text = "AMMO: " + str(current_ammo) + " / " + str(MAX_AMMO)
	stamina_bar.value = current_stamina
	
func update_animations(direction):
	if is_reloading:
		anim.play("reload")
	elif is_shooting:
		anim.play("shoot")
	elif is_shielding:
		anim.play("shield") 
	elif direction != 0 and not is_shielding:
		if is_running:
			anim.play("run")
		else:
			anim.play("walk")
	else:
		anim.play("idle")

func shoot():
	if current_ammo > 0:
		is_shooting = true
		current_ammo -= 1
		anim.play("shoot")
		print("DOR! Sisa peluru: ", current_ammo)
		
		# --- PROSES SPAWN PELURU ---
		if bullet_scene != null:
			var bullet = bullet_scene.instantiate() # Gandakan peluru
			
			# Tentukan arah peluru (1 jika hadap kanan, -1 jika kiri)
			bullet.direction = -1 if anim.flip_h else 1
			
			# Set posisi peluru agar muncul persis di node Muzzle
			bullet.global_position = muzzle.global_position
			
			# Masukkan peluru ke dalam dunia game
			get_tree().root.add_child(bullet)
		
		await get_tree().create_timer(0.3).timeout 
		is_shooting = false
	else:
		print("Peluru Habis! Tekan R")

# --- FUNGSI RELOAD BARU ---
func reload():
	is_reloading = true
	anim.play("reload")
	print("Reloading...")
	
	await get_tree().create_timer(1.0).timeout 
	
	current_ammo = MAX_AMMO
	is_reloading = false
	print("Reload Selesai! Peluru Penuh.")
