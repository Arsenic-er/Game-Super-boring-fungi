class_name SaveStore
extends RefCounted


static func temp_path(base_path: String) -> String:
	return base_path + ".tmp"


static func backup_path(base_path: String) -> String:
	return base_path + ".bak"


static func _read_candidate(path: String, validator: Callable) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var payload := file.get_as_text()
	file.close()
	var data = validator.call(payload)
	if not data is Dictionary or data.is_empty():
		return {}
	return {
		"path": path,
		"payload": payload,
		"data": data,
		"saved_at": float(data.get("saved_at", 0.0)),
	}


static func inspect(base_path: String, validator: Callable) -> Dictionary:
	var primary := _read_candidate(base_path, validator)
	if not primary.is_empty():
		return primary
	var temporary := _read_candidate(temp_path(base_path), validator)
	var backup := _read_candidate(backup_path(base_path), validator)
	if temporary.is_empty():
		return backup
	if backup.is_empty():
		return temporary
	if float(temporary.get("saved_at", 0.0)) >= float(backup.get("saved_at", 0.0)):
		return temporary
	return backup


static func has_recoverable_save(base_path: String, validator: Callable) -> bool:
	return not inspect(base_path, validator).is_empty()


static func _remove_if_present(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


static func _write_verified(path: String, payload: String, validator: Callable) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	var stored := file.store_string(payload)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if not stored or write_error != OK:
		return false
	var verified := _read_candidate(path, validator)
	return not verified.is_empty() and String(verified.get("payload", "")) == payload


static func commit(base_path: String, payload: String, validator: Callable) -> bool:
	var temporary_path := temp_path(base_path)
	var backup_path_value := backup_path(base_path)
	var backup_temporary_path := backup_path_value + ".tmp"
	_remove_if_present(temporary_path)
	_remove_if_present(backup_temporary_path)
	if not _write_verified(temporary_path, payload, validator):
		_remove_if_present(temporary_path)
		return false

	var current := _read_candidate(base_path, validator)
	if not current.is_empty():
		var copy_error := DirAccess.copy_absolute(base_path, backup_temporary_path)
		var copied := _read_candidate(backup_temporary_path, validator)
		if copy_error != OK or copied.is_empty() or String(copied.get("payload", "")) != String(current.get("payload", "")):
			_remove_if_present(temporary_path)
			_remove_if_present(backup_temporary_path)
			return false
		_remove_if_present(backup_path_value)
		if DirAccess.rename_absolute(backup_temporary_path, backup_path_value) != OK:
			_remove_if_present(temporary_path)
			_remove_if_present(backup_temporary_path)
			return false

	if DirAccess.rename_absolute(temporary_path, base_path) != OK:
		_remove_if_present(temporary_path)
		return false
	var committed := _read_candidate(base_path, validator)
	return not committed.is_empty() and String(committed.get("payload", "")) == payload


static func remove_slot(base_path: String) -> void:
	_remove_if_present(base_path)
	_remove_if_present(temp_path(base_path))
	_remove_if_present(backup_path(base_path))
	_remove_if_present(backup_path(base_path) + ".tmp")
