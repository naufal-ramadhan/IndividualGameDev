extends CharacterBody2D

# --- KONSTANTA ---
const SPEED = 200.0
const STAMINA_DRAIN_RATE = 20.0 
const STAMINA_REGEN_RATE = 15.0 

# --- VARIABEL STATUS ---
var current_stamina = 100.0
var is_shielding = false
var is_shooting = false

# --- REFERENSI NODE ---
@onready var anim = $CharacterVisualAnimated 
@onready var shield_sensor = $ShieldSensor
@onready var muzzle = $Muzzle

func _physics_process(delta):
	var direction = Input.get_axis("move_left", "move_right")
	
	# --- LOGIKA GERAK & LOCK (Hanya gerak jika TIDAK shielding) ---
	if is_shielding:
		velocity.x = 0 # Karakter diam total saat shield aktif
	else:
		if direction:
			velocity.x = direction * SPEED
			# --- LOGIKA FLIP BERDASARKAN INPUT A/D ---
			if direction > 0: # Hadap Kanan (Tombol D)
				anim.flip_h = false
				shield_sensor.position.x = abs(shield_sensor.position.x)
				muzzle.position.x = abs(muzzle.position.x)
			else: # Hadap Kiri (Tombol A)
				anim.flip_h = true
				shield_sensor.position.x = -abs(shield_sensor.position.x)
				muzzle.position.x = -abs(muzzle.position.x)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()
	update_animations(direction)

func _process(delta):
	# --- LOGIKA TAMENG ---
	if Input.is_action_pressed("shield") and current_stamina > 0:
		is_shielding = true
		current_stamina -= STAMINA_DRAIN_RATE * delta
	else:
		is_shielding = false
		if current_stamina < 100.0:
			current_stamina += STAMINA_REGEN_RATE * delta

	# --- LOGIKA MENEMBAK ---
	if Input.is_action_just_pressed("shoot") and not is_shielding:
		shoot()

func update_animations(direction):
	# 1. Prioritas Tertinggi: Menembak
	if is_shooting:
		anim.play("shoot")
	
	# 2. Prioritas Kedua: Pakai Tameng
	elif is_shielding:
		anim.play("shield") 
	
	# 3. Prioritas Ketiga: Bergerak/Lari (Hanya jika tidak shielding)
	elif direction != 0 and not is_shielding:
		anim.play("walk")
	
	# 4. Kondisi Terakhir: Diam
	else:
		anim.play("idle")

func shoot():
	is_shooting = true
	anim.play("shoot")
	
	print("DOR!")
	
	await get_tree().create_timer(0.3).timeout 
	is_shooting = false
