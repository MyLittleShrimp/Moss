extends RefCounted
## Release timing is a build policy, never a player-save multiplier.
const CROPS = {"herb": 300, "rice": 1800, "mushroom": 7200, "pumpkin": 21600, "corn": 3600, "carrot": 14400, "potato": 43200, "strawberry": 86400}
const TRIPS = {"creek": [900, 1800], "market": [3600, 7200], "hill": [10800, 21600], "dali": [21600, 43200], "hangzhou": [43200, 86400], "tokyo": [86400, 172800], "istanbul": [172800, 345600], "paris": [345600, 518400], "iceland": [604800, 864000]}
const HINTS = {"creek": "附近散步 · 不到一小时", "market": "邻镇闲逛 · 一两个小时", "hill": "山间午后 · 半天以内", "dali": "湖畔慢游 · 半日光景", "hangzhou": "国内远游 · 约一天", "tokyo": "海外小住 · 一两天", "istanbul": "跨洲探访 · 几天光景", "paris": "河岸漫游 · 接近一周", "iceland": "极光长旅 · 一周到十天"}

static func release_build() -> bool:
	return OS.has_feature("release_pace") or "--release-pace" in OS.get_cmdline_user_args()

static func channel() -> String:
	return "release" if release_build() else "development"

static func duration_text(seconds: float) -> String:
	if seconds >= 86400: return ("%.1f" % (seconds / 86400)).trim_suffix(".0") + " 天"
	if seconds >= 3600: return ("%.1f" % (seconds / 3600)).trim_suffix(".0") + " 小时"
	if seconds >= 60: return ("%.1f" % (seconds / 60)).trim_suffix(".0") + " 分钟"
	return ("%.1f" % seconds).trim_suffix(".0") + " 秒"


