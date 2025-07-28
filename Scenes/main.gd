extends Control
@export_category("Key binds")
@export var LOAD_DIALOGUE:String = "load_map_dialog"
@export var NEW_MAP:String = "create_blank_map"
@export var SAVE_MAP:String = "save_map_dialog"

@export_category("Components")
@export var EditorSquare:Control

func _process(delta: float) -> void:
	if Input.is_action_just_released(LOAD_DIALOGUE):
		EditorSquare.load_dialog()
	elif Input.is_action_just_released(NEW_MAP):
		EditorSquare.new_map_dialog()
	elif Input.is_action_just_released(SAVE_MAP):
		EditorSquare.save_dialog_opt()
