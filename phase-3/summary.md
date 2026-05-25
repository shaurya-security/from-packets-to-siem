# Phase 3 — summary

Phase 3 was the most frustrating phase and the one that changed the most.

---

## What landed

The counting pipeline — `grep | awk | sort | uniq -c | sort -nr` — clicked after the frustrating session where counting inside a loop always returned 1. That failure forced understanding: `uniq -c` needs all the data at once, not one line at a time. Once that clicked, the pipeline made structural sense, not just syntactic sense.

The blank screen problem was real. Short scripts are fine. Anything over 20 lines and the starting point became unclear. The solution was to always start from the nearest working thing and change only what's specific to the new task. Same strategy showed up again in Phase 5 with detection rules.

Functions were genuinely useful. `hero.sh` having a `hero()`, `hero_exist()`, and `main()` function felt like a different kind of code — readable, reusable, not a wall of sequential commands.

---

## Where I got it wrong

The cron duplication bug was the most instructive mistake. The script appended a log to a backup then appended the backup back to the original. Exponential growth every minute. The fix was obvious in hindsight — never write back to a file you're reading from. But I had to see it happen to really understand why production log systems treat source files as read-only.

Several syntax errors happened in the same ways repeatedly: `if ;do` instead of `if ;then`, unclosed quotes, forgetting `"$variable"` vs `"variable"`. These became automatic after getting them wrong enough times.

---

## What I'd do differently

Slow down earlier in the loop. I spent multiple sessions on the counting problem before stepping back and thinking about the architecture. The issue wasn't syntax — it was that `uniq -c` inside a per-line loop is structurally wrong. Reading the error output more carefully earlier would have saved time.

---

## Going into Phase 4

The bash skills transferred immediately. Phase 4's `inventory.sh` uses command substitution, `-z` empty checks, and function structure that's identical to `hero.sh`. The pattern carried forward.
