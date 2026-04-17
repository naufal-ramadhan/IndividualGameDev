extends CharacterBody2D

# --- KONSTANTA ---
const SPEED = 200.0
const RUN_SPEED = 320.0 # Tambahan: Kecepatan lari
const STAMINA_DRAIN_RATE = 20.0 
const STAMINA_DRAIN_RUN = 10.0 # Tambahan: Konsumsi stamina lari per detik
const STAMINA_REGEN_RATE = 15.0 
const MAX_AMMO = 7 # Tambahan: Maksimal peluru
const ZOOM_DEFAULT = Vector2(1.2, 1.2) # Zoom normal saat jalan
const ZOOM_SHIELD = Vector2(1.5, 1.5)  # Zoom in saat pakai tameng

# --- VARIABEL STATUS ---
var current_stamina = 100.0
var current_ammo = MAX_AMMO # Tambahan: Peluru saat ini
var is_shielding = false
var is_shooting = false
var is_running = false # Tambahan
var is_reloading = false # Tambahan

# --- REFERENSI NODE ---
@onready var anim = $CharacterVisualAnimated 
@onready var shield_sensor = $ShieldSensor
@onready var muzzle = $Muzzle
@onready var camera = $Camera

func _ready():
	# Kode di sini hanya akan dijalankan SATU KALI saat game baru mulai
	shield_sensor.position.x = 15
	muzzle.position.x = 20

func _physics_process(delta):
	var direction = Input.get_axis("move_left", "move_right")
	
	is_running = Input.is_action_pressed("run") and direction != 0 and not is_shielding and not is_reloading and not is_shooting and current_stamina > 0
	var current_speed = RUN_SPEED if is_running else SPEED
	
	# --- LOGIKA GERAK & LOCK (Berhenti jika sedang Shield, Nembak, atau Reload) ---
	if is_shielding or is_shooting or is_reloading:
		velocity.x = 0 # Karakter diam total, animasi kaki tidak akan meluncur
	else:
		if direction:
			velocity.x = direction * current_speed
			# --- LOGIKA FLIP BERDASARKAN INPUT A/D ---
			if direction > 0: # Hadap Kanan (Tombol D)
				anim.flip_h = false
				shield_sensor.position.x = 15
				muzzle.position.x = abs(muzzle.position.x)
			else: # Hadap Kiri (Tombol A)
				anim.flip_h = true
				shield_sensor.position.x = -15
				muzzle.position.x = -abs(muzzle.position.x)
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
	
	move_and_slide()
	update_animations(direction)

func _process(delta):
	# --- LOGIKA TAMENG & STAMINA ---
	if Input.is_action_pressed("shield") and current_stamina > 0 and not is_reloading:
		is_shielding = true
		current_stamina -= STAMINA_DRAIN_RATE * delta
	else:
		is_shielding = false
		# Stamina berkurang kalau lari, bertambah kalau santai
		if is_running:
			current_stamina -= STAMINA_DRAIN_RUN * delta
		elif current_stamina < 100.0:
			current_stamina += STAMINA_REGEN_RATE * delta

	# --- LOGIKA MENEMBAK ---
	# Ditambah validasi: gak bisa nembak saat reload
	if Input.is_action_just_pressed("shoot") and not is_shielding and not is_reloading:
		shoot()
		
	# --- LOGIKA RELOAD ---
	if Input.is_action_just_pressed("reload") and current_ammo < MAX_AMMO and not is_reloading and not is_shielding:
		reload()

	var target_zoom = Vector2(1.2, 1.2) # Zoom normal saat jalan
	if is_shielding:
		target_zoom = Vector2(1.5, 1.5) # Zoom in saat angkat tameng
		
	# lerp bikin pergerakan kameranya mulus, angka 5.0 itu kecepatan transisinya
	camera.zoom = camera.zoom.lerp(target_zoom, 5.0 * delta)
	
func update_animations(direction):
	# 1. Prioritas Ekstra: Reload
	if is_reloading:
		anim.play("reload") # Pastikan ada animasi bernama "reload"
		
	# 2. Prioritas Tertinggi: Menembak
	elif is_shooting:
		anim.play("shoot")
	
	# 3. Prioritas Kedua: Pakai Tameng
	elif is_shielding:
		anim.play("shield") 
	
	# 4. Prioritas Ketiga: Bergerak/Lari (Hanya jika tidak shielding)
	elif direction != 0 and not is_shielding:
		if is_running:
			anim.play("run") # Pastikan ada animasi bernama "run"
		else:
			anim.play("walk")
	
	# 5. Kondisi Terakhir: Diam
	else:
		anim.play("idle")

func shoot():
	if current_ammo > 0:
		is_shooting = true
		current_ammo -= 1
		anim.play("shoot")
		
		print("DOR! Sisa peluru: ", current_ammo)
		
		await get_tree().create_timer(0.3).timeout 
		is_shooting = false
	else:
		print("Peluru Habis! Tekan R")

# --- FUNGSI RELOAD BARU ---
func reload():
	is_reloading = true
	anim.play("reload")
	print("Reloading...")
	
	# Waktu tunggu simulasi reload (misal 1 detik)
	await get_tree().create_timer(1.0).timeout 
	
	current_ammo = MAX_AMMO
	is_reloading = false
	print("Reload Selesai! Peluru Penuh.")
