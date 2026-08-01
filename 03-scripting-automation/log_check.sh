#!/bin/bash
# log_check.sh
# Reads access.log line by line, flags "Failed" entries, prints the IP.

while IFS= read -r line; do
    ip=$(echo $line | awk '{print $1}')   # extract first field (the IP)

    if echo "$line" | grep -q "Failed"; then
        echo "---[ALERT!] IP $ip had failed access.---"
    else
        echo "---[ACCESSED!] IP $ip had succeeded the access. Good, Maybe. Verify!---"
    fi
done < access.log
