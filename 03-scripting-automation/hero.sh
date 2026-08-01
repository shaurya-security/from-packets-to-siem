#!/bin/bash
# hero.sh
# Modular log scanner with functions.

hero() {
    local logfile=$1
    echo "=== Checking $logfile ==="
    grep "Failed" "$logfile" | awk '{print $1}' | sort | uniq -c | sort -n
}

hero_exist() {
    local exist=$1
    if [ -f "$exist" ]; then     # "$exist" not "exist" — always quote variable expansions
        echo "=== Found ==="
    else
        echo "=== Missing ==="
    fi
}

main() {
    echo "Security Scanner v1.0"

    if hero_exist 'access.log'; then
        hero 'access.log'
    fi
}

main
