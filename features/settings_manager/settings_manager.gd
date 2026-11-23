class_name SettingsManager
## Manages getting and setting, saving and loading setting files.
##
## Available keys: [br] [code]
## RECENT_PROJECTS_KEY
## [/code]

const RECENT_PROJECTS_KEY: StringName = &"recent_projects"
const LINE_STYLE_KEY: StringName = &"line_style"

const USER_PREFERENCES_FILE_PATH: StringName = &"user://user_preferences.json"
const RESOURCES_FILE_PATH: StringName = &"user://resources.json"
const THEME: Theme = preload("uid://dmxt5luifu1kc")

const KEY_PATHS: Dictionary[StringName, String] = {
	RECENT_PROJECTS_KEY: USER_PREFERENCES_FILE_PATH,
	
	LINE_STYLE_KEY: RESOURCES_FILE_PATH,
}

const RESOURCE_COLLECTIONS: Dictionary[StringName, Array] = {
	"LineStyle": [
		preload("uid://016mfaf1yryg"),
		preload("uid://c2nr3xccfof7p"),
		preload("uid://c2lsqkerrr4o5"),
		preload("uid://x7up8gjmus1e"),
		preload("uid://hgvyr7nc5bfq"),
	],
}

static var files: Array[String] = [ ## A list of all the files that needs to be loaded on startup.
	USER_PREFERENCES_FILE_PATH,
]
static var _key_values: Dictionary[StringName, Dictionary]  = {
	USER_PREFERENCES_FILE_PATH: {
		RECENT_PROJECTS_KEY: [],
	},
	RESOURCES_FILE_PATH: RESOURCE_COLLECTIONS
}
static var system_fonts: Array[Font]


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
	
	load_system_fonts()


static func load_system_fonts() -> void:
	system_fonts.clear()
	for font: String in OS.get_system_fonts():
		var system_font: SystemFont = SystemFont.new()
		system_font.font_names = [font]
		system_font.oversampling = 5.0
		system_font.multichannel_signed_distance_field = true
		system_fonts.append(system_font)
	replace_theme_fonts_to_system_fonts()


static func replace_theme_fonts_to_system_fonts() -> void:
	for font_type: StringName in THEME.get_font_type_list():
		for font_name: String in THEME.get_font_list(font_type):
			var font: Font = THEME.get_font(font_name, font_type)
			if font is not SystemFont:
				continue
			var system_font: SystemFont = font
			var cached_system_font: SystemFont = get_system_font(system_font.font_names[0])
			if not cached_system_font:
				continue
			THEME.set_font(font_name, font_type, cached_system_font)


static func get_system_font(font_name: StringName) -> SystemFont:
	if system_fonts.is_empty():
		load_system_fonts()
	for system_font: SystemFont in system_fonts:
		if system_font.font_names[0] == font_name:
			return system_font
	return null


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


static func get_resources(_class_name: StringName) -> Array[Resource]:
	var resources: Array[Resource]
	if RESOURCE_COLLECTIONS.has(_class_name):
		resources.append_array(RESOURCE_COLLECTIONS[_class_name])
	if _class_name == &"Font":
		resources.append_array(system_fonts)
	return resources
