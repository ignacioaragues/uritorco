extends RefCounted

static var pending: = {}
const COUNT: = 3

static func path(slot: int, automatic: bool) -> String:
	return "user://partida_%d_%s.save" % [slot, "auto" if automatic else "manual"]

static func read(slot: int, automatic: bool) -> Dictionary:
	var name: = path(slot, automatic)
	if not FileAccess.file_exists(name): return {}
	var f: = FileAccess.open(name, FileAccess.READ)
	if f == null: return {}
	var data = f.get_var(false)
	if data is Dictionary and data.get("version") == 1 and data.has("state") and data.has("pose"):
		return data
	return {}

static func write(slot: int, automatic: bool, data: Dictionary) -> bool:
	var name: = path(slot, automatic)
	var f: = FileAccess.open(name + ".tmp", FileAccess.WRITE)
	if f == null: return false
	f.store_var(data)
	f.flush()
	var ok: = f.get_error() == OK
	f.close()
	return ok and DirAccess.rename_absolute(name + ".tmp", name) == OK
