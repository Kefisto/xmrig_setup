## mpool.pro XMRig Setup

This repository contains binaries of [XMRig](https://github.com/xmrig/xmrig) miner built to work on more platforms, bundled with helper Windows/Linux setup scripts that automatically configure them to work with the [mpool.pro](https://mpool.pro) Monero (XMR) mining pool.

### Pool Servers

| Server | Address |
|--------|---------|
| Main | `gulf.mpool.pro` |
| Backup (Germany) | `de.mpool.pro` |
| Tor | `mpoolg5v5rpc5hqx76kfg23uproub5pto6j6miaany33ltpm2efeetqd.onion` |

### Ports

| Port | Starting Difficulty | Recommendation |
|------|---------------------|----------------|
| 3333 | 1,000 | Slow hardware |
| 5555 | 5,000 | Medium hardware |
| 7777 | 10,000 | Powerful hardware |
| 9000 | 20,000 | Any hardware (SSL/TLS) |

### Quick Start

Replace `YOUR_WALLET_ADDRESS` with your Monero wallet address.

**Linux:**
```bash
curl -s -L https://raw.githubusercontent.com/mpoolpro/xmrig_setup/main/setup_mpool_miner.sh | bash -s YOUR_WALLET_ADDRESS
```

**Windows (PowerShell):**
```powershell
powershell -Command "$wc = New-Object System.Net.WebClient; $f = \"$env:TEMP\setup_mpool_miner.bat\"; $wc.DownloadFile('https://raw.githubusercontent.com/mpoolpro/xmrig_setup/main/setup_mpool_miner.bat', $f); Start-Process cmd -ArgumentList '/c', $f, 'YOUR_WALLET_ADDRESS' -Wait; Remove-Item $f"
```

### Uninstall

**Linux:**
```bash
curl -s -L https://raw.githubusercontent.com/mpoolpro/xmrig_setup/main/uninstall_mpool_miner.sh | bash
```

**Windows (PowerShell):**
```powershell
powershell -Command "$wc = New-Object System.Net.WebClient; $f = \"$env:TEMP\uninstall_mpool_miner.bat\"; $wc.DownloadFile('https://raw.githubusercontent.com/mpoolpro/xmrig_setup/main/uninstall_mpool_miner.bat', $f); Start-Process cmd -ArgumentList '/c', $f -Wait; Remove-Item $f"
```

### Support

- Pool: https://mpool.pro
- Discord: https://discord.gg/m2z6rkCgc3
- Email: support@mpool.pro
