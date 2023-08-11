extends CharacterBody3D

var jumpImpulse = 2.0
var gravity = -5.0
var groundAcceleration = 30.0
var groundSpeedLimit = 3.0
var airAcceleration = 500.0
var airSpeedLimit = 0.5
var groundFriction = 0.9

var mouseSensitivity = 0.025

var restartTransform
var restartVelocity

func _ready():
	restartTransform = self.global_transform
	restartVelocity = self.velocity
	pass # Replace with function body.

func _physics_process(delta):
	# Apply gravity, jumping, and ground friction to velocity
	velocity.y += gravity * delta
	if is_on_floor():
		# By using is_action_pressed() rather than is_action_just_pressed()
		# we get automatic bunny hopping.
		if Input.is_action_pressed("jump"):
			velocity.y = jumpImpulse
		else:
			velocity *= groundFriction
	
	# Compute X/Z axis strafe vector from WASD inputs
	var basis = $YawAxis/Camera.get_global_transform().basis
	var strafeDir = Vector3(0, 0, 0)
	if Input.is_action_pressed("up"):
		strafeDir -= basis.z
	if Input.is_action_pressed("down"):
		strafeDir += basis.z
	if Input.is_action_pressed("left"):
		strafeDir -= basis.x
	if Input.is_action_pressed("right"):
		strafeDir += basis.x
	strafeDir.y = 0
	strafeDir = strafeDir.normalized()
	
	# Figure out which strafe force and speed limit applies
	var strafeAccel = groundAcceleration if is_on_floor() else airAcceleration
	var speedLimit = groundSpeedLimit if is_on_floor() else airSpeedLimit
	
	# Project current velocity onto the strafe direction, and compute a capped
	# acceleration such that *projected* speed will remain within the limit.
	var currentSpeed = strafeDir.dot(velocity)
	var accel = strafeAccel * delta
	accel = max(0, min(accel, speedLimit - currentSpeed))
	
	# Apply strafe acceleration to velocity and then integrate motion
	velocity += strafeDir * accel
	move_and_slide()
	
	if Input.is_action_pressed("move_fast"):
		velocity = Vector3.ZERO
	if Input.is_action_just_released("move_fast"):
		velocity = -30 * basis.z
	
	if Input.is_action_just_pressed("checkpoint"):
		print("Saving Checkpoint: %s / %s" % [self.translation, self.velocity])
		restartTransform = self.global_transform
		restartVelocity = self.velocity	
	
	if Input.is_action_just_pressed("restart"):
		self.global_transform = restartTransform
		self.velocity = restartVelocity
	
	pass

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		$YawAxis.rotate_x(deg_to_rad(event.relative.y * mouseSensitivity * -1))
		self.rotate_y(deg_to_rad(event.relative.x * mouseSensitivity * -1))

		# Clamp yaw to [-89, 89] degrees so you can't flip over
		var yaw = $YawAxis.rotation_degrees.x
		$YawAxis.rotation_degrees.x = clamp(yaw, -89, 89)    
