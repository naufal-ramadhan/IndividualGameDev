extends Node2D

var effect_color = Color(1.0, 0.25, 0.18, 1.0)
var strength = 1.0
var age = 0.0
var duration = 0.18
var is_blood = false
var impact_direction = Vector2.LEFT
var sparks: Array[Vector2] = []

func _ready():
	var spark_count = 12 if is_blood else 10
	for i in range(spark_count):
		if is_blood:
			var blood_dir = Vector2(randf_range(-0.9, 0.35), randf_range(-0.25, 0.75)).normalized()
			sparks.append(blood_dir * randf_range(8.0, 24.0) * strength)
		else:
			var angle = randf_range(-0.9, 0.9)
			sparks.append(impact_direction.rotated(angle) * randf_range(8.0, 22.0) * strength)

func setup(new_color: Color, new_strength: float = 1.0, new_direction: Vector2 = Vector2.LEFT):
	effect_color = new_color
	strength = new_strength
	impact_direction = new_direction.normalized()
	if impact_direction == Vector2.ZERO:
		impact_direction = Vector2.LEFT
	is_blood = effect_color.r > 0.7 and effect_color.g < 0.35

func _process(delta):
	age += delta
	if age >= duration:
		queue_free()
		return
	queue_redraw()

func _draw():
	var progress = clamp(age / duration, 0.0, 1.0)
	var fade = 1.0 - progress
	var draw_color = Color(effect_color.r, effect_color.g, effect_color.b, fade)

	for spark in sparks:
		var start = spark * progress * 0.35
		var end = spark * progress
		draw_line(start, end, draw_color, 1.6 * strength)
		if is_blood:
			draw_circle(end, 1.3 * strength * fade, draw_color)

	if not is_blood:
		draw_circle(Vector2.ZERO, 1.8 * strength * fade, Color(0.9, 0.95, 1.0, fade))
