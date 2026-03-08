# Linux Forensic Artifacts Quick Reference

A concise checklist of high-value artifacts to collect during DFIR on Linux systems. Adjust for distribution specifics (systemd versus SysV, apt versus yum/dnf) and ensure evidence is collected with minimal alteration (mount read-only, use `--preserve` flags, etc.).

## System context
- **Host identity:** `hostnamectl`, `/etc/hostname`, `/etc/machine-id`, `/etc/issue`, `/etc/os-release`.
- **Hardware & kernel:** `uname -a`, `lscpu`, `lsblk -f`, `lspci`, `lsusb`, `dmidecode`, `/proc/cpuinfo`, `/proc/meminfo`.
- **Boot & uptime:** `who -b`, `uptime -p`, `journalctl -b`, `/var/log/boot.log` (where present), `/var/log/dmesg`.
- **Environment:** `env`, shell profiles (`/etc/profile`, `/etc/profile.d/*`, `~/.bash*`, `~/.zsh*`), `/etc/skel/`.

## Users and authentication
- **Account databases:** `/etc/passwd`, `/etc/shadow` (hashes), `/etc/group`, `/etc/gshadow`, `/etc/sudoers`, `/etc/sudoers.d/*`.
- **Login records:** `/var/log/wtmp` (logins), `/var/log/btmp` (failed logins), `/var/run/utmp` (current sessions); review with `last -f`, `lastb -f`, or `utmpdump`.
- **Auth logs:** `/var/log/auth.log` (Debian/Ubuntu) or `/var/log/secure` (RHEL/CentOS), PAM logs, `/var/log/faillog`, `/var/log/tallylog`, `/var/log/lastlog`.
- **SSH artifacts:** `~/.ssh/authorized_keys`, `~/.ssh/known_hosts`, `/etc/ssh/sshd_config`, `/etc/ssh/ssh_config`, host keys (`/etc/ssh/ssh_host_*`), `ss` or `lsof -i` for active sessions.

## Persistence mechanisms
- **Systemd units:** `/etc/systemd/system/*.service`, `/lib/systemd/system/*.service`, user units in `~/.config/systemd/user/`, `systemctl list-unit-files --type=service`, `systemctl status <unit>`.
- **Cron & timers:** `/etc/crontab`, `/etc/cron.*/*`, user crontabs in `/var/spool/cron/` or `/var/spool/cron/crontabs/`, systemd timers (`*.timer`), `systemctl list-timers --all`.
- **Init scripts & rc hooks:** `/etc/rc.local`, `/etc/init.d/*`, `/etc/rc?.d/`, `/etc/profile.d/`, `/etc/ld.so.preload`, `/etc/modules*`, `/etc/modprobe.d/*`.
- **Desktop/autostart:** `~/.config/autostart/*.desktop`, `/etc/xdg/autostart/`, display manager scripts (e.g., `/etc/lightdm/lightdm.conf.d/`, `/usr/share/gdm/`), `~/.config/systemd/user/` units.

## Running state
- **Processes:** `ps auxf`, `pstree -alp`, `/proc/<pid>/` (cwd, exe, cmdline, environ, sockets), `lsof -p <pid>`, `systemctl status` for services.
- **Open files and sockets:** `lsof`, `ss -tulpan`, `netstat -plant` (if available), `/proc/net/{tcp,tcp6,udp,udp6}`.
- **Scheduled jobs in memory:** `crontab -l` per user, `atq`/`at -c`, `systemctl list-timers`.
- **Kernel modules:** `lsmod`, `modinfo <module>`, `/lib/modules/<kernel>/`, `/etc/modprobe.d/*`.

## Network configuration & activity
- **Interfaces & routes:** `ip addr`, `ip link`, `ip route`, `ip neigh`, `/etc/network/interfaces`, NetworkManager profiles (`/etc/NetworkManager/system-connections/*.nmconnection`).
- **Name resolution:** `/etc/resolv.conf`, `/etc/hosts`, `/etc/nsswitch.conf`, `systemd-resolve --status`, DNS cache (if `systemd-resolved`).
- **DHCP and wireless:** DHCP leases (`/var/lib/dhcp/*`, `/var/lib/NetworkManager/*lease*`), `iwconfig`/`iw dev`, `wpa_supplicant.conf`, `hostapd.conf`.
- **Firewall:** `iptables -L -n -v`/`iptables-save`, `nft list ruleset`, `firewalld` configs in `/etc/firewalld/`.
- **Tunnels & VPNs:** OpenVPN (`/etc/openvpn/*.conf`, `~/.config/openvpn/`), WireGuard (`/etc/wireguard/*.conf`), SSH tunnels (`ss -atp`), `ip xfrm state` for IPsec.

## Disk, file system, and integrity
- **Mounts & volumes:** `lsblk -f`, `mount`, `/etc/fstab`, `/etc/mtab`, LVM info (`pvs`, `lvs`, `vgs`), encrypted volumes (`cryptsetup status`, `/etc/crypttab`).
- **Recent files:** `find / -xdev -type f -mtime -2`, `stat`/`getfattr` for MAC times, `inotify` traces if available.
- **Deleted/hidden:** review `/proc/*/fd/`, overlay/union FS, bind mounts, extended attributes (`lsattr`, `getfattr`).
- **Integrity & signatures:** package verification (`debsums -s`, `rpm -Va`), `aide`/`integrity` databases, `tripwire` if deployed.

## Logs and auditing
- **System logs:** `/var/log/syslog` (Debian/Ubuntu), `/var/log/messages` (RHEL/Fedora), `/var/log/kern.log`, `/var/log/dmesg`.
- **Service logs:** `/var/log/*` per daemon (nginx, apache2/httpd, mysql/mariadb, postgres, rsync, etc.), application-specific logs in `/opt/*/logs`.
- **Journal:** `journalctl -xe`, `journalctl --since "-2d"`, persistent journal in `/var/log/journal/`, boot-specific (`journalctl -b -1`).
- **Audit framework:** `/var/log/audit/audit.log`, `ausearch`, `aureport`, `/etc/audit/auditd.conf`, `/etc/audit/rules.d/*.rules`.

## Packages and software inventory
- **Installed packages:** `dpkg -l` (Debian-based), `rpm -qa` (RPM-based), `flatpak list`, `snap list`.
- **Repositories & keys:** `/etc/apt/sources.list`, `/etc/apt/sources.list.d/*.list`, `/etc/yum.repos.d/*.repo`, `/etc/pki/rpm-gpg/`, `/etc/zypp/repos.d/`.
- **Updates & install history:** `/var/log/apt/history.log`, `/var/log/dpkg.log`, `/var/log/yum.log` or `/var/log/dnf.rpm.log`, `/var/log/pacman.log`.
- **Language/package managers:** pip (`pip list`, `~/.cache/pip/log`), npm (`npm list -g --depth=1`), gem (`gem list`), rustup/cargo (`~/.cargo/`, `~/.rustup/`).

## Persistence via applications & services
- **Web stack:** webroots (`/var/www/`, `/srv/www/`), virtual host configs (`/etc/nginx/sites-enabled/`, `/etc/httpd/conf.d/`), `.htaccess`, TLS keys (`/etc/letsencrypt/`), uploads directories.
- **Databases:** MySQL/MariaDB (`/var/lib/mysql/`, `/etc/mysql/`), PostgreSQL (`/var/lib/postgresql/`, `/etc/postgresql/`), SQLite files, backup dumps in `/var/backups/` or `/root/`.
- **Mail & messaging:** Postfix (`/etc/postfix/`, `/var/log/mail*`), Exim, Sendmail, Dovecot, `/var/spool/mail/`, `/var/mail/`.
- **Task runners & queues:** systemd services, `supervisord.conf`, `pm2 list`, `cron`, `at`, `celery`/`rq` configs, `/etc/rc.local` scripts.

## Containers, virtualization, and cloud
- **Docker/Podman:** `/var/lib/docker/` (layers, containers), `docker ps -a`, `docker inspect <id>`, logs in `/var/lib/docker/containers/<id>/*-json.log`, `/etc/docker/daemon.json`, Podman storage in `~/.local/share/containers/`.
- **Kubernetes:** kubelet configs (`/var/lib/kubelet/config.yaml`), manifests (`/etc/kubernetes/manifests/`), `kubectl config view`, container runtimes (`crictl ps -a`, `/var/log/containers/`).
- **Virtual machines:** libvirt (`/etc/libvirt/`, `/var/lib/libvirt/`), qemu/kvm images (`/var/lib/libvirt/images/`), VirtualBox/VMware config and VMDKs/VDIs.
- **Cloud metadata:** cloud-init logs (`/var/log/cloud-init.log`, `/var/log/cloud-init-output.log`), instance metadata cached under `/var/lib/cloud/`.

## Memory and volatile data
- **Live response basics:** capture `ps aux`, `ss -tulpan`, `arp -an`, `ip route`, `ip addr`, `iptables-save`/`nft list ruleset`, `last`/`who`, `w`, `/proc/mounts`.
- **Memory acquisition:** `avml`, `lime`/`lime2`, `makelive`, `fmem` (if supported); verify output hashes and storage location.
- **Swap & hibernation:** swap devices from `/proc/swaps`, `lsblk`, `cat /sys/power/resume` for hibernation image.

## Collection tips
- Prefer **read-only mounts** or trusted static binaries on removable media when imaging.
- Record **hashes** (e.g., `sha256sum`) and **timestamps** for each artifact.
- When feasible, collect both **filesystem images** (e.g., `dd`, `ewfacquire`, `partclone`) and **logical exports** of high-value paths.
- Document commands run, user context, and collection timeline to preserve chain of custody.