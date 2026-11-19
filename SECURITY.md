# Security policy

This repository is a disposable training environment, not a production domain design.

- Never commit passwords, recovery keys, Windows product keys or exported directory data.
- Use an isolated Hyper-V switch and snapshots/checkpoints before changing AD DS, DNS, DHCP or GPO.
- Do not reuse the example domain, accounts or passwords in a real organization.
- The Zabbix web interface binds to localhost. Keep it behind a VPN or authenticated reverse proxy if remote access is required.
- Verify the SHA-256 digest of every downloaded MSI before installation.
- Run the lab scripts only in dedicated virtual machines. Read each script and use `-WhatIf` where supported.

If a credential is committed, revoke or rotate it before removing it from Git history.

