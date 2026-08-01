#!/usr/bin/env python3
"""
log_parser.py
Parse auth.log style files for security events.
Usage: python3 log_parser.py [/path/to/logfile]
"""

import sys
from datetime import datetime

SUSPICIOUS = [
    "Failed password",
    "Invalid user",
    "authentication failure"
]


def parse_log(filepath):
    findings = []
    try:
        with open(filepath, "r") as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                for keyword in SUSPICIOUS:
                    if keyword in line:
                        findings.append({
                            "line": line_num,
                            "keyword": keyword,
                            "content": line
                        })
                        break  # one match per line — don't double count
    except FileNotFoundError:
        print(f"[ERROR] File not found: {filepath}")
        sys.exit(1)
    except PermissionError:
        print(f"[ERROR] Permission denied: {filepath}")
        sys.exit(1)
    return findings


if __name__ == "__main__":
    logfile = sys.argv[1] if len(sys.argv) > 1 else "/var/log/auth.log"
    findings = parse_log(logfile)

    print(f"\n{'='*50}")
    print(f"Scan: {logfile}  |  {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    print(f"Findings: {len(findings)}")
    print(f"{'='*50}\n")

    if not findings:
        print("Nothing suspicious found.")
    else:
        for item in findings:
            print(f"[Line {item['line']:>5}] {item['keyword']}")
            print(f"         {item['content'][:90]}")
