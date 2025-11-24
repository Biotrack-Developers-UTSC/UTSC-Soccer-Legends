class_name BracketFlag
extends TextureRect

@onready var border: TextureRect = %Border
@onready var score_label: Label = %ScoreLabel
var tween: Tween

func _ready() -> void:
	modulate = Color(1, 1, 1, 1)
	tween = get_tree().create_tween()
	tween.stop()

func set_as_current_team() -> void:
	border.visible = true
	modulate = Color(1, 1, 1, 1)

func set_as_winner(score: String, is_final_winner: bool = false) -> void:
	score_label.text = score
	score_label.visible = true
	border.visible = false
	modulate = Color(1, 1, 1, 1)

	if is_final_winner:
		start_glow_effect()

func set_as_loser(stage: int = -1) -> void:
	border.visible = false
	score_label.visible = false

	match stage:
		Tournament.Stage.QUARTER_FINALS:
			modulate = Color(0.55, 0.55, 0.55, 1)
		Tournament.Stage.SEMI_FINALS:
			modulate = Color(0.35, 0.35, 0.35, 1)
		Tournament.Stage.FINALS:
			modulate = Color(0.25, 0.25, 0.25, 1)
		_:
			modulate = Color(0.5, 0.5, 0.5, 1)

func start_glow_effect() -> void:
	if tween:
		tween.kill()
	modulate = Color(1.0, 0.95, 0.7, 1) # tono dorado inicial
	tween = get_tree().create_tween()
	tween.set_loops() # loop infinito
	tween.tween_property(self, "modulate", Color(1.0, 0.85, 0.4, 1), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate", Color(1.0, 0.95, 0.7, 1), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
