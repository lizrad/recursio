extends Object
class_name TextFileToArray


static func load_text_file(file_path: String) -> Array:
	var text_file: File = File.new()
	var _error = text_file.open(file_path, File.READ)
	var data := []
	while not text_file.eof_reached():
		var line: String = text_file.get_line()
		data.append(line)
	text_file.close()
	return data

