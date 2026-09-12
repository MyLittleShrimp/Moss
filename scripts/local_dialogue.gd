class_name LocalDialogue
extends RefCounted
## Explicit scripted fallback, NOT a live LLM. Provider boundary for next stage.

func respond(text: String, world: PetWorld) -> String:
	var input = text.strip_edges()
	if input.is_empty():
		return "我在这里，慢慢说就好。"
	if world.has_method("accept_memory_text"):
		var memory = world.accept_memory_text(input)
		if memory.handled: return memory.text
	if "雨" in input:
		if "忘记" in input:
			world.command("remember", {"preference": "unknown"})
			return "好，我不再把雨声当成你的偏好了。以前的旅行信还留在相册里。"
		# This deliberately narrow parser avoids attributing a friend's preference to the player.
		if input.begins_with("我不喜欢雨") or input.begins_with("我讨厌雨"):
			world.command("remember", {"preference": "dislike", "source": input.left(100)})
			return "记住啦。下次我会找个干爽的地方，再给你写信。"
		if input.begins_with("我喜欢雨"):
			world.command("remember", {"preference": "like", "source": input.left(100)})
			return "那我下次经过溪谷时，就替你多听一会儿。窗台也留给那段声音。"
	if float(world.data.trip_end) > 0:
		return "小纸条：我正去往%s，带着故事再回家。" % GameContent.ROUTES.get(world.data.get("trip_snapshot", {}).get("planned", world.data.active_event.get("destination", "creek")), GameContent.ROUTES.creek).name
	if "累" in input or "忙" in input:
		return "你先歇一会儿吧。我会自己照料小屋，回来时再一起看看窗外。"
	if bool(world.data.placed):
		return "窗台上的青石还在。每次经过它，我都会想起溪边那阵风。"
	if "记得" in input and world.data.rain_preference == "like":
		return "记得呀，你说过喜欢雨声。下一趟旅行，我会留心听听。"
	return "我刚在小屋里转了一圈。要不要种一点香草，给下一次散步准备便当？"
