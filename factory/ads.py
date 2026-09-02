from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class AdsConfig:
    enabled: bool = False
    provider: str = "none"
    personalized_ads: bool = False
    child_directed: bool = True
    unknown_age_treated_as_child: bool = True
    require_age_screen_for_mixed_audience: bool = False
    require_consent_flow_where_applicable: bool = True
    require_report_inappropriate_ads: bool = True


def validate_ads(config: AdsConfig, target_includes_children: bool) -> list[str]:
    issues: list[str] = []
    if not config.enabled:
        return issues
    if target_includes_children and config.personalized_ads:
        issues.append("Personalized/interest-based advertising must be disabled for children and users of unknown age.")
    if target_includes_children and not config.child_directed:
        issues.append("Child-directed traffic must be configured as child-directed when applicable.")
    if config.require_consent_flow_where_applicable is False:
        issues.append("Required privacy/consent handling is missing.")
    if config.require_report_inappropriate_ads and not config.provider:
        issues.append("An advertising provider must be identified before enabling ads.")
    return issues


def manifest(config: AdsConfig, target_includes_children: bool) -> dict[str, Any]:
    return {
        "config": config.__dict__,
        "target_includes_children": target_includes_children,
        "blocked_until_reviewed": bool(validate_ads(config, target_includes_children)),
        "issues": validate_ads(config, target_includes_children),
    }
