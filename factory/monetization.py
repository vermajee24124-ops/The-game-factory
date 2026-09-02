from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class MonetizationConfig:
    enabled: bool = False
    platform: str = "none"
    require_backend_verification: bool = True
    allow_pending_entitlement: bool = False
    require_restore: bool = True
    require_refund_sync: bool = True
    require_parental_gate_when_applicable: bool = True


GOOGLE_PLAY_PURCHASE_STATES = {"PENDING", "PURCHASED", "CANCELED"}
APPLE_PURCHASE_STATES = {"PENDING", "PURCHASED", "REFUNDED", "REVOKED"}


def validate_monetization(config: MonetizationConfig, target_includes_children: bool) -> list[str]:
    issues: list[str] = []
    if not config.enabled:
        return issues
    if config.require_backend_verification is False:
        issues.append("Payment must use secure server-side verification before granting entitlement when a backend is available.")
    if target_includes_children and config.require_parental_gate_when_applicable is False:
        issues.append("Child-directed monetization requires an appropriate parental/guardian flow where applicable.")
    return issues


def purchase_lifecycle(platform: str) -> list[str]:
    platform = platform.lower()
    if platform == "google_play":
        return [
            "query products",
            "launch purchase flow",
            "detect purchase/pending state",
            "verify purchase token with secure backend",
            "grant entitlement only after PURCHASED verification",
            "acknowledge/consume as appropriate",
            "process refund/revocation lifecycle",
        ]
    if platform == "apple":
        return [
            "load products",
            "launch StoreKit purchase",
            "verify transaction",
            "grant entitlement",
            "support restore purchases",
            "handle refunds/revocations",
            "process App Store Server Notifications when backend is enabled",
        ]
    return ["provider-specific purchase flow", "server verification", "entitlement", "refund/revocation"]


def manifest(config: MonetizationConfig, target_includes_children: bool) -> dict[str, Any]:
    return {
        "config": config.__dict__,
        "target_includes_children": target_includes_children,
        "lifecycle": {p: purchase_lifecycle(p) for p in ("google_play", "apple")},
        "issues": validate_monetization(config, target_includes_children),
    }
