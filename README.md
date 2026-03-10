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

**Windows:**
```
setup_mpool_miner.bat <wallet_address>
```

**Linux:**
```
bash setup_mpool_miner.sh <wallet_address>
```

### Uninstall

**Windows:** `uninstall_mpool_miner.bat`
**Linux:** `bash uninstall_mpool_miner.sh`

### Support

- Pool: https://mpool.pro
- Discord: https://discord.gg/m2z6rkCgc3
- Email: support@mpool.pro
