extends CharacterBody2D
class_name BaseEnemy

# Kita pakai @export var agar HP bisa diatur per-musuh di Editor!
@export var max_hp: float = 100.0
@onready var hp: float = max_hp

var knockback_force = Vector2.ZERO
var player_target = null 

var is_chasing = false
var is_hurt = false
var is_dead = false
var stun_id: int = 0 # <-- Variabel antrean stun

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func apply_knockback(amount: float, stun_duration: float = 1.5):
	if is_dead: return
	velocity.x = amount 
	trigger_stun(stun_duration)

func take_damage(amount: float):
	if is_dead: return
	hp -= amount
	velocity.x = 0
	
	if not is_chasing:
		var p = get_tree().get_first_node_in_group("player")
		if p:
			player_target = p
			is_chasing = true

	if hp <= 0:
		die()
	else:
		trigger_stun(0.3)

# ==========================================
# FUNGSI MANAJEMEN STUN
# ==========================================
func trigger_stun(duration: float):
	is_hurt = true
	
	stun_id += 1 
	var my_id = stun_id
	
	await get_tree().create_timer(duration).timeout
	
	if my_id == stun_id and not is_dead:
		is_hurt = false
# ==========================================

func die():
	is_dead = true
	remove_from_group("enemy")
	collision_layer = 0
	collision_mask = 1 
	z_index = 0
	
	print("Tango Down! (Dari BaseEnemy)")
	await get_tree().create_timer(30.0).timeout
	queue_free()
