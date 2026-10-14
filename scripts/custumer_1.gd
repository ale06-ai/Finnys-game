extends CharacterBody2D

signal paid(amount)
signal patience_changed(current, maximum)
signal left_without_paying

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var patience_bar: ProgressBar = $PatienceBar
@onready var time_label: Label = $PatienceBar/TimeLabel

const WITCH = preload("res://assets/animations/witch.tres")
const SKELETON = preload("res://assets/animations/skeleton.tres")
const GOLEM = preload("res://assets/animations/golem.tres")

enum State { ARRIVING, SHOWING, WAITING, LEAVING, UPSET }
@export_enum("Witch", "Skeleton", "Golem") var customer_type: int = 0
@export var speed: float = 100.0
@export var acceleration: float = 650.0
@export var price: int = 100
@export var max_patience: float = 10.0
@export var wait_point: Vector2 = Vector2(500, 300)

var current_state = State.ARRIVING
var patience: float
var spawn_position: Vector2
var finny: Node2D = null

func _ready() -> void:
	add_to_group("customer")
	match customer_type:
		0: animated_sprite.sprite_frames = WITCH
		1: animated_sprite.sprite_frames = SKELETON
		2: animated_sprite.sprite_frames = GOLEM
	spawn_position = global_position
	patience = max_patience
	patience_bar.max_value = max_patience
	patience_bar.value = max_patience
	patience_bar.visible = false
	time_label.text = str(ceili(max_patience)) + "s"
	animated_sprite.play("idle")

func _physics_process(delta: float) -> void:
	match current_state:
		State.ARRIVING:
			arriving(delta)
		State.WAITING:
			waiting(delta)
		State.LEAVING:
			leaving(delta)
		State.SHOWING, State.UPSET:
			velocity = Vector2.ZERO
	move_and_slide()

func move_towards(target: Vector2, delta: float) -> bool:
	var distance := global_position.distance_to(target)
	if distance < 4.0:
		velocity = Vector2.ZERO
		return true
	var direction := global_position.direction_to(target)
	var arrival_speed := minf(speed, distance * 6.0)
	velocity = velocity.move_toward(direction * arrival_speed, acceleration * delta)
	animated_sprite.speed_scale = clampf(velocity.length() / speed, 0.65, 1.0)
	animated_sprite.play("costumer1_walk")
	if absf(direction.x) > 0.1:
		animated_sprite.flip_h = direction.x < 0
	return false

func arriving(delta: float) -> void:
	if move_towards(wait_point, delta):
		current_state = State.WAITING
		patience_bar.visible = true
		animated_sprite.speed_scale = 1.0
		animated_sprite.play("idle")

func waiting(delta: float) -> void:
	velocity = Vector2.ZERO
	patience = maxf(0.0, patience - delta)
	patience_bar.value = patience
	time_label.text = str(ceili(patience)) + "s"
	patience_changed.emit(patience, max_patience)
	if patience <= 0.0:
		leave_angry()
	elif is_instance_valid(finny) and not finny.is_doing_show and Input.is_action_just_pressed("ui_accept"):
		start_show()

func start_show() -> void:
	if current_state != State.WAITING or not is_instance_valid(finny):
		return
	var performer = finny
	if performer.is_doing_show:
		return
	current_state = State.SHOWING
	patience_bar.visible = false
	velocity = Vector2.ZERO
	animated_sprite.speed_scale = 1.0
	animated_sprite.play("costumer1_attack")
	await performer.do_show()
	Economy.earn(price)
	paid.emit(price)
	current_state = State.LEAVING

func leave_angry() -> void:
	current_state = State.UPSET
	velocity = Vector2.ZERO
	patience_bar.visible = false
	left_without_paying.emit()
	if customer_type != 0:
		animated_sprite.speed_scale = 1.0
		animated_sprite.play("upset")
		await animated_sprite.animation_finished
		animated_sprite.play("recover")
		await animated_sprite.animation_finished
	current_state = State.LEAVING

func leaving(delta: float) -> void:
	if move_towards(spawn_position, delta):
		queue_free()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		finny = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == finny:
		finny = null
