class_name SoccerQuizScreen
extends QuizGameScreen

func select_theme_mode() -> void:
	var pool = QUESTIONS_SOCCER.duplicate()
	pool.shuffle()
	# GARANTIZA 5 PREGUNTAS
	current_questions_set = pool.slice(0, 5)
	print("⚽ Modo Fútbol Activado (5 Preguntas)")
