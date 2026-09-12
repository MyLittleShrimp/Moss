extends RefCounted
const IDS = ["herb", "rice", "mushroom", "pumpkin", "herb_box", "rice_ball", "mushroom_box", "feast", "stone", "glowstone", "teacup", "oldmap", "chime", "goldseed", "silk", "lotus", "charm", "starbell", "ceramic", "blueeye", "plant", "flower", "book", "broom"]
const NEW_IDS = ["corn", "carrot", "potato", "strawberry", "corn_ball", "veggie_box", "potato_box", "berry_snack", "tiedye", "cloudshawl", "coffeecup", "iris", "basalt", "auroraglass", "parcel", "tiecloth"]
static var cache: Dictionary = {}
static var matte: ShaderMaterial

static func texture(id: String) -> Texture2D:
	if id == "unknown": return load("res://assets/unknown.svg")
	if id == "pariscup": return texture("coffeecup")
	if id == "stonelamp": return texture("basalt")
	if id in NEW_IDS:
		if cache.has(id): return cache[id]
		var atlas = load("res://assets/items-g9.png")
		var index = NEW_IDS.find(id)
		var cell = atlas.get_width() / 4
		var result = AtlasTexture.new()
		result.atlas = atlas
		result.region = Rect2((index % 4) * cell + 10, (index / 4) * cell + 10, cell - 20, cell - 20)
		result.filter_clip = true
		cache[id] = result
		return result
	if id in ["woven", "meadow", "sunset"]: return rug(id)
	if cache.has(id): return cache[id]
	if id in ["lantern", "bunting"]:
		cache[id] = native_decor(id)
		return cache[id]
	var index = IDS.find(id)
	if index < 0: index = IDS.find("book")
	var result = AtlasTexture.new()
	result.atlas = load("res://assets/items-g6.png")
	result.region = Rect2((index % 6) * 256 + 8, (index / 6) * 256 + 16, 240, 222)
	result.filter_clip = true
	cache[id] = result
	return result

static func native_decor(id: String) -> Texture2D:
	# These extend the existing code-drawn lamp/flags and match their room silhouettes.
	var image = Image.create(96, 96, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in range(96):
		for x in range(96):
			var color = Color.TRANSPARENT
			if id == "lantern":
				if abs(x - 48) < 2 and y > 10 and y < 35: color = Color("80674b")
				if pow((x - 48) / 22.0, 2) + pow((y - 54) / 27.0, 2) < 1: color = Color("edc16e")
				if x > 27 and x < 69 and (abs(y - 32) < 3 or abs(y - 76) < 3): color = Color("80674b")
			else:
				if y > 25 and y < 29 and x > 5 and x < 91: color = Color("987e5e")
				for i in range(3):
					var cx = 18 + i * 30
					if y >= 29 and y <= 64 and abs(x - cx) < (65 - y) * 0.39: color = Color("96ae7d") if i != 1 else Color("d4a0a3")
			if color.a > 0: image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)

static func rug(id: String) -> Texture2D:
	var index = ["woven", "meadow", "sunset"].find(id)
	var result = AtlasTexture.new()
	result.atlas = load("res://assets/rugs-g6.png")
	var cell = result.atlas.get_width() / 2
	result.region = Rect2((index % 2) * cell, (index / 2) * cell, cell, cell)
	result.filter_clip = true
	return result

static func postcard(id: String) -> Texture2D:
	if id in ["dali", "paris", "iceland"]: return load("res://assets/postcards/" + id + ".png")
	var index = GameContent.ROUTES.keys().find(id)
	var result = AtlasTexture.new()
	result.atlas = load("res://assets/postcards.png")
	result.region = Rect2((index % 3) * 512, (index / 3) * 512, 512, 512)
	result.filter_clip = true
	return result

static func matte_material() -> ShaderMaterial:
	if matte != null: return matte
	# Runtime white-matte removal only; source PNG and original colors are preserved.
	var shader = Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); float white=min(c.r,min(c.g,c.b)); c.a*=1.0-smoothstep(0.94,0.995,white); COLOR=c; }"
	var material = ShaderMaterial.new()
	material.shader = shader
	matte = material
	return matte
