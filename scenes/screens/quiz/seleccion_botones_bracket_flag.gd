class_name SeleccionBotonBracketFlag
extends TextureRect

@onready var seleccion_button_label: Label = %SeleccionBotonesLabel
@onready var small_text_label: Label = %SmallTextLabel
@onready var icon_rect: TextureRect = %IconRect
@onready var color_rect: ColorRect = %ColorRect

# Cambia el texto del label principal
func set_text(new_text: String) -> void:
	if seleccion_button_label:
		seleccion_button_label.text = new_text

# FUNCIÓN AÑADIDA PARA MOSTRAR EL TEXTO PEQUEÑO
func set_small_text(new_text: String) -> void:
	if small_text_label:
		small_text_label.text = new_text
	else:
		print("Warning: SmallTextLabel not found in SeleccionBotonBracketFlag.")

# Cambia el color del texto según si está seleccionado o no
func set_highlighted(is_selected: bool) -> void:
	if not seleccion_button_label:
		return
	if is_selected:
		seleccion_button_label.add_theme_color_override("font_color", Color.YELLOW)
		if small_text_label: small_text_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		seleccion_button_label.add_theme_color_override("font_color", Color.WHITE)
		if small_text_label: small_text_label.add_theme_color_override("font_color", Color.WHITE)

# Cambia el ícono mostrado
func set_icon(texture: Texture2D) -> void:
	if icon_rect and texture:
		icon_rect.texture = texture
	# Aseguramos que el IconRect esté visible si se asigna una textura
	if icon_rect:
		icon_rect.visible = texture != null

# Cambia el color del fondo
func set_background_color(new_color: Color) -> void:
	if color_rect:
		color_rect.color = new_color
