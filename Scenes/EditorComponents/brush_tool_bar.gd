extends Control
@export_category("Brush state")
@export var current_brush:String = ""
@export var brush_selected:bool = false
@export var custom_brush_string:String = ""
@export var current_brush_name:String = ""

@export_category("Components")
@export var hbox:HBoxContainer
@export var toolsbar:HBoxContainer
@export var MapRules:MapRulesResource

const ERASER_BRUSH = "!ERASE_ACTION"
const TOOL_CUSTOM = "TOOL_CUSTOM"
const TOOL_MOVE = "TOOL_MOVE"
const TOOL_ERASER = "TOOL_ERASER"
@onready var custom_line_edit: LineEdit = $LineEdit  # A LineEdit node for Custom brush input

var move_mode_active: bool = false     # Whether the Move tool is currently selected
var move_source_btn: Button = null     # Button that was first clicked (source)
var move_brush: String = ""             # The emoji/text from the source cell being moved


func _ready() -> void:
	connect_hbox_buttons()
	connect_tool_buttons()
	# Hide custom line_edit initially
	if custom_line_edit:
		custom_line_edit.visible = false
		custom_line_edit.text = ""
		custom_line_edit.connect("text_submitted", Callable(self, "_on_custom_brush_submitted"))

func _on_custom_brush_submitted(text: String) -> void:
	print("Custom brush entered:", text)
	if text != "":
		current_brush = text
		current_brush_name = TOOL_CUSTOM
		brush_selected = true
	else:
		current_brush = ""
		brush_selected = false

	# Hide the input after submission
	if custom_line_edit:
		custom_line_edit.visible = false
		custom_line_edit.text = ""


func connect_hbox_buttons() -> void:
	for btn:Button in hbox.get_children():
		if btn is Button:
			# Disconnect previously connected to avoid duplicate connections (optional safety)
			var cb = Callable(self, "_on_brush_button_pressed")
			
			if btn.pressed.is_connected(cb):
				btn.pressed.disconnect(cb)
			# Connect button pressed signal, bind the button's name as argument
			btn.pressed.connect(Callable(self, "_on_brush_button_pressed").bind(btn.name))

func connect_tool_buttons() -> void:
	for btn:Button in toolsbar.get_children():
		if btn is Button:
			var cb = Callable(self, "_on_brush_button_pressed")
			if btn.pressed.is_connected(cb):
				btn.pressed.disconnect(cb)
			# Connect button pressed signal, bind the button's name as argument
			btn.pressed.connect(Callable(self, "_on_tool_button_pressed").bind(btn.name))



func _on_brush_button_pressed(button_name: String) -> void:
	# When a brush button is pressed, select the brush from MapRules as before:
	print("Brush button pressed:", button_name)
	var map_rules_dict = MapRules.create_dict()
	var key_map = {
		"highwall": "high_walls",
		"highwallbreak": "breakable_high_walls",
		"low_wall": "low_walls",
		"high_doors": "high_doors",
		"enemy": "enemy",
		"civilian": "civilian",
		"dead_enemy": "dead_body",
		"money": "money",
		"water": "water",
		"fog": "fog",
		"upstairs": "upstairs_marker",
		"downstairs": "downstairs_marker",
		# brushes only here; tools handled separately
	}

	if button_name in key_map:
		var dict_key = key_map[button_name]
		if dict_key in map_rules_dict and map_rules_dict[dict_key].size() > 0:
			current_brush = map_rules_dict[dict_key][0]
			brush_selected = true
			current_brush_name = button_name
			print("Current brush set to:", current_brush)
		else:
			current_brush = ""
			brush_selected = false
			current_brush_name = button_name
	else:
		# Unknown brush
		current_brush = ""
		brush_selected = false
		current_brush_name = button_name
	
	# Hide custom input if visible
	if custom_line_edit:
		custom_line_edit.visible = false
		
func _handle_move_click(btn: Button) -> void:
	# First click: if no source selected, pick up the text from this button
	if move_source_btn == null:
		if btn.text.strip_escapes() == "":
			print("Selected cell is empty, cannot move")
			return  # Ignore empty cells

		# Store the source data
		move_source_btn = btn
		move_brush = btn.text

		# Clear the source cell text to simulate "pickup"
		btn.text = ""
		print("Picked up brush:", move_brush, "from cell:", btn.name)

	else:
		# Second click: place the stored brush into this cell
		btn.text = move_brush
		print("Placed brush:", move_brush, "to cell:", btn.name)

		# Reset the move state, ending the move action
		move_source_btn = null
		move_brush = ""
		current_brush_name = ""

func _apply_brush_to_button(btn: Button) -> void:
	if brush_selected and current_brush != "":
		if current_brush == ERASER_BRUSH:
			btn.text = ""
		else:
			btn.text = current_brush

func _on_tool_button_pressed(tool_name: String) -> void:
	print("Tool button pressed:", tool_name)
	match tool_name:
		TOOL_CUSTOM:
			# Show line edit for custom brush input
			if custom_line_edit:
				custom_line_edit.visible = true
				custom_line_edit.grab_focus()

			# Clear current brush selection unless custom input is confirmed
			current_brush = ""
			current_brush_name = tool_name
			brush_selected = false
		
		TOOL_MOVE:
			move_mode_active = true
			move_source_btn = null
			move_brush = ""
			current_brush = ""  # Clear any normal brush to avoid conflict
			current_brush_name = tool_name
			brush_selected = true
			print("Move tool activated: waiting for first click to pick a cell")


		TOOL_ERASER:
			# Select eraser brush
			current_brush = ERASER_BRUSH
			current_brush_name = tool_name
			brush_selected = true
			# Hide custom input if visible
			if custom_line_edit:
				custom_line_edit.visible = false
			print("Eraser selected")

		_:
			print("Unknown tool button pressed:", tool_name)
			current_brush = ""
			current_brush_name = tool_name
			brush_selected = false
