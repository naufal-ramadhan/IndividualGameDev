extends Area2D
class_name BaseItem # Jadikan ini class agar bisa dikenali oleh skrip lain

@onready var sprite = $Sprite2D

func _ready():
	body_entered.connect(_on_body_entered)
	
	var tween = create_tween().set_loops()
	
	tween.tween_property(sprite, "position:y", -15.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "position:y", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	await get_tree().create_timer(10.0).timeout
	queue_free()

func _on_body_entered(body):
	if body.name == "Player":
		apply_effect(body) 
		
		if body.has_method("update_ui"):
			body.update_ui()
		queue_free()

# ==========================================
# FUNGSI VIRTUAL: Akan ditimpa (override) oleh skrip anak
# ==========================================
func apply_effect(player: Node2D):
	# Biarkan kosong (pass) di kelas induk ini
	pass
