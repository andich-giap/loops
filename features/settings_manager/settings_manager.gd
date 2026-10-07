class_name SettingsManager
## Manages getting and setting, saving and loading setting files.
##
## Available keys: [br] [code]
## RECENT_PROJECTS_KEY
## [/code]

const RECENT_PROJECTS_KEY: StringName = &"recent_projects"

const USER_PREFERENCES_FILE_PATH: StringName = &"user://user_preferences.json"

const KEY_PATHS: Dictionary[StringName, String] = {
	RECENT_PROJECTS_KEY: USER_PREFERENCES_FILE_PATH,
}
static var files: Array[String] = [ ## A list of all the files that needs to be loaded on startup.
	USER_PREFERENCES_FILE_PATH,
]
static var _key_values: Dictionary[StringName, Dictionary]  = {
	USER_PREFERENCES_FILE_PATH: {
		RECENT_PROJECTS_KEY: [],
	},
}


## Loads all the files that are specified by [member files].
static func load_files() -> void:
	for file: String in files:
		var data_string: String = FileAccess.get_file_as_string(USER_PREFERENCES_FILE_PATH)
		if not data_string:
			var file_access: FileAccess = FileAccess.open(file, FileAccess.WRITE)
			file_access.store_string(JSON.stringify(_key_values[file]))
			file_access.close()
			continue
		var data: Dictionary = JSON.parse_string(data_string)
		_key_values[USER_PREFERENCES_FILE_PATH] = data


## Saves the specified [param file].
static func save(file: String) -> void:
	if not files.has(file):
		return
	var data_string: String = JSON.stringify(_key_values[file])
	var file_access: FileAccess = FileAccess.open(file, FileAccess.WRITE)
	file_access.store_string(data_string)
	file_access.close()


## Saves dedicated settings file by the corresponding key.
static func save_by_key(key: StringName) -> void:
	save(SettingsManager.KEY_PATHS[key])


## Sets the [param value] of the specified [param key].
static func set_value(key: StringName, value: Variant) -> void:
	_key_values[KEY_PATHS[key]][key] = value


## Returns the [param value] of the specified [param key].
static func get_value(key: String) -> Variant:
	return _key_values[KEY_PATHS[key]][key]


## Returns the file path that contains specified [param key].
static func get_file_of_key(key: String) -> String:
	return KEY_PATHS[key]
