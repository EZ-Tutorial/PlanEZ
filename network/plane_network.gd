extends CharacterBody3D

# ------speed------
@export var max_speed : float = 10.0
@export var acceleration : float = 2
@export var natural_deceleration : float = 0.7
@export var braking_deceleration : float = 2
var current_speed : float = 0.0

@export var takeoff_speed : float = 2

# ------direction------
# Pitch = nez haut/bas (souris verticale). Roll = inclinaison ailes (souris horizontale). Yaw = tourner gauche/droite (Q/D).
@export var mouse_sensitivity : float = 0.002
@export var pitch_range : float = 1.0
@export var yaw_speed : float = 1.2  # rad/s avec Q et D (réglage fin)
@export var turn_from_bank_factor : float = 0.04  # virage dû au bank : roll * speed * ce facteur → rad/s
const MAX_BANK_RAD := 1.5708  # roll ±90°
var target_yaw : float = 0.0    # Q/D + virage dû au bank
var target_pitch : float = 0.0  # souris Y (tangage)
var target_bank : float = 0.0   # souris X (roulis)

# ------animation------
@export var animation_multiplier : float = 4
@export var max_animation_speed : float = 10.0

# ------gravity------
@export var gravity : float = 198.0

@onready var camera: Camera3D = $Camera3D
@onready var speed_label: Label = $SpeedOverlay/SpeedPanel/SpeedLabel

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	target_yaw = rotation.y
	target_pitch = rotation.x
	target_bank = rotation.z
	
	if is_multiplayer_authority():
		camera.current = true

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	
	if event is InputEventMouseMotion:
		var mouse_x: float = event.relative.x * mouse_sensitivity
		var mouse_y: float = event.relative.y * mouse_sensitivity
		target_pitch -= mouse_y   # souris verticale = tangage (nez haut/bas)
		target_bank -= mouse_x    # souris horizontale = roulis (inclinaison ailes)
		target_pitch = clamp(target_pitch, -pitch_range, pitch_range)
		target_bank = clamp(target_bank, -MAX_BANK_RAD, MAX_BANK_RAD)
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	#------speed------
	if Input.is_physical_key_pressed(KEY_W):
		# -Z local = "devant" en Godot 3D
		current_speed = move_toward(current_speed, max_speed, acceleration * delta)
	elif Input.is_physical_key_pressed(KEY_S):
		current_speed = move_toward(current_speed, 0, braking_deceleration * delta)
	else:
		# Pas de touche = on s'arrête doucement
		current_speed = move_toward(current_speed, 0, natural_deceleration * delta)
	current_speed = clamp(current_speed, 0, max_speed)

	if speed_label:
		speed_label.text = "Speed: %.1f" % current_speed

	#velocity update
	# velocity = -transform.basis.z * current_speed

	#------direction------
	# Yaw manuel (Q/D) pour réglage fin
	if Input.is_physical_key_pressed(KEY_Q) or Input.is_physical_key_pressed(KEY_A):
		target_yaw += yaw_speed * delta
	if Input.is_physical_key_pressed(KEY_D):
		target_yaw -= yaw_speed * delta

	var in_flight: bool = not is_on_floor() or current_speed > takeoff_speed
	if in_flight:
		var turn_rate: float = rotation.z * current_speed * turn_from_bank_factor  # bank left → tourne à gauche
		target_yaw += turn_rate * delta
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * 3.0)
		rotation.x = lerp_angle(rotation.x, target_pitch, delta * 3.0)
		rotation.z = lerp_angle(rotation.z, target_bank, delta * 5.0)
	else:
		rotation.y = lerp_angle(rotation.y, 0, delta)
		rotation.x = lerp_angle(rotation.x, 0, delta)
		rotation.z = lerp_angle(rotation.z, 0, delta)

	# Vitesse = direction du nez × vitesse (inclut le pitch : nez en l'air = montée)
	var forward_direction := -transform.basis.z
	velocity = forward_direction * current_speed

	#------animation------
	var animation_player := $AnimationPlayer
	if animation_player.has_animation("propeller_rotation"):
		animation_player.play("propeller_rotation")
		animation_player.speed_scale = clamp(current_speed, 1, max_animation_speed) * animation_multiplier  # clamp pour que la vitesse reste dans l'intervalle désiré


	#------gravity------
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		# Au sol : ne pas s'enfoncer, mais garder velocity.y si > 0 pour pouvoir décoller
		velocity.y = 0.0

	move_and_slide()

	
