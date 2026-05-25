# Phase 1 — labs

Real terminal sessions. Mistakes included.

---

## First look at the filesystem

```bash
dell@DESKTOP-RUFLD2D:~$ ls -la /
total 2808
drwxr-xr-x  23 root root    4096 Apr 18 22:47 .
drwxr-xr-x  23 root root    4096 Apr 18 22:47 ..
drwxr-xr-x   3 root root    4096 Apr 18 22:47 Docker
lrwxrwxrwx   1 root root       7 Apr 22  2024 bin -> usr/bin
drwxr-xr-x  93 root root    4096 Apr 24 01:37 etc
drwxr-xr-x   3 root root    4096 Apr 18 23:54 home
-rwxr-xr-x   1 root root 2781568 Dec 12 07:28 init
dr-xr-xr-x 268 root root       0 Apr 18 22:47 proc
drwx------   5 root root    4096 Apr 18 22:47 root
drwxrwxrwt   9 root root    4096 Apr 24 01:22 tmp
drwxr-xr-x  12 root root    4096 Feb 10 06:24 usr
drwxr-xr-x  13 root root    4096 Apr 16 20:16 var
```

What I noticed: `init` is a regular file (`-rwxr-xr-x`), 2.7MB. That's WSL2's custom init — not systemd. `proc` has 268 entries — those are running processes exposed as a filesystem. `root` is `drwx------` — only root can enter.

---

## Permissions experiment

```bash
dell@DESKTOP-RUFLD2D:~$ ls -la /etc/passwd
-rw-r--r-- 1 root root 1658 Jan 15 20:29 /etc/passwd

dell@DESKTOP-RUFLD2D:~$ ls -la /etc/shadow
-rw-r----- 1 root shadow 742 Jan 15 20:29 /etc/shadow
```

`/etc/passwd` is readable by everyone (`-rw-r--r--`). It contains usernames but not passwords. `/etc/shadow` is readable only by root and the shadow group. That gap is why getting root matters — shadow stays locked without it.

I tried `chmod 600` on a test file and said it protects all three parts of the CIA triad. Got corrected: `chmod 600` protects confidentiality (only owner reads) and integrity (only owner writes), but it doesn't protect availability — in fact, it restricts it. A file locked to one person is inaccessible to everyone else who might need it.

Then I reasoned it through with `chmod 000`:

> "No one can access it, so it's available to no one — ghost file."

That landed. `chmod 000` protects confidentiality and integrity perfectly, breaks availability entirely.

---

## Hashing — ran it and observed

```bash
dell@DESKTOP-RUFLD2D:~$ echo -n 'mygirlfriendshoumya' | sha256sum
c22f55829da0fa126e7f7ff5f6d961f0cff1a65d7042bbfe517410944d32b7f5  -

dell@DESKTOP-RUFLD2D:~$ echo -n 'mygirlfriendshoumya' | sha256sum
c22f55829da0fa126e7f7ff5f6d961f0cff1a65d7042bbfe517410944d32b7f5  -

dell@DESKTOP-RUFLD2D:~$ echo 'mygirlfriendshoumya' | sha256sum
3b997b4ee6af3c75aa9d2f5892fc398abef8be47b851ebd94b914ee60dd241f0  -
```

`echo -n` omits the trailing newline. Without `-n`, there's a hidden newline character appended, which changes the hash completely. Same input always gives the same hash. Different input — even one invisible character — gives a totally different hash.

Salting experiment — three different "salts" prepended to the same password:

```bash
dell@DESKTOP-RUFLD2D:~$ echo -n 'height' | cat - <(echo -n 'mygirlfriendshoumya') | sha256sum
c3764bc85c50030bd5a53d088bcfb7633e2b625b404eda09bad70420253ee068  -

dell@DESKTOP-RUFLD2D:~$ echo -n 'sakshi' | cat - <(echo -n 'mygirlfriendshoumya') | sha256sum
bf75af273e7227b8a081d65281cbd19e38169fd57606b16df37a22d4a43921a3  -

dell@DESKTOP-RUFLD2D:~$ echo -n 'r' | cat - <(echo -n 'mygirlfriendshoumya') | sha256sum
9dfe73a330dc6cc91542f5d36156dc0b44e2df2a5dd79cd45df7b29285813be8  -
```

Three completely different hashes for the same password. An attacker who cracks one has to start over for every other user. That's why salting exists.

I noted: I'll forget this exact command format in an hour. That's fine — real salting is handled by bcrypt or Argon2 automatically. Understanding *why* it works matters more than memorizing the plumbing.

---

## The netcat experiment

```bash
dell@DESKTOP-RUFLD2D:~$ nc -nv 192.168.43.91 1524
Connection to 192.168.43.91 1524 port [tcp/*] succeeded!
root@metasploitable:/# whoami
root

dell@DESKTOP-RUFLD2D:~$ nc -n 192.168.43.91 1524   # no verbose
root@metasploitable:/# whoami
root

dell@DESKTOP-RUFLD2D:~$ nc -v 192.168.43.91 1524    # verbose, with DNS attempt
Connection to 192.168.43.91 1524 port [tcp/ingreslock] succeeded!
root@metasploitable:/# whoami
root

dell@DESKTOP-RUFLD2D:~$ nc 192.168.43.91 1524       # bare, silent
root@metasploitable:/# whoami
root
```

All four connected. The flags only change the *connection feedback*, not the result. With `-v`, the port name shows as `tcp/ingreslock` — that's a known service identifier for that port number. Without `-n`, nc tried DNS. Both still worked because the bindshell doesn't care how you connect.

---

## Gateway that blocked ICMP

```bash
dell@DESKTOP-RUFLD2D:~$ arp -a
DESKTOP-RUFLD2D.mshome.net (172.31.112.1) at 00:15:5d:c7:28:f5 [ether] on eth0

dell@DESKTOP-RUFLD2D:~$ ping -c 4 172.31.112.1
4 packets transmitted, 0 received, 100% packet loss

dell@DESKTOP-RUFLD2D:~$ ping -c 4 8.8.8.8
64 bytes from 8.8.8.8: icmp_seq=1 ttl=111 time=241 ms
4 packets transmitted, 4 received, 0% packet loss
```

The gateway appears in `arp -a` — Layer 2 reachability confirmed. But ping fails — Layer 3 ICMP blocked. Yet traffic to 8.8.8.8 routes *through* that same gateway fine. Conclusion: Windows Firewall on the host blocks ICMP directed at its virtual adapter. The host is up, functioning, and just filtering ICMP back to itself.

Lesson: ping failure doesn't mean the host is dead. Always check ARP first.
