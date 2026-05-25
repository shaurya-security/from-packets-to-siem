# Phase 1 — summary

Phase 1 wasn't about learning commands. It was about learning to read a system like a conversation rather than a wall of text.

---

## What landed

The permission string clicked immediately and stayed. One glance at `-rw-r--r--` now tells me: owner reads and writes, group reads, everyone else reads. That's useful every time I open a terminal.

The ARP/ICMP lesson stuck too — absence of ping doesn't mean the host is gone. Layer 2 and Layer 3 are different things. I didn't fully understand why that mattered until Phase 5 (cloud detection), but the reasoning was right.

The netcat experiment where I ran it four ways — with both flags, one flag, no flags — was one of the better moments. I wasn't told to do that. I just wanted to see what actually changed. Turns out: only the connection feedback changes. The shell on the other end doesn't know or care.

---

## Where I got it wrong

The CIA triad / availability mistake. I argued `chmod 600` protects all three parts of the triad because the owner still has access. The correction: availability means the service or data is reachable when *authorized users need it* — not that one specific person has a key. Locking something down tighter can break availability for others who legitimately need it.

This was a useful mistake. After working through the correction with `chmod 000` as the ghost file example, the concept stuck in a way it wouldn't have if I'd gotten it right the first time.

---

## What came from it

The SSD died partway through Phase 1. Replaced it, migrated from Windows 10 to Windows 11, hit compatibility issues, lost a day to that. Rebuilt everything: WSL2, Metasploitable, switched from Ubuntu VM to Linux Mint VM.

Looking back, that chaos was the first real application of Phase 2 concepts — an availability failure (SSD), an integrity failure (bad upgrade), and an incident response (manual rebuild). At the time it just felt like a bad few days.

---

## Going into Phase 2

Phase 1 left me with: a mental map of the filesystem, working intuition about permissions, the ability to check what's running and what's listening, and enough netcat understanding to knock on a port and see what answers. That's enough to be dangerous in a lab. Phase 2 gave those skills context — threat, vulnerability, kill chain — so they meant something beyond just running commands.
