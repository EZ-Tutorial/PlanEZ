extends CharacterBody3D

# Vitesse de l'avion (unités par seconde)
var speed := 10.0

var gravity : float = 9.8


func _physics_process(delta: float) -> void:
	# Si on appuie sur Z (physiquement la touche W sur le clavier)
	# if Input.is_physical_key_pressed(KEY_W):
	# 	# -Z local = "devant" en Godot 3D
	# 	velocity = -transform.basis.z * speed
	# else:
	# 	# Pas de touche = on s'arrête doucement
	# 	velocity = velocity.move_toward(Vector3.ZERO, speed * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
		print("Gravity applied: ", velocity.y)

	# Applique le mouvement
	move_and_slide()
