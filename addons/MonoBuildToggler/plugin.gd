@tool
extends EditorPlugin

const DisabledExt = "disabled"

var scene: Node
var solution_path: String
var solution_path_hidden: String
var csproj_path: String
var csproj_path_hidden: String

var toggler = preload("res://addons/MonoBuildToggler/toggler.tscn")


func _enter_tree():
	var proj_name := ProjectSettings.get("application/config/name")
	solution_path = "res://" + proj_name + ".sln"
	solution_path_hidden = "res://" + proj_name + ".sln." + DisabledExt
	
	csproj_path = "res://" + proj_name + ".csproj"
	csproj_path_hidden = "res://" + proj_name + ".csproj." + DisabledExt
	
	scene = toggler.instantiate() as MonoBuildToggler
	scene.on_toggled.connect(_on_mono_toggled)
	
	add_control_to_container(CONTAINER_TOOLBAR, scene)
	
	# Set toggle button initial status	
	if FileAccess.file_exists(solution_path):
		scene.set_enabled(true)
	elif FileAccess.file_exists(solution_path_hidden):
		scene.set_enabled(false)
	else:
		push_error("No solution file exists at path '" + solution_path + "' or '" + solution_path_hidden + "'")


func _on_mono_toggled(enabled: bool):
	if not enabled:
		if FileAccess.file_exists(solution_path):
			# Hide solution file			
			var error: Error = DirAccess.rename_absolute(solution_path, solution_path_hidden)
			if error != OK:
				push_error("An error occurred while renaming the solution file: " + str(error))
				return
			DirAccess.rename_absolute(csproj_path, csproj_path_hidden)
		elif not FileAccess.file_exists(solution_path_hidden):
			push_error("No solution file exists at path '" + solution_path + "' or '" + solution_path_hidden + "'")
	else:
		if FileAccess.file_exists(solution_path_hidden):
			# Show solution file
			var error: Error = DirAccess.rename_absolute(solution_path_hidden, solution_path)
			if error != OK:
				push_error("An error occurred while renaming the solution file: " + str(error))
				return				
			DirAccess.rename_absolute(csproj_path_hidden, csproj_path)
		elif not FileAccess.file_exists(solution_path):
			push_error("No solution file exists at path '" + solution_path + "' or '" + solution_path_hidden + "'")


func _exit_tree():
	remove_control_from_container(CONTAINER_TOOLBAR, scene)

	# Enable solution if disabled
	if solution_path_hidden and FileAccess.file_exists(solution_path_hidden):
		DirAccess.rename_absolute(solution_path_hidden, solution_path)
		
	if csproj_path_hidden and FileAccess.file_exists(csproj_path_hidden):
		DirAccess.rename_absolute(csproj_path_hidden, csproj_path)
