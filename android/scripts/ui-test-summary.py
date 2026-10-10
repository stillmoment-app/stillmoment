#!/usr/bin/env python3
"""
Summarize Android UI test results (connectedDebugAndroidTest) for GitHub Actions.

Reads the JUnit XML files written by the Android Gradle Plugin and
- appends a Markdown table to $GITHUB_STEP_SUMMARY (the check's summary page),
- emits one ::error annotation per failed test (shown directly on the check).

Usage: python3 scripts/ui-test-summary.py <results-dir>
Exits 0 in any case: the test step itself decides whether the check is red.
"""

import glob
import os
import sys
import xml.etree.ElementTree as ET

MAX_MESSAGE_LINES = 15


def collect(results_dir):
    total = failed = skipped = 0
    failures = []
    for xml_file in glob.glob(os.path.join(results_dir, "**", "*.xml"), recursive=True):
        try:
            root = ET.parse(xml_file).getroot()
        except ET.ParseError:
            continue
        suites = root.findall("testsuite") if root.tag == "testsuites" else [root]
        for suite in suites:
            for case in suite.findall("testcase"):
                total += 1
                if case.find("skipped") is not None:
                    skipped += 1
                    continue
                problem = case.find("failure")
                if problem is None:
                    problem = case.find("error")
                if problem is None:
                    continue
                failed += 1
                short_class = case.get("classname", "").split(".")[-1]
                name = f"{short_class}.{case.get('name', '')}"
                details = (problem.get("message") or problem.text or "").strip()
                failures.append((name, details))
    return total, failed, skipped, failures


def escape_annotation(text):
    return text.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def main():
    if len(sys.argv) != 2:
        print("Usage: ui-test-summary.py <results-dir>")
        return 0
    total, failed, skipped, failures = collect(sys.argv[1])

    lines = ["## Android UI Tests", ""]
    if total == 0:
        lines.append("No test results found. The build or the emulator failed before tests ran — see the job log.")
    else:
        passed = total - failed - skipped
        status = "passed" if failed == 0 else "FAILED"
        lines.append(f"**{status}** — {passed} passed, {failed} failed, {skipped} skipped, {total} total")
    for name, details in failures:
        short = "\n".join(details.splitlines()[:MAX_MESSAGE_LINES])
        lines += ["", f"### {name}", "", "```", short, "```"]
        first_line = details.splitlines()[0] if details else "failed"
        print(f"::error title=UI test failed: {name}::{escape_annotation(first_line)}")

    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    text = "\n".join(lines) + "\n"
    if summary_path:
        with open(summary_path, "a", encoding="utf-8") as summary:
            summary.write(text)
    else:
        print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
