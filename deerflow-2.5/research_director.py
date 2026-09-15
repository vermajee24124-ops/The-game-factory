"""DeerFlow 2.5 research-director helpers.

This module does not replace DeerFlow's agent runtime. It supplies a deterministic
mission specification and completion checks for the Game Factory's long-horizon
research role.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Iterable


@dataclass
class ResearchMission:
    title: str
    brief: str
    objectives: list[str]
    target_minutes: int = 45
    hard_limit_minutes: int = 60
    started_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def elapsed_minutes(self, now: datetime | None = None) -> float:
        now = now or datetime.now(timezone.utc)
        return max(0.0, (now - self.started_at).total_seconds() / 60.0)

    def time_expired(self, now: datetime | None = None) -> bool:
        return self.elapsed_minutes(now) >= self.hard_limit_minutes

    def objective_completion(self, completed: Iterable[str]) -> tuple[list[str], list[str]]:
        done = {item.strip() for item in completed if item and item.strip()}
        remaining = [item for item in self.objectives if item not in done]
        completed_ordered = [item for item in self.objectives if item in done]
        return completed_ordered, remaining

    def can_finalize(self, completed: Iterable[str], *, quality_gate_passed: bool, now: datetime | None = None) -> bool:
        _, remaining = self.objective_completion(completed)
        if remaining and not self.time_expired(now):
            return False
        return quality_gate_passed


def build_game_research_prompt(mission: ResearchMission) -> str:
    objective_lines = "\n".join(f"- {item}" for item in mission.objectives)
    return f"""You are the Research Director for a Game Factory.\n\nMISSION: {mission.title}\n\nBRIEF:\n{mission.brief}\n\nRESEARCH OBJECTIVES:\n{objective_lines}\n\nRULES:\n1. Start by decomposing the mission into concrete research questions.\n2. Prefer primary and official sources when available.\n3. Run independent research branches in parallel when possible.\n4. Read source content, do not rely only on search snippets.\n5. Record source URLs and concise evidence notes.\n6. Cross-check high-impact claims and record contradictions.\n7. After each research wave, reflect on missing questions and expand the plan when justified.\n8. Compress durable findings before passing them to the main planner.\n9. Produce actionable recommendations, trade-offs, risks, unknowns and implementation implications.\n10. Do not finish merely because the timer is reached; finish when objectives plus the quality gate are satisfied, or when the hard limit is reached and remaining unknowns are explicitly documented.\n\nTIME POLICY:\nTarget={mission.target_minutes} minutes; hard limit={mission.hard_limit_minutes} minutes.\n"""


__all__ = ["ResearchMission", "build_game_research_prompt"]
