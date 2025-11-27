class_name MobileControls
extends CanvasLayer

# 🌟 Señal para enviar el vector de movimiento al personaje
signal movement_vector_changed(direction_vector)

# 🕹️ Diccionario para rastrear el estado de cada dirección
var active_directions: Dictionary = {
	"up": false,
	"down": false,
	"left": false,
	"right": false
}

func _ready() -> void:
	# Opcional: Si necesitas que los botones sean semitransparentes
	for child in get_children():
		if child is TouchScreenButton:
			child.modulate = Color(1, 1, 1, 0.6)
			
			# Conecta las señales 'pressed' y 'released' de cada botón
			# Los nombres de los nodos deben coincidir (Button_UP, Button_DOWN, etc.)
			if child.name == "Button_UP":
				child.connect("pressed", Callable(self, "_on_button_pressed").bind("up"))
				child.connect("released", Callable(self, "_on_button_released").bind("up"))
			elif child.name == "Button_DOWN":
				child.connect("pressed", Callable(self, "_on_button_pressed").bind("down"))
				child.connect("released", Callable(self, "_on_button_released").bind("down"))
			elif child.name == "Button_LEFT":
				child.connect("pressed", Callable(self, "_on_button_pressed").bind("left"))
				child.connect("released", Callable(self, "_on_button_released").bind("left"))
			elif child.name == "Button_RIGHT":
				child.connect("pressed", Callable(self, "_on_button_pressed").bind("right"))
				child.connect("released", Callable(self, "_on_button_released").bind("right"))

# 🟢 Función que se llama cuando un botón táctil se presiona
func _on_button_pressed(direction: String) -> void:
	active_directions[direction] = true
	_calculate_movement_vector()

# 🔴 Función que se llama cuando un botón táctil se suelta
func _on_button_released(direction: String) -> void:
	active_directions[direction] = false
	_calculate_movement_vector()

# 📐 Función principal para calcular el vector de movimiento de 8 direcciones
func _calculate_movement_vector() -> void:
	var direction_vector: Vector2 = Vector2.ZERO
	
	if active_directions.up:
		direction_vector.y -= 1
	if active_directions.down:
		direction_vector.y += 1
	if active_directions.left:
		direction_vector.x -= 1
	if active_directions.right:
		direction_vector.x += 1
		
	# Normaliza el vector para que la diagonal no sea más rápida
	if direction_vector.length_squared() > 0:
		direction_vector = direction_vector.normalized()
		
	# Emitir la señal con el vector calculado
	movement_vector_changed.emit(direction_vector)
