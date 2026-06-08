extends PatrollingEnemy

@export var melee_damage: float = 18.0
@export var charge_trigger_distance: float = 260.0
@export var charge_speed: float = 520.0
@export var charge_duration: float = 0.45
@export var minimum_charge_visual_time: float = 0.18

var is_attacking = false
var can_attack = true
var player_in_attack_range = false
var is_winding_up_charge = false
var is_charging = false
var has_charged = false
var has_hit_during_charge = false
var charge_direction = 1
var charge_time_left = 0.0
var charge_visual_time_left = 0.0

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
		is_winding_up_charge = false
		is_charging = false
		velocity.x = move_toward(velocity.x, 0, 4000 * delta)
		move_and_slide()
		update_animations()
		return

	if is_attacking or is_winding_up_charge:
		velocity.x = 0
	elif is_charging:
		velocity.x = charge_direction * charge_speed
		charge_time_left -= delta
		charge_visual_time_left -= delta
		if charge_visual_time_left <= 0.0 and player_in_attack_range and not has_hit_during_charge and player_target != null:
			hit_player_during_charge(player_target)
		if charge_time_left <= 0.0:
			finish_charge()
	elif is_chasing and player_target != null:
		var direction = sign(player_target.global_position.x - global_position.x)
		if direction == 0:
			direction = -1 if anim.flip_h else 1
		flip_character(direction)
		var distance_to_player = abs(player_target.global_position.x - global_position.x)

		if not has_charged and distance_to_player <= charge_trigger_distance:
			start_charge(direction)
		elif player_in_attack_range:
			velocity.x = 0
			if can_attack: attack(player_target)
		else:
			velocity.x = direction * chase_speed
	else:
		if can_patrol:
			do_patrol(delta)
		else:
			velocity.x = move_toward(velocity.x, 0, chase_speed)

	move_and_slide()
	update_animations()

func start_charge(direction):
	if has_charged or is_winding_up_charge or is_charging:
		return
	has_charged = true
	is_winding_up_charge = true
	charge_direction = direction
	flip_character(charge_direction)
	velocity.x = 0
	anim.play("special")

	await anim.animation_finished

	if is_dead or is_hurt:
		is_winding_up_charge = false
		return

	is_winding_up_charge = false
	is_charging = true
	has_hit_during_charge = false
	charge_time_left = charge_duration
	charge_visual_time_left = minimum_charge_visual_time
	velocity.x = charge_direction * charge_speed
	anim.play("charge")

func finish_charge():
	if not is_charging:
		return
	is_charging = false
	has_hit_during_charge = true
	velocity.x = 0

func hit_player_during_charge(target):
	has_hit_during_charge = true
	if target.has_method("take_damage"):
		target.take_damage(melee_damage, self)
	finish_charge()

func update_animations():
	if is_dead:
		if anim.animation != "dead": anim.play("dead")
		return
	if is_hurt:
		if anim.animation != "hurt": anim.play("hurt")
		return
	if is_winding_up_charge:
		if anim.animation != "special": anim.play("special")
		return
	if is_attacking:
		return
	if is_charging:
		anim.play("charge")
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

func flip_character(direction):
	if direction > 0:
		anim.flip_h = false
		attack_range.position.x = 34
	elif direction < 0:
		anim.flip_h = true
		attack_range.position.x = -6

func attack(target):
	is_attacking = true
	is_charging = false
	can_attack = false
	var attack_list = ["attack1", "attack2"]
	anim.play(attack_list.pick_random())
	if has_node("PunchSFX"):
		$PunchSFX.play()

	if target.has_method("take_damage"):
		target.take_damage(melee_damage, self)

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
