extends Area2D

@export_enum("King", "Business") var chest_type: int = 0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var player_inside: bool = false
var is_opening: bool = false

func _ready() -> void:
	if chest_type == 0:
		sprite.sprite_frames = preload("res://assets/animations/king.tres")
	else:
		sprite.sprite_frames = preload("res://assets/animations/business.tres")
	sprite.play("closed")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false

func _process(_delta: float) -> void:
	if player_inside and not is_opening and Input.is_action_just_pressed("deposit"):
		deposit()

func deposit() -> void:
	if is_opening:
		return
	is_opening = true
	if chest_type == 0:
		Economy.deposit_to_king()
	else:
		Economy.deposit_to_business()
	sprite.play("open")
	await sprite.animation_finished
	await get_tree().create_timer(0.3).timeout
	sprite.play("close")
	await sprite.animation_finished
	sprite.play("closed")
	is_opening = false
