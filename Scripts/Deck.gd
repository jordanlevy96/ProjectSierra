class_name Deck

var tiles = []
var rng

func load_tile_resources(path):
	var dir = DirAccess.open(path)
	var resources = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".tres"):
				var resource_path = path + file_name
				var resource = load(resource_path)
				if resource != null:
					resources.append(resource)
			file_name = dir.get_next()
		dir.list_dir_end()
	return resources

func initialize_deck(starter_deck, seeded_rng, resource_folder):
	rng = seeded_rng
	var tile_counts = starter_deck.tile_counts
	var tile_data_array = load_tile_resources(resource_folder)
	var tile_data_map = {}

	for data in tile_data_array:
		tile_data_map[data.tile_type] = data

	for tile_type in tile_counts.keys():
		var count = tile_counts[tile_type]
		if tile_type in tile_data_map:
			var tile_data = tile_data_map[tile_type]
			for i in range(count):
				tiles.append(tile_data)

func add_tile(tile_data):
	tiles.append(tile_data)

func remove_tile(tile_data):
	tiles.erase(tile_data)

func get_random_tile():
	if tiles.size() > 0:
		return tiles[rng.randi() % tiles.size()]
	return null
