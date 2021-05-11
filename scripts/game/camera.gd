class_name CameraController
extends Camera2D

# https://www.gdquest.com/tutorial/godot/2d/camera-zoom/

# Lower cap for the `_zoom_level`.
export var min_zoom := 0.5
# Upper cap for the `_zoom_level`.
export var max_zoom := 2.0
# Controls how much we increase or decrease the `_zoom_level` on every turn of the scroll wheel.
export var zoom_factor := 0.1
# Duration of the zoom's tween animation.
export var zoom_duration := 0.2

# The camera's target zoom level.
var _zoom_level := 1.0 setget _set_zoom_level

# We store a reference to the scene's tween node.
var tween: Tween

func _ready():
	tween = Tween.new()
	add_child(tween)

func _set_zoom_level(value: float) -> void:
	# We limit the value between `min_zoom` and `max_zoom`
	_zoom_level = clamp(value, min_zoom, max_zoom)
	# Then, we ask the tween node to animate the camera's `zoom` property from its current value
	# to the target zoom level.
	tween.interpolate_property(
		self,
		"zoom",
		zoom,
		Vector2(_zoom_level, _zoom_level),
		zoom_duration,
		tween.TRANS_SINE,
		# Easing out means we start fast and slow down as we reach the target value.
		tween.EASE_OUT
	)
	tween.start()

func _unhandled_input(event):
	if event is InputEventMouseButton && event.is_pressed():
		if event.button_index == BUTTON_WHEEL_UP: #.is_action_pressed("zoom_in"):
			# Inside a given class, we need to either write `self._zoom_level = ...` or explicitly
			# call the setter function to use it.
			_set_zoom_level(_zoom_level - zoom_factor)
		if event.button_index == BUTTON_WHEEL_DOWN: #.is_action_pressed("zoom_out"):
			_set_zoom_level(_zoom_level + zoom_factor)
