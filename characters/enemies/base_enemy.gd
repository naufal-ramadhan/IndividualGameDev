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

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func apply_knockback(amount: float):
	if is_dead: return
	knockback_force.x = amount
	is_hurt = true	
	await get_tree().create_timer(0.4).timeout
	is_hurt = false

func take_damage(amount: float):
	if is_dead: return
	hp -= amount
	is_hurt = true
	velocity.x = 0
	
	if not is_chasing:
		var p = get_tree().get_first_node_in_group("player")
		if p:
			player_target = p
			is_chasing = true

	if hp <= 0:
		die()
	else:
		await get_tree().create_timer(0.3).timeout
		is_hurt = false

func die():
	is_dead = true
	collision_layer = 0
	collision_mask = 1 
	z_index = 0
	
	print("Tango Down! (Dari BaseEnemy)")
	await get_tree().create_timer(30.0).timeout
	queue_free()
