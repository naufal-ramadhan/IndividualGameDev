extends Area2D

const SPEED = 800.0
const DAMAGE = 25.0

var direction = 1 # 1 untuk hadap kanan, -1 untuk hadap kiri

func _ready():
	body_entered.connect(_on_body_entered)
	
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _physics_process(delta):
	position.x += direction * SPEED * delta

func _on_body_entered(body):
	# Abaikan jika yang ditabrak adalah Player itu sendiri
	if body.name == "Player":
		return
		
	# Cek apakah yang ditabrak punya fungsi take_damage (berarti itu musuh)
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)
		
	# Apapun yang ditabrak (tembok atau musuh), peluru harus hancur
	queue_free()
