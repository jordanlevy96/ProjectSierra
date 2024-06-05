var tiles = []

func add_tile(tile_data):
    tiles.append(tile_data)

func remove_tile(tile_data):
    tiles.erase(tile_data)

func get_random_tile():
    if tiles.size() > 0:
        return tiles[randi() % tiles.size()]
    return null
    