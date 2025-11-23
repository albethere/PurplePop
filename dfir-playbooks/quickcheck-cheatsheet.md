# DFIR Quick Check Cheatsheet

A one-page checklist of fast triage steps for incident responders. Commands are geared for quick context gathering while preserving evidence integrity. Prefer read-only actions and collect outputs to a case directory.

## Collection prep
- Record hostname, case number, responder name, and current time.
- Use `script -a case.log` (Linux/macOS) or `Start-Transcript` (Windows PowerShell) to capture console output.
- Mount external storage read-only when possible; avoid altering timestamps on evidence volumes.

## System overview
| Goal | Linux | macOS | Windows |
| --- | --- | --- | --- |
| Host details | `hostnamectl`; `cat /etc/os-release`; `uname -a` | `sw_vers`; `uname -a` | `systeminfo`; `Get-ComputerInfo` |
| Uptime | `uptime -p` | `uptime` | `net stats srv` or `Get-CimInstance Win32_OperatingSystem | select LastBootUpTime` |
| Time sync | `timedatectl` | `systemsetup -getnetworktimeserver`; `ntpdate -q <server>` | `w32tm /query /status` |

## User activity
- List logged-in users: `who` (Linux/macOS) or `query user` (Windows).
- Recent logins and failures:
  - Linux: `last -F | head`, `lastb -F | head`.
  - macOS: `last | head`.
  - Windows: Event IDs 4624/4625/4648 via `Get-WinEvent -FilterHashtable @{LogName='Security';ID=4624,4625,4648} -MaxEvents 20`.
- Privileged groups: `getent group sudo` (Linux), `dseditgroup -o read admin` (macOS), `net localgroup administrators` (Windows).

## Processes and services
- Running processes with network context: `ps auxw | head`, `lsof -i -n -P` (Linux/macOS); `Get-Process` and `Get-NetTCPConnection` (Windows).
- Auto-start items:
  - Linux: `/etc/rc*.d/`, `systemctl list-unit-files --type=service`, `crontab -l`, `/etc/cron.*`.
  - macOS: `/Library/LaunchDaemons`, `/Library/LaunchAgents`, user `~/Library/LaunchAgents`.
  - Windows: `Get-CimInstance Win32_StartupCommand`, Scheduled Tasks via `schtasks /query /fo LIST`, services via `Get-Service`.

## Network quick checks
- Active connections: `ss -tunp` (Linux), `netstat -anv` (macOS), `Get-NetTCPConnection` (Windows).
- Listening ports: `ss -tuln` (Linux), `sudo lsof -iTCP -sTCP:LISTEN` (macOS), `netstat -ano | findstr LISTENING` (Windows).
- Recent DNS cache: `systemd-resolve --statistics` (Linux), `killall -INFO mDNSResponder` logs (macOS), `ipconfig /displaydns` (Windows).
- Firewall status: `iptables -L` or `nft list ruleset` (Linux), `socketfilterfw --getglobalstate` (macOS), `Get-NetFirewallProfile` (Windows).

## Filesystem triage
- Quickly spot recent changes: `find / -mtime -1 -type f 2>/dev/null | head` (Linux/macOS), `Get-ChildItem -Recurse | Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-1) } | Select -First 20` (Windows PowerShell).
- Suspicious persistence locations: `/tmp`, `/var/tmp`, `/dev/shm` (Linux); `/Library/LaunchDaemons`, `/Users/*/Library/LaunchAgents` (macOS); `%ProgramData%`, `%AppData%`, `%TEMP%`, `C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup` (Windows).
- Hash a file before copying: `sha256sum <file>` (Linux/macOS) or `Get-FileHash -Algorithm SHA256 <path>` (Windows).

## Memory and disk checks
- Verify swap/virtual memory usage: `free -h` (Linux), `vm_stat` (macOS), `Get-CimInstance Win32_OperatingSystem | select FreePhysicalMemory,TotalVirtualMemorySize` (Windows).
- Identify mounted volumes: `lsblk` and `mount` (Linux), `diskutil list` (macOS), `Get-Volume` and `Get-Disk` (Windows).
- Check for disk encryption: `systemctl status systemd-cryptsetup*` or `lsblk -f` for LUKS (Linux); `fdesetup status` (macOS); BitLocker via `manage-bde -status` (Windows).

## Log snapshots
- Linux: `/var/log/auth.log`, `/var/log/secure`, `/var/log/syslog`, `journalctl -xn`, service-specific logs under `/var/log/`.
- macOS: `/var/log/system.log`, `log show --last 1h --info`, unified logs via `log collect` if time allows.
- Windows: export key Event Logs with `wevtutil epl Security security.evtx`, `System` and `Application` similarly.

## Evidence preservation tips
- Prefer imaging over ad-hoc copies; use write blockers for removable media.
- Document every command, path, and timestamp; maintain chain of custody notes.
- Avoid rebooting systems unless necessary to contain ongoing damage.
- For remote systems, capture volatile data (processes, network, memory) before containment actions.

## Minimal triage package checklist
- System info snapshot output.
- User/session listing and authentication logs.
- Process list, autoruns, and active network connections.
- Recent file modifications and hashes of any suspicious binaries/documents.
- Copies of critical logs (auth/security/system/application) and configuration files relevant to the incident.