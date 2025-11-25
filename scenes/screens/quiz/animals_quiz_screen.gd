class_name AnimalsQuizScreen
extends QuizGameScreen

func select_theme_mode() -> void:
	var pool = QUESTIONS_ANIMALS.duplicate()
	pool.shuffle()
	# GARANTIZA 5 PREGUNTAS
	current_questions_set = pool.slice(0, 5)
	print("🐾 Modo Animales Activado (5 Preguntas)")
