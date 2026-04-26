# nut-cyberpower-macos

> Event-driven UPS monitoring for macOS using NUT (Network UPS Tools) with CyberPower USB HID, coordinated multi-host shutdown, and Telegram alerting.

**Production-verified on:**
- macOS 12 Monterey · Mac Mini (Intel)
- CyberPower CP1500PFCLCDa · USB HID · Vendor `0764` · Product `0601`
- NUT 2.8.5 via Homebrew
- Remote Linux (Ubuntu) and Windows (OpenSSH) shutdown coordination

---

## Features

- **Event-driven** — NUT `upsmon` calls the handler the instant the UPS state changes. No polling.
- **Coordinated shutdown** — Mac, remote Linux, and remote Windows all receive 2-minute shutdown warnings simultaneously.
- **Immediate LOWBATT path** — skips the timer and shuts everything down immediately when battery is critical.
- **Cancellable** — flag-file mechanism aborts all shutdowns if utility power returns within 2 minutes.
- **Telegram alerts** — every state change sends a message with retry logic and local logging.
- **SSH pre-flight** — verifies remote hosts are reachable before attempting shutdown.
- **launchd managed** — driver, upsd, and upsmon run as system LaunchDaemons, survive reboot, auto-restart on crash.

---

## Repository Layout

```
nut-cyberpower-macos/
├── README.md
├── ups_handler.sh.example      # NOTIFYCMD event handler (fill in credentials)
├── ups_cancel.sh.example       # Manual cancel script (fill in credentials)
├── ups.conf                    # NUT driver config
├── upsd.conf.example           # NUT server listener config
├── upsd.users.example          # NUT user credentials (sanitized)
├── upsmon.conf.example         # upsmon monitor config (sanitized)
└── launchd/
    ├── org.nut.upsdrv.plist    # USB HID driver daemon
    ├── org.nut.upsd.plist      # NUT server daemon
    └── org.nut.upsmon.plist    # UPS monitor daemon
```

---

## Requirements

| Component | Detail |
|-----------|--------|
| macOS | 12 Monterey or later (Intel or Apple Silicon) |
| Homebrew | Current |
| NUT | 2.8.5 via `brew install nut` |
| CyberPower UPS | USB connected — Vendor `0x0764` |
| SSH keys | Passwordless from Mac root to remote Linux and Windows |
| Telegram Bot | Token from BotFather + your chat ID |

---

## Installation

### 1. Install NUT

```zsh
brew install nut
```

> **macOS 12 note:** NUT builds openssl@3 from source. Allow 25–30 minutes.
> If install fails with a stale lock: `rm /usr/local/var/homebrew/locks/nut.formula.lock`

**Verify binary locations (Intel Mac):**
```zsh
/usr/local/opt/nut/sbin/upsd       # NUT server
/usr/local/opt/nut/sbin/upsmon     # UPS monitor
/usr/local/Cellar/nut/2.8.5/bin/usbhid-ups   # USB HID driver (bin not sbin)
```

### 2. Verify UPS detection

```zsh
system_profiler SPUSBDataType 2>/dev/null | grep -i "vendor\|manufacturer"
```

Confirm: `Vendor ID: 0x0764  (Cyber Power Systems, Inc.)`

### 3. Create directories

```zsh
sudo mkdir -p /usr/local/var/state/ups
sudo chmod 755 /usr/local/var/state/ups
sudo chown root:wheel /usr/local/var/state/ups
sudo chown root:nobody /usr/local/etc/nut
sudo chmod 750 /usr/local/etc/nut
sudo touch /var/log/nut-driver.log /var/log/nut-upsd.log /var/log/nut-upsmon.log /var/log/ups_handler.log
sudo chmod 644 /var/log/nut-*.log /var/log/ups_handler.log
mkdir -p /Users/Steve/projects/UPS
```

### 4. Configure NUT

Copy example files and fill in your values:

```zsh
cp ups.conf /usr/local/etc/nut/ups.conf
cp upsd.users.example /usr/local/etc/nut/upsd.users
cp upsmon.conf.example /usr/local/etc/nut/upsmon.conf
```

Edit `upsd.users` — replace `YOUR_NUT_PASSWORD` with a real password.
Edit `upsmon.conf` — replace `YOUR_NUT_PASSWORD` with the same password.

Set permissions on all NUT config files:

```zsh
for f in ups.conf upsd.conf upsd.users upsmon.conf; do
  sudo chown root:nobody /usr/local/etc/nut/$f
  sudo chmod 640 /usr/local/etc/nut/$f
done
```

### 5. Install scripts

```zsh
cp ups_handler.sh.example /Users/Steve/projects/UPS/ups_handler.sh
cp ups_cancel.sh.example /Users/Steve/projects/UPS/ups_cancel.sh
```

Edit both scripts — replace:
- `YOUR_TELEGRAM_BOT_TOKEN`
- `YOUR_TELEGRAM_CHAT_ID`
- `YOUR_LINUX_USER` and `YOUR_LINUX_IP`
- `YOUR_WINDOWS_USER` and `YOUR_WINDOWS_IP`

```zsh
sudo chown root /Users/Steve/projects/UPS/ups_handler.sh
sudo chown root /Users/Steve/projects/UPS/ups_cancel.sh
sudo chmod 750 /Users/Steve/projects/UPS/ups_handler.sh
sudo chmod 750 /Users/Steve/projects/UPS/ups_cancel.sh
```

### 6. Deploy SSH keys from Mac root to remote hosts

The handler runs as root via upsmon. Root needs its own SSH keys deployed to remote hosts.

```zsh
sudo mkdir -p /var/root/.ssh
sudo cp /Users/Steve/.ssh/id_ed25519 /var/root/.ssh/
sudo cp /Users/Steve/.ssh/id_ed25519.pub /var/root/.ssh/
sudo cp /Users/Steve/.ssh/known_hosts /var/root/.ssh/
sudo chmod 700 /var/root/.ssh
sudo chmod 600 /var/root/.ssh/id_ed25519
sudo chmod 644 /var/root/.ssh/id_ed25519.pub known_hosts
```

Deploy to Linux:
```zsh
ssh-copy-id YOUR_LINUX_USER@YOUR_LINUX_IP
```

Deploy to Windows — see **Windows SSH Key Setup** section below.

Test as root:
```zsh
sudo ssh -o BatchMode=yes YOUR_LINUX_USER@YOUR_LINUX_IP "echo ok"
sudo ssh -o BatchMode=yes YOUR_WINDOWS_USER@YOUR_WINDOWS_IP "echo ok"
```

### 7. Configure passwordless sudo on Linux

The handler calls `sudo shutdown` on the Linux host. Add a sudoers rule:

```bash
sudo visudo
```

Add at the bottom:
```
YOUR_LINUX_USER ALL=(ALL) NOPASSWD: /sbin/shutdown
```

### 8. Install LaunchDaemons

```zsh
sudo cp launchd/org.nut.upsdrv.plist /Library/LaunchDaemons/
sudo cp launchd/org.nut.upsd.plist /Library/LaunchDaemons/
sudo cp launchd/org.nut.upsmon.plist /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/org.nut.*.plist
sudo chmod 644 /Library/LaunchDaemons/org.nut.*.plist
```

### 9. Load services (order matters)

```zsh
sudo launchctl bootstrap system /Library/LaunchDaemons/org.nut.upsdrv.plist
sleep 5
sudo launchctl bootstrap system /Library/LaunchDaemons/org.nut.upsd.plist
sleep 3
sudo launchctl bootstrap system /Library/LaunchDaemons/org.nut.upsmon.plist
sleep 5
```

### 10. Verify

```zsh
/usr/local/opt/nut/bin/upsc ups1@localhost ups.status
```

Expected: `OL`

```zsh
ps aux | grep -E "usbhid|upsd|upsmon" | grep -v grep
```

Expected — three processes all showing `??` (daemon):
```
root    ... /usr/local/Cellar/nut/2.8.5/bin/usbhid-ups -u root -a ups1 -F
nobody  ... /usr/local/opt/nut/sbin/upsd -u nobody -F
root    ... /usr/local/opt/nut/sbin/upsmon -F
nobody  ... /usr/local/opt/nut/sbin/upsmon -F
```

### 11. Test end-to-end

```zsh
rm -f /Users/Steve/.ups_shutdown_flag
sudo /Users/Steve/projects/UPS/ups_handler.sh 'UPS ups1 on battery'
```

Watch Telegram for:
- UPS on battery alert
- Linux shutdown initiated
- Windows shutdown initiated

Then immediately cancel:

```zsh
sudo /Users/Steve/projects/UPS/ups_cancel.sh
```

Watch Telegram for:
- Linux shutdown cancelled
- Windows shutdown cancelled
- All shutdowns aborted

---

## Cancel Shutdown Manually

If power restores before the 2-minute window expires:

```zsh
sudo /Users/Steve/projects/UPS/ups_cancel.sh
```

---

## Windows SSH Key Setup

Windows OpenSSH enforces strict file ownership on `authorized_keys`. This is the correct procedure — shortcuts will fail.

### 1. Configure sshd_config on Windows (as Administrator)

```cmd
notepad C:\ProgramData\ssh\sshd_config
```

Comment out the default and add explicit path:
```
#AuthorizedKeysFile      .ssh/authorized_keys
AuthorizedKeysFile C:\Users\USERNAME\.ssh\authorized_keys
```

Also comment out if present:
```
#       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
```

Restart sshd:
```cmd
net stop sshd && net start sshd
```

### 2. Create .ssh directory (as Administrator)

```cmd
mkdir C:\Users\USERNAME\.ssh
icacls "C:\Users\USERNAME\.ssh" /inheritance:r /grant USERNAME:F /grant SYSTEM:F /grant ADMINUSER:F
```

### 3. Create authorized_keys using PowerShell (avoids \r\n line endings)

```cmd
powershell -Command "Set-Content 'C:\Users\USERNAME\.ssh\authorized_keys' 'ssh-ed25519 AAAA...your_key... user@host' -NoNewline -Encoding utf8"
```

### 4. Fix ownership — MUST be done as the target user via SSH

This is the critical step. Run from Mac:

```zsh
ssh USERNAME@WINDOWS_IP
```

Once logged in on Windows:
```cmd
takeown /f "C:\Users\USERNAME\.ssh\authorized_keys"
icacls "C:\Users\USERNAME\.ssh\authorized_keys" /inheritance:r /grant USERNAME:F /grant SYSTEM:R
exit
```

### 5. Test

```zsh
ssh -o BatchMode=yes USERNAME@WINDOWS_IP "echo ok"
```

> **Key lesson:** Windows profile folders may appear as `USERNAME.COMPUTERNAME` in the filesystem. The `AuthorizedKeysFile` override in sshd_config is required to point to the correct path.

> **Key lesson:** Windows `shutdown /s /t 120` returns a non-zero exit code even on success. Do not use `||` to detect failure — it will always report failure even when the shutdown was initiated correctly.

---

## Log Files

| Log | Contents |
|-----|----------|
| `/var/log/nut-driver.log` | USB HID driver output |
| `/var/log/nut-upsd.log` | NUT server output |
| `/var/log/nut-upsmon.log` | upsmon events |
| `/var/log/ups_handler.log` | Telegram send attempts |

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `ERR ACCESS-DENIED` in upsmon log | Password mismatch between upsmon.conf and upsd.users. Run `sudo killall -HUP upsd` |
| `Can't claim USB device: Access denied` | Run driver as root: `sudo upsdrvctl -u root start` |
| `Driver not connected` | Driver needs 5-8s before upsd starts. Use sleep between bootstrap commands |
| `Bootstrap failed: 5` | Stale registration. `sudo launchctl bootout system/org.nut.upsd` then re-bootstrap |
| `program = /usr/local/sbin/upsd` in launchctl | Old plist cached. Bootout and re-bootstrap to pick up new path |
| `invalid notify type [COMMLOST]` | Use `COMMBAD` not `COMMLOST` in upsmon.conf (removed in NUT 2.8.x) |
| `A previous upsmon instance is already running` | `sudo killall upsmon && sudo rm -f /usr/local/var/run/upsmon.pid` |
| `Bad owner on authorized_keys` | Windows: run takeown from within SSH session as the target user |
| `Failed to open file error:13` | Windows: fix .ssh directory permissions — SYSTEM needs F not just R |
| Windows shutdown reports failure but works | Remove `\|\|` error check — Windows shutdown returns non-zero even on success |
| Handler hangs on battery event | Remote host is offline. Ctrl+C, wait for host, then retest |
| Root SSH fails with host key error | Copy Steve's known_hosts to /var/root/.ssh/ |
| `sudo shutdown` requires password on Linux | Add `USER ALL=(ALL) NOPASSWD: /sbin/shutdown` to sudoers via visudo |

---

## NUT 2.8.x Breaking Changes

- `allowfrom` in upsd.users is removed — use `upsmon primary` instead
- `COMMLOST` notify flag removed — use `COMMBAD`
- `actions = SET` and `instcmds = ALL` must be uppercase
- upsmon PID file moved to `/usr/local/var/run/upsmon.pid`

---

## Known Behaviours

- `upsnotify: failed to notify about NOTIFY_STATE_READY_WITH_PID` — cosmetic warning on macOS, no impact
- `/usr/libexec/ioupsd` (Apple's UPS daemon) coexists with NUT without conflict
- macOS 12 is Homebrew Tier 3 — openssl@3 builds from source (~30 minutes)
- Windows `shutdown /s /t 120` returns exit code 1 even on success

---

## License

MIT

---

## Author

StevoKeano
