class_name SuperAgentSkillStore
extends RefCounted

const SKILL_DIR := "res://agent_evolution/learned"
var skills: Array[Dictionary] = []

func load_skills() -> void:
    skills.clear()
    var dir := DirAccess.open(SKILL_DIR)
    if dir == null:
        return
    dir.list_dir_begin()
    var name := dir.get_next()
    while not name.is_empty():
        if not dir.current_is_dir() and name.ends_with(".json"):
            var file := FileAccess.open(SKILL_DIR + "/" + name, FileAccess.READ)
            if file:
                var value = JSON.parse_string(file.get_as_text())
                file.close()
                if value is Dictionary and value.has("skills") and value.skills is Array:
                    for skill in value.skills:
                        if skill is Dictionary:
                            skills.append(skill)
        name = dir.get_next()
    dir.list_dir_end()

func relevant(query: String, limit: int = 8) -> Array[Dictionary]:
    var tokens := query.to_lower().split(" ", false)
    var ranked: Array = []
    for skill in skills:
        var haystack := (str(skill.get("name", "")) + " " + str(skill.get("domain", "")) + " " + str(skill.get("skill", ""))).to_lower()
        var score := 0
        for token in tokens:
            if token.length() >= 3 and haystack.contains(token):
                score += 1
        if score > 0:
            ranked.append({"score": score, "skill": skill})
    ranked.sort_custom(func(a, b): return a.score > b.score)
    var result: Array[Dictionary] = []
    for item in ranked.slice(0, limit):
        result.append(item.skill)
    return result