+++
title = "OSC52 wrapper script for unsupported terminals"

[taxonomies]
tags = ["osc52", "tty", "pty", "pts", "python"]
+++

I recently write more code directly on an ssh machine. I still haven't beat my procrastination to
move to i3wm, thus a dropdown terminal is my stop gap for a bit nicer experience with
terminal-as-workspace. Unfortunately [vte](https://github.com/GNOME/vte) (and thus
[ddterm](https://github.com/ddterm/gnome-shell-extension-ddterm)) doesn't support OSC52 — an escape
sequence to interact with clipboard. This sucks because vim yank won't copy to my local machine,
sure I can mouse select and Ctrl-Shift-C, but... So as any sane person would do, I wrote a script to
intercept the sequence and support OSC52.

<!-- more -->

# AI slop

I first AI the script, it suggested `pty.fork()` and I couldn't think for my own good enough to
follow suite. This sent me down a rabbit hole of
[TTY demystified](https://www.linusakesson.net/programming/tty). I actually did learn a lot from the
article, and only know now that `ctrl alt f1` is not the same as the terminal window I open. I'm
documenting this for my own learning so if you're not interested, skip to the next section.

`ctrl alt f1` is the software version of the ancient PC with terminal, you type into a keyboard
which connects to the PC which relays information back to the screen (minus some physical landline).
The whole diagram in the article depicts 2 things: `terminal components` (frontend — keyboard,
display) + `tty driver` (backend TeleTYpewriter — the connection to the actual command), and for
`ctrl alt f1` they both run in the kernel as 1 device `/dev/tty1`.

A terminal emulator (e.g. ddterm) runs `terminal components` in userland instead (aka pseudo
terminal `pty`). Actually it's a confusing name because there is no `/dev/pty`. The `pty` run in
userland as slave side, while the `tty driver` stays in kernel as master. An emulator open
`/dev/ptmx` and get back a pair of `/dev/pts/N` (slave) and `fd N` (master). `/dev/pts/N` is the
equivalent of `/dev/tty1`.

I did wonder why there isn't a path for the master but just an `fd`, and there were `/dev/ptyXX`
master devices in the old BSD scheme, but the modern approach is just more secure, with an actual
path any process could then write to it as terminal input !

There's one last thing I only learnt now. I also wondered why 2 files at all, why not just 1 like
`/dev/tty1` ? Well in UNIX those are special files. A write to `/dev/pts/N` isn't stored there at
all, it goes immediately to `fd N` (master) and vice versa, so the kernel knows anything in
`/dev/pts/N` is `stdin` and not `stdout` from programs. Btw the `/dev/tty` is just a map to
`/dev/pts/N`, that's why it always receive actual user `stdin`.

As you probably realize by now, the pair looks a lot like a fancy pipe. It actually is. The
`pty.fork()` was actually fairly compilcated because of bi-directional, and inserting an
intermediate `pty` pair meant I had to deal with signals too (which tbh I was entirely dumb
founded). One of which was the special `SIGWINCH`, used for resizing windows in tmux-likes. It uses
side channel and thus isn't going through the pipe as bytes... haiz.

# Rewrite (with pipe)

I talked to my dear friend wk (woke nights) about this and him being much less dependent on AI said
right away, why not pipe... Well he had all the reasons.

He tried something like this `bash | tee test`. This worked great ! `test` has the `stdout` of the
last command. I can just replace `tee test` with a script to detect the sequence and forward the
rest.

After trying this for a bit though, I noticed that I wouldn't get any color on the terminal. It
turns out that `bash & al` detect whether they're connected to a real terminal and disable color
otherwise. They can be forced them but it's not a universal option. AI found a simple workaround:
`script -qc cmd /dev/null`. It's UNIX, meant to record a terminal session (so simulate a real
`pty`), and allow custom command, amazing ! (`/dev/null` because it's meant to record to a file, but
we just use it for the simulated `pty`)

So now I can do `script -qc cmd /dev/null | tee test`, almost there, what rest to be done is to
intercept the OSC52.

```python
    \x1b\]52;[^;]*;([A-Za-z0-9+/=]*)(?:\x07|\x1b\\)
```

then just copy the match to my clipboard with either

```python
    ['wl-copy'], ['xsel', '--clipboard', '--input'], ['xclip', '-selection', 'clipboard']
```

So much simpler than calling `pty.fork()` and deal with its pair. Great !

# Big clipboard

Well well if only...

`os.read(stdout_fd, ...)` needs a size. No matter how big the size is, there exists theoretically an
infinitely long text that doesn't fit into. As any sane person would do, I tried to detect the split
OSC52 sequence.

The split could happen between the starting - complete ending sequence and also within the starting
sequence itself, thus I check first whether the buffer ends with a partial starting sequence. Notice
it can't be known whether it's actually an OSC52 if it's split at let's say `\x1b`, therefore any
incomplete escape sequence will be buffered at least 1 iteration.

```python
OSC52_PREFIX = b'\x1b]52;'
OSC52 = re.compile(re.escape(OSC52_PREFIX) + rb'[^;]*;([A-Za-z0-9+/=]*)(?:\x07|\x1b\\)')

def find_incomplete_osc52(buf):
    for n in range(1, len(OSC52_PREFIX) + 1):
        if buf.endswith(OSC52_PREFIX[:n]):
            return len(buf) - n
    i = buf.rfind(OSC52_PREFIX)
    if i == -1:
        return -1
    if OSC52.match(buf, i):
        return -1
    return i
```

# Full script

```python
#!/usr/bin/env python3
"""
osc52 support wrapper with script(1)

Architecture:
  Input path:  ddterm → PTY1 → script (inherits stdin) → PTY2 → zellij
  Output path: zellij → PTY2 → script → pipe → this wrapper → PTY1 → ddterm

script(1) handles PTY creation, raw mode, SIGWINCH, and stdin relay.
This wrapper only intercepts the output path for OSC52 sequences,
copying their payload to the local clipboard via wl-copy/xsel/xclip.

Tradeoff vs pty.fork() wrapper: cannot inject into child's stdin
(no OSC52 paste/query support, insecure anyway), but much simpler.
"""
import base64, os, re, subprocess, sys

# OSC52 can be terminated by BEL (\007) or ST (\033\\)
OSC52_PREFIX = b'\x1b]52;'
OSC52 = re.compile(re.escape(OSC52_PREFIX) + rb'[^;]*;([A-Za-z0-9+/=]*)(?:\x07|\x1b\\)')

def find_incomplete_osc52(buf):
    """Return index of a trailing incomplete OSC52 sequence, or -1.

    os.read(fd, 4096) can split an OSC52 across two reads. A large clipboard
    copy (~3KB+ text → ~4KB+ base64) easily exceeds the 4096 boundary. When
    split, the OSC52 regex matches neither chunk — the copy is missed and
    partial escape bytes leak to the terminal.

    Only OSC52 is buffered. Other escape sequences (CSI, other OSC) pass
    through immediately — the terminal's own parser handles partial sequences.

    Note: if you ever try to buffer *all* ESC sequences, beware of CSI
    variants with intermediate bytes like `?`, `>`, `=` (e.g. \x1b[?2004h,
    \x1b[?25l). A naive CSI regex like `\\x1b\\[[0-9;]*[A-Za-z]` won't match
    them, causing those complete sequences to be held as "incomplete" forever
    — leading to deadlocks. This is why we only buffer OSC52 specifically.

    Handles splits at any byte boundary, including within the prefix itself
    (e.g. split between \x1b and ]).
    """
    # Check if buffer ends with a partial prefix of OSC52 start
    for n in range(1, len(OSC52_PREFIX) + 1):
        if buf.endswith(OSC52_PREFIX[:n]):
            return len(buf) - n
    # Check for unterminated OSC52 sequence
    i = buf.rfind(OSC52_PREFIX)
    if i == -1:
        return -1
    if OSC52.match(buf, i):
        return -1
    return i

def copy_to_clipboard(data):
    for cmd in (['wl-copy'], ['xsel', '--clipboard', '--input'], ['xclip', '-selection', 'clipboard']):
        try:
            subprocess.run(cmd, input=data, check=True)
            return True
        except (FileNotFoundError, subprocess.CalledProcessError):
            continue
    return False

def main():
    cmd = sys.argv[1:] or [os.environ.get('SHELL', '/bin/sh')]
    proc = subprocess.Popen(
        ['script', '-qc', ' '.join(cmd), '/dev/null'], # /dev/null discards script log
        stdout=subprocess.PIPE
    )

    stdout_fd = proc.stdout.fileno()
    buf = b''
    try:
        while True:
            data = os.read(stdout_fd, 4096)
            if not data:
                break
            buf += data
            # Hold back only trailing incomplete OSC52 sequences
            i = find_incomplete_osc52(buf)
            if i == -1:
                out, buf = buf, b''
            elif len(buf) - i > 65536:
                ## too large / malformed (no terminator)
                ## flush to avoid unbounded buffer growth
                out, buf = buf, b''
            else:
                out, buf = buf[:i], buf[i:]
            if not out:
                continue
            # Intercept OSC52: decode base64 payload and copy to clipboard
            for m in OSC52.finditer(out):
                try:
                    copy_to_clipboard(base64.b64decode(m.group(1)))
                except Exception:
                    pass
            # Forward to terminal with OSC52 stripped
            os.write(1, OSC52.sub(b'', out))
    except OSError:
        pass
    finally:
        # Flush any remaining buffered data on exit
        if buf:
            os.write(1, OSC52.sub(b'', buf))
        proc.wait()

if __name__ == '__main__':
    main()
```
