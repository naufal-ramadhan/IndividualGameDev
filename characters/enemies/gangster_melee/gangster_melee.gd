extends PatrollingEnemy

@export var melee_damage: float = 15.0 # Bisa diubah per-musuh

var is_attacking = false
var can_attack = true
var player_in_attack_range = false

@onready var anim = $CharacterVisualAnimated 
@onready var detector = $PlayerDetector
@onready var attack_range = $AttackRange 

func _ready():
	detector.body_entered.connect(_on_player_entered)
	attack_range.body_entered.connect(_on_attack_range_entered)
	attack_range.body_exited.connect(_on_attack_range_exited)

func _physics_process(delta):
	if is_dead:
		velocity.x = 0
		if not is_on_floor(): velocity.y += gravity * delta
		move_and_slide()
		update_animations()
		return

	velocity.x += knockback_force.x
	knockback_force.x = move_toward(knockback_force.x, 0, 800 * delta)
	
	if not is_on_floor(): velocity.y += gravity * delta

	if is_hurt:
		move_and_slide() 
		update_animations() 
		return 

	if is_attacking:
		velocity.x = 0 
	elif is_chasing and player_target != null:
		var direction = sign(player_target.global_position.x - global_position.x)
		flip_character(direction)
		
		if player_in_attack_range:
			velocity.x = 0
			if can_attack: attack(player_target)
		else:
			velocity.x = direction * chase_speed 
	else:
		if can_patrol:
			do_patrol(delta) # Memanggil fungsi milik Ayahnya (PatrollingEnemy)
		else:
			velocity.x = move_toward(velocity.x, 0, chase_speed) 

	move_and_slide()
	update_animations()

func update_animations():
	if is_dead:
		if anim.animation != "dead": anim.play("dead")
		return
	if is_hurt:
		if anim.animation != "hurt": anim.play("hurt")
		return
	if is_attacking:
		return 

	if abs(velocity.x) > 5.0: 
		if is_chasing: anim.play("run")
		else: anim.play("walk")
	else:
		play_idle_logic()

func play_idle_logic():
	if anim.animation == "idle2" and anim.is_playing(): return
	if randf() < 0.005: anim.play("idle2")
	else: anim.play("idle1")

# Override fungsi bapaknya untuk memutar badannya sendiri
func flip_character(direction):
	if direction > 0: 
		anim.flip_h = false
		attack_range.position.x = 34
	elif direction < 0: 
		anim.flip_h = true
		attack_range.position.x = -6

func attack(target):
	is_attacking = true
	can_attack = false
	var attack_list = ["attack1", "attack2", "attack3"]
	anim.play(attack_list.pick_random()) 
	
	if target.has_method("take_damage"): target.take_damage(melee_damage)

	await get_tree().create_timer(0.6).timeout
	is_attacking = false
	await get_tree().create_timer(1.0).timeout
	can_attack = true

func die():
	super.die() 
	attack_range.set_deferred("monitoring", false)
	detector.set_deferred("monitoring", false)

func _on_attack_range_entered(body):
	if body.name == "Player": player_in_attack_range = true

func _on_attack_range_exited(body):
	if body.name == "Player": player_in_attack_range = false

func _on_player_entered(body):
	if body.name == "Player":
		player_target = body
		is_chasing = true
