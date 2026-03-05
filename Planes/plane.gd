extends CharacterBody3D

# Vitesse de l'avion (unités par seconde) — en float pour que delta s'accumule
var max_speed : float = 100.0
var current_speed : float = 0.0
var acceleration : float = 20.0
var deceleration : float = 10.0

var animation_multiplier : float = 4
var max_animation_speed : float = 10.0

# Gravité forte pour chute nette (ne pas dépendre de is_on_floor)
var gravity : float = 198.0


func _physics_process(delta: float) -> void:



	# Si on appuie sur Z (physiquement la touche W sur le clavier)
	if Input.is_physical_key_pressed(KEY_W):
		# -Z local = "devant" en Godot 3D
		current_speed += acceleration * delta
		current_speed = clamp(current_speed, 0, max_speed)
	else:
		# Pas de touche = on s'arrête doucement
		current_speed -= deceleration * delta
		current_speed = clamp(current_speed, 0, max_speed)

	# Mettre à jour la vélocité avant l'affichage pour que le déplacement soit effectif
	velocity = -transform.basis.z * current_speed

	print("Current speed: ", current_speed)

	# Vitesse de l'animation de l'hélice = current_speed (plus on va vite, plus l'hélice tourne)
	var animation_player := $AnimationPlayer
	if animation_player.has_animation("propeller_rotation"):
		animation_player.play("propeller_rotation")
		animation_player.speed_scale = clamp(current_speed, 1, max_animation_speed) * animation_multiplier  # clamp pour que la vitesse reste dans l'intervalle désiré

	# gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Applique le mouvement
	move_and_slide()
