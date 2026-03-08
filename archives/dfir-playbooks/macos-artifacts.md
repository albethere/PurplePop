# macOS Forensic Artifacts

> A quick-reference for locating and collecting high-value macOS artifacts during DFIR investigations.

## System & Host Context
- System profile snapshot: `system_profiler SPSoftwareDataType SPHardwareDataType SPStorageDataType > ~/Desktop/system_profile.txt`
- Installed applications: `/Applications`, `/Library/Application Support`, `/Library/Receipts/InstallHistory.plist`
- Power events & reboots: Unified log query `log show --predicate 'eventMessage CONTAINS "Previous shutdown"' --style syslog --last 7d`

## Persistence & Startup Items
- Launch agents (user): `~/Library/LaunchAgents/*.plist`
- Launch agents (system): `/Library/LaunchAgents/*.plist`
- Launch daemons: `/Library/LaunchDaemons/*.plist`
- Login items DB (per user): `~/Library/Application Support/com.apple.backgroundtaskmanagementagent/backgrounditems.btm`
- Startup scripts (legacy): `/etc/rc.common`, `/etc/rc*`

## User Activity & Timeline
- KnowledgeC (user actions, app usage): `~/Library/Application Support/Knowledge/knowledgeC.db`
- Quarantine events (downloads & first-seen): `/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2`
- Recent items: `~/Library/Preferences/com.apple.recentitems.plist`
- Spotlight metadata (file create/access): `/Volumes/<vol>/.Spotlight-V100/Store-V2/*`
- Unified logs (system-wide timeline): `log show --style syslog --last 24h > ~/Desktop/unifiedlog-24h.txt`

## Filesystem & Volume Info
- APFS container & volume details: `diskutil apfs list`
- FSEvents (file change journal): `/System/Volumes/Data/.fseventsd/`
- Time Machine snapshots: `tmutil listbackups`, local snapshots `tmutil listlocalsnapshots /`
- Trash (user): `~/.Trash`, `/Users/Shared/.Trashes`

## Network & Remote Access
- Wi‑Fi networks & timestamps: `/Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist`
- Interface configs & DHCP: `/Library/Preferences/SystemConfiguration/preferences.plist`
- Firewall log: `/var/log/appfirewall.log`
- SSH: `/etc/ssh/sshd_config`, auth log `log show --predicate 'process == "sshd"' --style syslog --last 7d`
- Screen sharing/ARD: `/Library/Preferences/com.apple.RemoteManagement.plist`

## Browser & Cloud Artifacts
- Safari history: `~/Library/Safari/History.db` (and `LastSession.plist`)
- Safari downloads: `~/Library/Safari/Downloads.plist`
- Chrome/Edge: `~/Library/Application Support/Google/Chrome/Default/History`
- iCloud Drive sync state: `~/Library/Application Support/CloudDocs/session/db/client.db`

## Messaging & Communications
- iMessage & SMS: `~/Library/Messages/chat.db` (attachments in `~/Library/Messages/Attachments/`)
- FaceTime call history: `~/Library/Preferences/com.apple.facetime.bag.plist`, `~/Library/Preferences/com.apple.MobilePhone.call_history.db`
- Mail: `~/Library/Mail/` per-account subfolders and `Envelope Index*` databases

## Security Controls
- Gatekeeper & notarization decisions: `/private/var/db/SystemPolicy` (notably `systempolicy.db`)
- Transparency, Consent, and Control (TCC): `~/Library/Application Support/com.apple.TCC/TCC.db`
- XProtect & MRT signatures: `/Library/Apple/System/Library/CoreServices/XProtect.bundle/`, `/Library/Apple/System/Library/CoreServices/MRT.app`
- FileVault status: `fdesetup status`

## Collection Tips
- Preserve extended attributes when copying files: `cp -a` or `rsync -aHAX`
- Capture volatile data first (processes, network, memory if available) before imaging disks.
- Use `log collect --last 1d --output ~/Desktop/macOS-log-collect.diag` for a structured, signed log bundle.
- Record the time reference: `systemsetup -gettimezone` and `date -u` for correlation across artifacts.