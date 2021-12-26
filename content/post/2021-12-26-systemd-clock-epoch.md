+++
date = "2021-12-26T06:24:00Z"
title = "Systemd's clock-epoch for RTC-less systems"
description = "Configuring the systems clock at boot for RTC-less systems, like the Raspberry Pi, using systemd's clock-epoch."
+++

Earlier today I restarted a Raspberry Pi I use on my home network. When the system came up after reboot, many services failed to resume, which I quickly noticed due to the lack of DNS resolution on my network. Upon checking the system logs, the culprit became clear: CoreDNS was failing to verify the certificates of my DNS-over-TLS provider. According to my Raspberry Pi, we were partying like it was 1999. Without DNS resolution the system time would never automatically synchronize with NTP.

On a Raspberry Pi running Raspian or Raspberry Pi OS, the system is automatically configured to use `fake-hwclock` to save the time to disk from a cron, and restore it at boot. However, this package isn't widely distributed outside Debian and it's derivatives.

At boot, systemd compares the system time to a builtin epoch, usually the release or build date of systemd. If it finds the system time is before this epoch, it resets the clock to the epoch. Unfortunately, this is still sometimes too old, especially when it comes to TLS certificates.

We can still utilize this systemd feature however, at least if systemd is version 247 or newer, by utilizing a hook added to aid system administrators and image distributors. If the file `/usr/lib/clock-epoch` exists, systemd uses the modified time as the systemd epoch.

We can even script periodically updating this file. First, create `/etc/systemd/system/set-clock-epoch.service`:


```ini
[Unit]
Description=Updates the mtime of clock-epoch

[Service]
ExecStart=/bin/touch -m /usr/lib/clock-epoch
```

Then, create a timer to start it periodically, at `/etc/systemd/system/set-clock-epoch.timer`:

```ini
[Unit]
Description=Timer for updating clock-epoch

[Timer]
OnBootSec=5min
OnUnitInactiveSec=17min
```

Then reload the daemon, then enable and start the timer.

```bash
systemd daemon-reload
systemd enable --now set-clock-epoch.timer
```

Now when the system reboots, systemd will read the modification time of this file during early boot, setting the time to a reasonably close value, allowing certificates to be validated and NTP to take over.
