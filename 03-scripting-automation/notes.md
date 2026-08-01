# Phase 3 — notes

Writing code that does security things. Starting with bash, moving to Python.

---

## Why scripting matters here

After Phase 2, I understood attacks and defenses conceptually. But detection doesn't run on understanding — it runs on code. A log parser, a port scanner, an alert threshold — these are written things. Phase 3 was about building the ability to write them.

---

## Bash: the concepts

A bash script is just a sequence of shell commands saved to a file and run together. The shebang line `#!/bin/bash` tells the system which interpreter to use.

**Variables:**
```bash
name="Shaurya"
echo "Hello $name"
```
Variables hold values. No spaces around the `=`. Use `$name` to read the value.

**Command substitution:**
```bash
current_dir=$(pwd)
echo "I am in $current_dir"
```
`$()` runs a command and captures its output as a value. This is how you store the result of a command in a variable.

**Conditionals:**
```bash
if [ -f /etc/passwd ]; then
    echo "found"
fi
```
`-f` checks if a path is a regular file. `-d` checks for a directory. The brackets `[ ]` are the test operator. `then` and `fi` close the block.

**Loops:**
```bash
while IFS= read -r line; do
    echo "$line"
done < file.txt
```
`IFS=` clears the field separator so lines with spaces are read whole. `read -r` reads one line at a time without interpreting backslashes. This is the standard pattern for reading a file line by line.

**`awk` for field extraction:**
```bash
echo "192.168.1.5 - Failed" | awk '{print $1}'
# output: 192.168.1.5
```
`awk` splits input on whitespace and lets you print specific fields. `$1` is first, `$2` is second, and so on.

**The counting pipeline:**
```bash
grep "Failed" auth.log | awk '{print $1}' | sort | uniq -c | sort -nr
```
`grep` filters matching lines. `awk` extracts the IP. `sort` groups identical IPs together. `uniq -c` counts consecutive duplicates. `sort -nr` sorts by count, highest first. This pipeline is the logic behind "top attacking IPs" in any SIEM.

---

## Python: the concepts

Python's job in this context: when bash gets messy (structured data, multi-file logic, readable code), switch to Python.

**Variables and printing:**
```python
name = "Shaurya"
log_level = "WARNING"
print(f"[{log_level}] Hello {name}")
```
f-strings let you embed variables directly in strings with `{}`.

**Reading files:**
```python
with open("auth.log", "r") as f:
    for line_num, line in enumerate(f, 1):
        if "Failed password" in line:
            print(f"Line {line_num}: {line.strip()}")
```
`with open()` is a context manager — the file closes automatically when the block ends. `enumerate(f, 1)` gives you line numbers starting from 1.

**Error handling:**
```python
try:
    with open(filepath, "r") as f:
        data = f.read()
except FileNotFoundError:
    print(f"Not found: {filepath}")
    sys.exit(1)
```
`try/except` catches predictable failures. `sys.exit(1)` signals failure to whatever called the script — important for cron jobs and automated pipelines.

**When to use which:**
- Bash: quick automation, chaining CLI tools, cron jobs, one-liners
- Python: structured data, multi-file logic, readable maintainable code, anything that'll be read again later
