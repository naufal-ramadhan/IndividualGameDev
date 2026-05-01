extends Area2D

const SPEED = 800.0

# 1. UBAH CONST JADI VAR! Agar nilainya bisa diubah-ubah oleh musuh
var damage: float = 25.0 

var direction = 1 

func _ready():
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _physics_process(delta):
	position.x += direction * SPEED * delta

func _on_body_entered(body):
	# 2. SISTEM ANTI FRIENDLY-FIRE! Kalau nabrak sesama Gangster, peluru tembus saja
	if body is BaseEnemy:
		return 
		
	# 3. Kalau nabrak tembok atau lantai, langsung hancur
	if body.name == "TileMap" or body.name == "Ground":
		queue_free()
		return
		
	# 4. Kalau nabrak Player, oper damage-nya
	if body.has_method("take_damage"):
		body.take_damage(damage, self)
		queue_free()
