class_name BotonBracketFlag
extends TextureRect

@onready var button_label : Label = %BotonLabel
@onready var action_label : Label = %ActionLabel # <<-- ESTE ES EL NODO QUE DEBE MOSTRAR LA TECLA
@onready var color_rect: ColorRect = %ColorRect
@onready var icon_rect: TextureRect = %IconRect


# Cambia el texto del label principal
func set_text(new_text: String) -> void:
	button_label.text = new_text

# Función para mostrar el texto de la acción ("Ctrl Derecho", "Shift Derecho", etc.)
func set_small_text(new_text: String) -> void:
	if action_label:
		action_label.text = new_text
		# Si quieres que el texto de la tecla sea más grande que el texto principal:
		# action_label.add_theme_font_size_override("font_size", 16) # Ajusta este valor si es necesario
	else:
		print("Warning: ActionLabel not found in BotonBracketFlag.")

# Función para cambiar el color de fondo
func set_background_color(new_color: Color) -> void:
	if color_rect:
		color_rect.color = new_color

func set_icon(texture: Texture2D) -> void:
	if icon_rect:
		icon_rect.texture = texture
	else:
		print("Warning: IconRect not found in BotonBracketFlag.")

# Cambia el color del texto (opcional)
func set_highlighted(is_selected: bool) -> void:
	if is_selected:
		button_label.add_theme_color_override("font_color", Color.YELLOW)
		if action_label: action_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		button_label.add_theme_color_override("font_color", Color.WHITE)
		if action_label: action_label.add_theme_color_override("font_color", Color.WHITE)
