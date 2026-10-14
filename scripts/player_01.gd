extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var speed: float = 200.0
@export var acceleration: float = 1400.0
@export var friction: float = 1800.0

var is_doing_show: bool = false

func _ready() -> void:
	add_to_group("player")
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	if is_doing_show:
		velocity = Vector2.ZERO
		return

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var change := friction if direction == Vector2.ZERO else acceleration
	velocity = velocity.move_toward(direction * speed, change * delta)
	move_and_slide()

	if absf(direction.x) > 0.1:
		sprite.flip_h = direction.x < 0
	animate_walk()

func animate_walk() -> void:
	if velocity.length() > 8.0:
		sprite.speed_scale = clampf(velocity.length() / speed, 0.65, 1.0)
		sprite.play("walk")
	else:
		sprite.speed_scale = 1.0
		sprite.play("idle")

func do_show() -> void:
	if is_doing_show:
		return
	is_doing_show = true
	velocity = Vector2.ZERO
	sprite.speed_scale = 1.0
	sprite.play("show")
	await sprite.animation_finished
	is_doing_show = false
	sprite.play("idle")

func take_damage(_amount: int) -> void:
	pass
