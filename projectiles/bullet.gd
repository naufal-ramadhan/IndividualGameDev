extends Area2D

const SPEED = 800.0
var damage: float = 25.0 # Boleh tetap pakai var

var direction = 1 

func _ready():
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _physics_process(delta):
	position.x += direction * SPEED * delta

func _on_body_entered(body):
	# Kalau nabrak Player sendiri (misal lari nabrak peluru sendiri), biarkan tembus!
	if body.name == "Player":
		return
		
	if body.name == "TileMap" or body.name == "Ground":
		queue_free()
		return
		
	# Tembak musuh
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
