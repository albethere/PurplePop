# Windows Incident Response Artifact Playbook

A quick-reference checklist for acquiring and triaging Windows artifacts during incident response. Focus on collecting volatile data first, then durable sources for timeline and root-cause analysis.

## Triage priorities
- **Preserve volatile data first:** live memory image, running processes, network connections, and ARP/route tables.
- **Capture system context:** hostname, users, domain membership, uptime, boot time, installed updates, and AV/EDR status.
- **Collect execution evidence:** PowerShell history, Prefetch, ShimCache/AmCache, SRUM, BAM/DAM, and task/service changes.
- **Secure authentication material:** LSASS dump (with care), SAM/SECURITY/SYSTEM hives, DPAPI master keys, LSA secrets, and cached credentials.
- **Keep integrity:** hash artifacts, record acquisition tools/versions, and log command transcripts.

## Volatile data (live response)
- Processes and loaded modules: `tasklist /v`, `Get-Process | Select Name,Id,StartTime,Path`, `handle.exe`.
- Network state: `netstat -ano`, `Get-NetTCPConnection`, `arp -a`, `route print`.
- Logged-on sessions: `query user`, `quser`, `klist sessions`, RDP client cache (`%LocalAppData%\Microsoft\Terminal Server Client\Cache`).
- Memory acquisition: use **DumpIt**, **Magnet RAM Capture**, or **WinPmem**; verify hashes.

## Event logs
- Export via `wevtutil epl <log> <dest>` or `Get-WinEvent`.
- Core logs:
  - **System** (drivers, services, device adds/removals).
  - **Security** (logon/logoff, process creation 4688/4689, Special Logon 4672, account changes, group changes, Kerberos, NTLM).
  - **Application** (app errors), **Setup** (installs), **Windows PowerShell** and **Microsoft-Windows-PowerShell/Operational**, **Microsoft-Windows-Sysmon/Operational**, **Microsoft-Windows-WMI-Activity/Operational**.
  - **Defender** (`Microsoft-Windows-Windows Defender/Operational`) and any EDR-specific channels.
- Forwarded events or collector logs if WEF is in use.

## Registry hives to capture
- `C:\Windows\System32\config\SAM`, `SECURITY`, `SYSTEM`, `SOFTWARE`, and `DEFAULT` (plus their `.log` files).
- User hives: `C:\Users\<user>\NTUSER.DAT` and `UsrClass.dat`.
- Offline copies in `C:\Windows\System32\config\RegBack` if available.
- Key triage locations:
  - Run keys: `...\Run`, `RunOnce`, `RunServices`, `Image File Execution Options`, `SilentProcessExit`.
  - Services: `HKLM\SYSTEM\CurrentControlSet\Services` (look for odd paths or new services).
  - **WMI persistence:** `ROOT\Subscription` (`__EventFilter`, `CommandLineEventConsumer`, `FilterToConsumerBinding`).
  - **Scheduled Tasks:** `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree` and `\Tasks` folder on disk.
  - **AppCompat/ShimCache:** `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache` (parse offline).
  - **BAM/DAM:** `HKLM\SYSTEM\CurrentControlSet\Services\bam\State` (per-user activity timestamps).
  - **Network:** firewall rules (`HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy`), interfaces, and DNS cache (`HKLM\SYSTEM\CurrentControlSet\Services\Dnscache`).

## File-system artifacts
- **Prefetch:** `C:\Windows\Prefetch` (use recent Windows build matching parser). Captures execution counts and last run times.
- **AmCache:** `C:\Windows\AppCompat\Programs\Amcache.hve` (installed/executed binaries metadata).
- **Recent files/jump lists:** `C:\Users\<user>\AppData\Roaming\Microsoft\Windows\Recent` and `AutomaticDestinations`/`CustomDestinations` under `...\Recent\AutomaticDestinations`.
- **Recycle Bin:** `$Recycle.Bin` per volume.
- **Shadow Copies:** enumerate with `vssadmin list shadows` and capture relevant `\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy#` paths.
- **LNK files:** `C:\Users\<user>\AppData\Roaming\Microsoft\Windows\Recent` and desktop/start menu shortcuts.
- **BITS jobs:** `C:\ProgramData\Microsoft\Network\Downloader` (BITS persistence/downloads).
- **WMI repository:** `C:\Windows\System32\wbem\Repository`.
- **Task files:** `C:\Windows\System32\Tasks` for on-disk scheduled task definitions.

## User activity and credentials
- **Browser artifacts:** per-browser profiles (Edge/Chrome/Brave/Firefox) under `C:\Users\<user>\AppData\Local` or `Roaming`; include `History`, `Cookies`, `Login Data`, `Downloads`, `Top Sites`, `Web Data`.
- **PowerShell:** console history (`ConsoleHost_history.txt`), PSReadLine history (`AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine`), module logs, and `Transcription` output if enabled.
- **Remote access:** RDP (`Default.rdp`, `RecentItems`, `RDP client cache`, `Terminal Server` keys), PuTTY registry keys, SSH configs (`.ssh\known_hosts`, `authorized_keys`).
- **Cloud sync:** OneDrive/SharePoint logs (`AppData\Local\Microsoft\OneDrive\logs`), Dropbox/Box/Google Drive client data.
- **Email clients:** Outlook OST/PST paths, recent attachments, Outlook SecureTemp folder.
- **Credential stores:** DPAPI master keys (`AppData\Roaming\Microsoft\Protect`), Credential Manager (`\AppData\Local\Microsoft\Credentials` and `Vault`), LSA secrets, cached logons, `SAM` hives.

## Persistence and execution tracing
- **Services and drivers:** `sc query`, `Get-Service`, autoruns locations, `C:\Windows\System32\drivers` for unsigned/odd drivers.
- **Startup folders:** `C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup` and per-user startup.
- **Scheduled tasks:** `schtasks /query /fo LIST /v` plus on-disk/registry artifacts.
- **WMI/ETW:** event consumers and ETW providers configured to start processes.
- **Browser extensions:** review suspicious extensions under `AppData` profile folders.
- **Installers:** `C:\Windows\inf\setupapi.dev.log`, `setupapi.app.log`, MSI logs (`%WINDIR%\Logs\CBS\`), and `Program Files`/`ProgramData` for newly added apps.

## Network and lateral movement
- Firewall and connection logs: `C:\Windows\System32\LogFiles\Firewall\pfirewall.log` (if enabled), Windows Defender Network Protection logs.
- RDP: `Security` log (IDs 4624/4625/4634/4647/4778/4779), `TerminalServices-LocalSessionManager/Operational`, `RemoteConnectionManager/Operational`, and `Microsoft-Windows-RemoteDesktopServices-RdpCoreTS/Operational`.
- SMB: `Security` 5140/5142/5143/5144 and `Microsoft-Windows-SmbClient/Connectivity`/`Security` logs.
- Remote services: `sc.exe` usage, `psexec` artifacts (`\admin$`, services named `PSEXESVC`), WinRM/PowerShell remoting logs (`PowerShell/Operational`, `Microsoft-Windows-WinRM/Operational`).
- ARP cache and routing tables for quick lateral movement detection.

## Data staging and exfiltration indicators
- Large archive creation or transfers in user temp folders (`%TEMP%`, `%LOCALAPPDATA%\Temp`).
- Cloud upload clients or browser history showing file-sharing sites.
- BITS jobs and `Background Intelligent Transfer Service` logs.
- Recent removable media: `Setupapi.dev.log`, `Microsoft-Windows-Partition/Diagnostic` log, registry keys under `HKLM\SYSTEM\CurrentControlSet\Enum\USBSTOR` and `MountedDevices`.

## Recommended tools and commands
- **Native:** `wevtutil`, `wmic process list full`, `netsh advfirewall show`, `schtasks`, `dir /s /a /t:w` for rapid directory timelines.
- **Sysinternals:** `Autoruns`, `Procmon` (boot logging), `Tcpview`, `Sigcheck`, `Listdlls`, `Sysmon` (ensure configs captured), `PsExec` artifacts.
- **Timeline building:** export `$MFT`, `$J` (USN Journal), and `$LogFile`; parse with `MFTECmd`, `JLECmd`, `LogFileParser`.
- **Correlation tips:** align Prefetch last-run, event log timestamps, BAM/DAM activity, SRUM network usage, and AmCache install times to build a minute-level timeline.

## Collection checklist (minimal set)
- [ ] Memory image + hashes
- [ ] Running processes/services/network connections
- [ ] Full set of Windows event logs (System, Security, Application, PowerShell, WMI, Sysmon, Defender)
- [ ] Registry hives (SYSTEM, SOFTWARE, SAM, SECURITY, DEFAULT, per-user hives)
- [ ] Prefetch, AmCache, SRUM, BAM/DAM, ShimCache, TaskCache
- [ ] Scheduled tasks folder and service binaries
- [ ] User profiles (browser data, PS histories, Recent/Jump Lists, desktop/downloads/temp)
- [ ] Shadow copies and Recycle Bin
- [ ] Network/firewall/RDP/SMB logs
- [ ] Tooling/EDR logs and configuration exports

## Acquisition notes
- Use read-only mounts or trusted collection kits; avoid altering atime when possible.
- Record time synchronization status (`w32tm /query /status`) to adjust for clock skew.
- Prefer full-disk or volume images for high-severity incidents; document any exclusions.
- When collecting over the network, ensure encryption and integrity (e.g., `sftp`, `scp`, `robocopy` over SMB signing).