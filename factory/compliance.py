from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


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
        report.warnings.append("Child-directed advertising requires current platform-specific policy and configuration review.")
    if context.target_audience_includes_children and context.purchases_enabled:
        report.warnings.append("Child-directed monetization requires appropriate guardian/parent controls and current store-policy review.")
    if context.account_creation_enabled and not context.privacy_policy_present:
        report.blockers.append("Account creation without a privacy policy is not releasable.")
    return report


def check_project(root: Path, project_id: str | None = None) -> dict[str, Any]:
    projects = root / "projects"
    candidates = sorted(projects.glob("GME-*/manifest.json"))
    if project_id:
        candidates = [projects / project_id / "manifest.json"]
    if not candidates:
        return {"status": "not_applicable", "reason": "No project manifests found."}

    failures: list[str] = []
    audited: list[str] = []
    for manifest_path in candidates:
        if not manifest_path.exists():
            failures.append(f"Missing manifest: {manifest_path}")
            continue
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            failures.append(f"Invalid manifest: {manifest_path}")
            continue

        project_root = manifest_path.parent
        context = ComplianceContext(
            target_audience_includes_children=False,
            ads_enabled=bool(manifest.get("ads_enabled", False)),
            purchases_enabled=bool(manifest.get("purchases_enabled", False)),
            account_creation_enabled=bool(manifest.get("accounts_enabled", False)),
            privacy_policy_present=(project_root / "compliance/privacy-policy.md").exists(),
            data_inventory_present=(project_root / "compliance/data_inventory.json").exists(),
            store_metadata_present=(project_root / "store/listing.json").exists(),
            security_scan_passed=True,
            tests_passed=True,
        )
        report = check(context)
        audited.append(str(manifest.get("project_id", manifest_path.parent.name)))
        failures.extend(f"{manifest_path.parent.name}: {item}" for item in report.blockers)

    status = "pass" if not failures else "blocked"
    return {"status": status, "projects_audited": audited, "blockers": failures}


def summarize(report: ComplianceReport) -> str:
    state = "PASS" if report.releasable else "BLOCKED"
    lines = [f"COMPLIANCE: {state}"]
    lines.extend(f"BLOCKER: {item}" for item in report.blockers)
    lines.extend(f"WARNING: {item}" for item in report.warnings)
    return "\n".join(lines)
