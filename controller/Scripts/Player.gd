extends CharacterBody3D

signal health_changed(health_value)

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.8
const SENSITIVITY = 0.0025
const AIR_ACCELERATION = 5.0

#bob variables
const BOB_FREQ = 2.4
const BOB_AMP = 0.06
var t_bob = 0.0

#fov variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.0
var mouse_momentum: float = 0.0
var gravity = 9.8
var adjusted_gravity = gravity * 0.9

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var animPlayer = $"Head/Camera3D/USP45 By BillyTheKid/AnimationPlayer2"
@onready var raycast = $Head/Camera3D/RayCast3D

var health = 5

func _process(delta):
	var speed = abs(velocity.x)  # Get the absolute speed (ignoring direction)
	var formatted_speed = speed
	$"Head/Camera3D/CanvasLayer/ColorRect/Velocity Counter".text = str(formatted_speed)
	
func _enter_tree():
	set_multiplayer_authority(str(name).to_int())
	
func _ready():
	if not is_multiplayer_authority(): return
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	camera.current = true

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)
	
	if Input.is_action_just_pressed("shoot"):
		play_shoot_effects.rpc()
		if raycast.is_colliding():
			var hit_player = raycast.get_collider()
			hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())
		
	if Input.is_action_just_pressed("quickMelee") and animPlayer.current_animation != "h2_skeleton|ss2":
		play_quickMelee_effects.rpc()
	
	if Input.is_action_just_pressed("reload") and animPlayer.current_animation != "h2_skeleton|reload":
		play_reload_effects.rpc()


func _physics_process(delta):
	if not is_multiplayer_authority(): return
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= adjusted_gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		
		velocity.y = JUMP_VELOCITY
	
	# Handle Sprint.
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	#animations
	if animPlayer.current_animation == "h2_skeleton|shoot1" or animPlayer.current_animation == "h2_skeleton|ss2" or animPlayer.current_animation == "h2_skeleton|reload":
		pass
	elif is_on_floor():
		animPlayer.play("h2_skeleton|idle")
	
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()

@rpc("call_local")
func play_shoot_effects():
	animPlayer.stop()
	animPlayer.play("h2_skeleton|shoot1")
	
@rpc("call_local")
func play_reload_effects():
	animPlayer.stop()
	animPlayer.play("h2_skeleton|reload")

@rpc("call_local")
func play_quickMelee_effects():
	animPlayer.stop()
	animPlayer.play("h2_skeleton|ss2")

@rpc("any_peer")
func receive_damage():
	health -= 1
	if health <= 0:
		health = 3
		position = Vector3.ZERO
	health_changed.emit(health)

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
