# Project collaboration rules

- User selected Godot. Use Godot 4 / GDScript for the playable prototype.
- Each completed phase must have a Markdown handoff in `docs/handoffs/`: scope, changed files, run instructions, actual tests/evidence, remaining limits, and next steps.
- Record every material encountered issue in `docs/TROUBLESHOOTING.md`: symptoms, reproduction, root cause/evidence, solution, verification, prevention, status. Distinguish resolved issues from pending work.
- Keep `docs/STATUS.md` current. Do not declare a full roadmap phase complete when only its technical slice is done.
- Never represent local scripted dialogue as live LLM output. Generated narrative cannot directly change inventory or grant rewards.
- Preserve user saves. Automated tests use separate temporary save paths. Do not include credentials in source or logs.
- No delegation unless the user explicitly requests it.
