extends Node2D

@export var list_musuh: Array[PackedScene]

@onready var timer = $Timer
@onready var spawn_kiri = $SpawnKiri
@onready var spawn_kanan = $SpawnKanan
@onready var player = get_tree().get_first_node_in_group("player")

# --- TAMBAHAN UNTUK BALANCING ---
var spawn_rate = 3.0 # Awal-awal muncul tiap 3 detik
var min_spawn_rate = 0.8 # Maksimal seganas apa (jangan sampai 0, nanti crash!)

func _ready():
	timer.wait_time = spawn_rate # Set waktu awal
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	if list_musuh.is_empty(): return 
		
	var scene_terpilih = list_musuh.pick_random()
	var enemy = scene_terpilih.instantiate()
	
	if randf() > 0.5: enemy.global_position = spawn_kiri.global_position
	else: enemy.global_position = spawn_kanan.global_position
		
	if player != null:
		enemy.player_target = player
		enemy.is_chasing = true
		
	add_child(enemy)

	# --- LOGIKA GRADUAL DIFFICULTY ---
	if spawn_rate > min_spawn_rate:
		spawn_rate -= 0.05 # Kurangi jeda 0.05 detik setiap musuh muncul!
		timer.wait_time = spawn_rate # Terapkan kecepatan baru ke Timer
