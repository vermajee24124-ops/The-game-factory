from __future__ import annotations

from dataclasses import dataclass, field
from typing import Iterable


@dataclass(frozen=True)
class ComplianceContext:
    target_audience_includes_children: bool = False
    ads_enabled: bool = False
    purchases_enabled: bool = False
    account_creation_enabled: bool = False
    privacy_policy_present: bool = False
    data_inventory_present: bool = False
    store_metadata_present: bool = False
    security_scan_passed: bool = True
    tests_passed: bool = True


@dataclass
class ComplianceReport:
    blockers: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)

    @property
    def releasable(self) -> bool:
        return not self.blockers


def check(context: ComplianceContext) -> ComplianceReport:
    report = ComplianceReport()
    if not context.privacy_policy_present:
        report.blockers.append("Privacy policy artifact is missing.")
    if not context.data_inventory_present:
        report.blockers.append("Data/SDK inventory is missing.")
    if not context.store_metadata_present:
        report.blockers.append("Store metadata package is missing.")
    if not context.tests_passed:
        report.blockers.append("Required automated tests have not passed.")
    if not context.security_scan_passed:
        report.blockers.append("Security checks have not passed.")
    if context.target_audience_includes_children and context.ads_enabled:
        report.warnings.append("Child-directed advertising requires a current platform-specific certified/approved ad configuration and policy audit.")
    if context.target_audience_includes_children and context.purchases_enabled:
        report.warnings.append("Child-directed monetization requires an appropriate guardian/parent flow and current store-policy review.")
    if context.account_creation_enabled and not context.privacy_policy_present:
        report.blockers.append("Account creation without a privacy policy is not releasable.")
    return report


def summarize(report: ComplianceReport) -> str:
    state = "PASS" if report.releasable else "BLOCKED"
    lines = [f"COMPLIANCE: {state}"]
    lines.extend(f"BLOCKER: {item}" for item in report.blockers)
    lines.extend(f"WARNING: {item}" for item in report.warnings)
    return "\n".join(lines)
