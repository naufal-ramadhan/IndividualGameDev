extends Node2D

@export var list_musuh: Array[PackedScene]

@onready var timer = $Timer
@onready var spawn_kiri = $SpawnKiri
@onready var spawn_kanan = $SpawnKanan
@onready var player = get_tree().get_first_node_in_group("player")

var current_wave = 0
var musuh_sisa_di_spawner = 0

func _ready():
	timer.timeout.connect(_on_timer_timeout)
	mulai_wave_baru()

func _process(delta):
	if musuh_sisa_di_spawner <= 0:
		var musuh_hidup = get_tree().get_nodes_in_group("enemy").size()
		
		if musuh_hidup == 0:
			mulai_wave_baru()

func mulai_wave_baru():
	current_wave += 1
	
	if player != null and player.has_method("update_wave_ui"):
		player.update_wave_ui(current_wave)
	
	musuh_sisa_di_spawner = current_wave * 2 
	
	print("--- WAVE ", current_wave, " DIMULAI! TARGET: ", musuh_sisa_di_spawner, " MUSUH ---")
	
	#timer.wait_time = max(0.8, 3.0 - (current_wave * 0.2)) 
	
	timer.stop()
	await get_tree().create_timer(3.0).timeout
	timer.start()

func _on_timer_timeout():
	if musuh_sisa_di_spawner <= 0 or list_musuh.is_empty():
		timer.stop() 
		return
		
	var scene_terpilih = list_musuh.pick_random()
	var enemy = scene_terpilih.instantiate()
	
	if randf() > 0.5: 
		enemy.global_position = spawn_kiri.global_position
	else: 
		enemy.global_position = spawn_kanan.global_position
		
	if player != null:
		enemy.player_target = player
		enemy.is_chasing = true
	
	enemy.add_to_group("enemy") 
	add_child(enemy)
	musuh_sisa_di_spawner -= 1
	
	var kecepatan_minimum = max(1.0, 3.0 - (current_wave * 0.15))
	timer.wait_time = randf_range(kecepatan_minimum, kecepatan_minimum + 1.5)
