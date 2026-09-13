class_name GameContent
extends RefCounted

const CROPS = {
	"herb": {"name": "香草", "seconds": 30, "yield": 2},
	"rice": {"name": "稻米", "seconds": 90, "yield": 3},
	"mushroom": {"name": "蘑菇", "seconds": 180, "yield": 2},
	"pumpkin": {"name": "南瓜", "seconds": 300, "yield": 2},
	"corn": {"name": "玉米", "seconds": 480, "yield": 4},
	"carrot": {"name": "胡萝卜", "seconds": 720, "yield": 3},
	"potato": {"name": "土豆", "seconds": 1080, "yield": 4},
	"strawberry": {"name": "草莓", "seconds": 1500, "yield": 2}}
const FOODS = {
	"herb_box": {"name": "香草便当", "recipe": {"herb": 2}, "nutrition": 1, "tier": 1},
	"rice_ball": {"name": "田园饭团", "recipe": {"rice": 1, "herb": 2}, "nutrition": 3, "tier": 1},
	"mushroom_box": {"name": "蘑菇双层便当", "recipe": {"rice": 1, "mushroom": 1}, "nutrition": 5, "tier": 2},
	"feast": {"name": "南瓜远行餐", "recipe": {"rice": 2, "pumpkin": 1, "mushroom": 1}, "nutrition": 8, "tier": 3},
	"corn_ball": {"name": "玉米饭团", "recipe": {"corn": 4, "rice": 1}, "nutrition": 5, "tier": 2},
	"veggie_box": {"name": "田园蔬菜便当", "recipe": {"carrot": 2, "mushroom": 1, "rice": 2}, "nutrition": 9, "tier": 3},
	"potato_box": {"name": "烤土豆远行盒", "recipe": {"potato": 2, "pumpkin": 1, "herb": 1}, "nutrition": 12, "tier": 4},
	"berry_snack": {"name": "草莓点心包", "recipe": {"strawberry": 1, "rice": 1}, "nutrition": 2, "tier": 1, "snack": true}}
const ROUTES = {
	"creek": {"name": "溪谷", "min": 300, "max": 600, "supply": 1, "tier": 1, "hint": "附近 · 一小会儿", "common": "stone", "rare": "glowstone", "chance": 0.15},
	"market": {"name": "林间集市", "min": 600, "max": 1200, "supply": 3, "tier": 1, "hint": "邻镇 · 慢慢逛", "common": "teacup", "rare": "oldmap", "chance": 0.12},
	"hill": {"name": "山坡", "min": 1200, "max": 2400, "supply": 5, "tier": 1, "hint": "郊外 · 悠长午后", "common": "chime", "rare": "goldseed", "chance": 0.10},
	"hangzhou": {"name": "杭州·西湖", "min": 3600, "max": 7200, "supply": 10, "tier": 2, "hint": "国内远游 · 几个钟头", "common": "silk", "rare": "lotus", "chance": 0.08},
	"tokyo": {"name": "东京", "min": 10800, "max": 21600, "supply": 18, "tier": 2, "hint": "海外 · 半日光景", "common": "charm", "rare": "starbell", "chance": 0.05},
	"istanbul": {"name": "伊斯坦布尔", "min": 21600, "max": 43200, "supply": 32, "tier": 3, "hint": "跨洲 · 漫长远行", "common": "ceramic", "rare": "blueeye", "chance": 0.03},
	"dali": {"name": "大理·洱海", "min": 2400, "max": 5400, "supply": 8, "tier": 2, "hint": "湖畔慢游 · 悠长午后", "common": "tiedye", "rare": "cloudshawl", "chance": 0.10},
	"paris": {"name": "巴黎", "min": 28800, "max": 57600, "supply": 40, "tier": 3, "hint": "街角与河岸 · 一日漫游", "common": "coffeecup", "rare": "iris", "chance": 0.07},
	"iceland": {"name": "冰岛·雷克雅未克", "min": 43200, "max": 86400, "supply": 48, "tier": 4, "hint": "极光之旅 · 慢慢等它回来", "common": "basalt", "rare": "auroraglass", "chance": 0.05}}
const ITEMS = {
	"stone": {"name": "溪边青石", "value": 2}, "glowstone": {"name": "微光萤石", "value": 12},
	"teacup": {"name": "木纹茶杯", "value": 3}, "oldmap": {"name": "蜗牛旧地图", "value": 16},
	"chime": {"name": "山风铃", "value": 4}, "goldseed": {"name": "金色蒲公英", "value": 20},
	"silk": {"name": "湖色丝带", "value": 6}, "lotus": {"name": "月下莲纹扣", "value": 28},
	"charm": {"name": "樱花御守", "value": 9}, "starbell": {"name": "星夜铃", "value": 40},
	"ceramic": {"name": "蓝纹陶片", "value": 12}, "blueeye": {"name": "海峡蓝眼石", "value": 60},
	"tiedye": {"name": "洱海扎染布", "value": 5}, "cloudshawl": {"name": "云纹披肩", "value": 24},
	"coffeecup": {"name": "花纹咖啡杯", "value": 14}, "iris": {"name": "鸢尾胸针", "value": 48},
	"basalt": {"name": "火山石", "value": 16}, "auroraglass": {"name": "极光玻璃", "value": 64}}
const DECOR = {"plant": {"name": "窗边绿植", "price": 8}, "lantern": {"name": "暖光小灯", "price": 14}, "bunting": {"name": "旅行彩旗", "price": 20},
	"tiecloth": {"name": "洱海扎染桌布", "price": 0, "reward_only": true}, "pariscup": {"name": "巴黎纪念咖啡杯", "price": 0, "reward_only": true}, "stonelamp": {"name": "火山石微光灯", "price": 0, "reward_only": true}}
const THEMES = {"spring": "春日花枝", "summer": "夏日清凉", "autumn": "秋日暖叶", "winter": "冬日灯火"}
const INCIDENTS = {"ordinary": "一路平安", "rain": "檐下等雨停", "forgot": "忘带日记本", "friend": "跟朋友绕了点路", "ill": "有点着凉", "mood": "想安静待一会儿"}

static func portions(destination: String, food: String) -> int:
	return ceili(float(ROUTES[destination].supply) / FOODS[food].nutrition)

static func recipe_text(food: String) -> String:
	var parts: Array[String] = []
	for crop in FOODS[food].recipe:
		parts.append("%s×%d" % [CROPS[crop].name, FOODS[food].recipe[crop]])
	return " + ".join(parts)

static func incident(roll: float) -> String:
	if roll < 0.60: return "ordinary"
	if roll < 0.72: return "rain"
	if roll < 0.80: return "forgot"
	if roll < 0.90: return "friend"
	if roll < 0.95: return "ill"
	return "mood"

# Prices follow per-unit growing cost; prepared meals include a convenience premium.
const CROP_PRICES = {"herb": 1, "rice": 2, "corn": 3, "mushroom": 4, "carrot": 6, "pumpkin": 8, "potato": 12, "strawberry": 20}
const LONG_ROUTES = ["tokyo", "istanbul", "paris", "iceland"]
const PROGRESS_COINS = {"tokyo": 3, "istanbul": 5, "paris": 7, "iceland": 10}
static func food_price(id: String) -> int:
	var cost = 0
	for crop in FOODS[id].recipe: cost += CROP_PRICES[crop] * FOODS[id].recipe[crop]
	return ceili(cost * 1.2) + 1
