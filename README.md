## mpool.pro XMRig Setup

Setup scripts for Windows and Linux that automatically download the latest [XMRig](https://github.com/xmrig/xmrig) miner from official releases, configure it for the [mpool.pro](https://mpool.pro) Monero (XMR) pool (algorithm: **rx/0 only**, no algo-switching), and set up auto-start.

> **Disclaimer:** This software is intended for legitimate cryptocurrency mining on hardware you own or have explicit permission to use. Unauthorized use of someone else's computing resources for mining is illegal. The authors are not responsible for any misuse of this software.

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

### License

This project is licensed under the [GNU General Public License v3.0](LICENSE), same as [XMRig](https://github.com/xmrig/xmrig).

---

## Гайд на русском

### Что это?

Автоматический установщик майнера [XMRig](https://github.com/xmrig/xmrig) для пула [mpool.pro](https://mpool.pro). Скрипт скачает последнюю версию XMRig с GitHub, настроит конфиг под ваш кошелёк и запустит майнинг **только Monero (XMR)** на алгоритме **rx/0** (без algo-switching).

### Что нужно перед началом

1. **Кошелёк Monero** — адрес длиной 95 или 106 символов (начинается на `4` или `8`). Если нет — создайте на [getmonero.org](https://www.getmonero.org/downloads/) или в любом кошельке с поддержкой XMR.
2. **Отключить антивирус** (или добавить папку майнера в исключения) — антивирусы часто удаляют XMRig, хотя он не является вирусом.

### Установка

Скопируйте команду, замените `ВАШ_АДРЕС_КОШЕЛЬКА` на ваш Monero-адрес и вставьте в терминал.

#### Linux / macOS

```bash
curl -s -L https://raw.githubusercontent.com/mpoolpro/xmrig_setup/main/setup_mpool_miner.sh | bash -s ВАШ_АДРЕС_КОШЕЛЬКА
```

#### Windows

Откройте **PowerShell** (правой кнопкой по Пуску → Windows PowerShell) и вставьте:

```powershell
powershell -Command "$wc = New-Object System.Net.WebClient; $f = \"$env:TEMP\setup_mpool_miner.bat\"; $wc.DownloadFile('https://raw.githubusercontent.com/mpoolpro/xmrig_setup/main/setup_mpool_miner.bat', $f); Start-Process cmd -ArgumentList '/c', $f, 'ВАШ_АДРЕС_КОШЕЛЬКА' -Wait; Remove-Item $f"
```

### Что произойдёт после запуска

1. Скачает последнюю версию XMRig с [официального репозитория](https://github.com/xmrig/xmrig/releases/latest)
2. Пропингует `gulf.mpool.pro` и `de.mpool.pro` и выберет сервер с наименьшей задержкой
3. Автоматически выберет порт по мощности CPU (3333 / 5555 / 7777)
4. Настроит `config.json`: алгоритм **rx/0**, монета **Monero**, резервный пул для автопереключения при сбое
5. **На Windows:** предложит выбор — запуск в видимом окне, в фоне, или не запускать сейчас
6. На Windows с правами администратора — создаст системную службу `mpool_miner` (работает после перезагрузки)
7. На Windows без прав администратора — добавит майнер в автозагрузку
8. **На Linux** с sudo — создаст systemd-сервис `mpool_miner` и запустит в фоне

### Серверы пула

| Сервер | Адрес |
|--------|-------|
| Основной | `gulf.mpool.pro` |
| Резервный (Германия) | `de.mpool.pro` |
| Tor | `mpoolg5v5rpc5hqx76kfg23uproub5pto6j6miaany33ltpm2efeetqd.onion` |

### Порты

| Порт | Начальная сложность | Для какого железа |
|------|---------------------|-------------------|
| 3333 | 1 000 | Слабое |
| 5555 | 5 000 | Среднее |
| 7777 | 10 000 | Мощное |
| 9000 | 20 000 | Любое (SSL/TLS) |

Скрипт выбирает порт автоматически на основе количества ядер CPU.

### Проверка работы

- **Логи:** `%USERPROFILE%\mpool\xmrig.log` (Windows) или `$HOME/mpool/xmrig.log` (Linux)
- **Статистика:** откройте https://mpool.pro и введите свой адрес кошелька
- **Ручной запуск:** `%USERPROFILE%\mpool\miner.bat` (Windows) или `$HOME/mpool/miner.sh` (Linux)

### Удаление

#### Linux

```bash
curl -s -L https://raw.githubusercontent.com/mpoolpro/xmrig_setup/main/uninstall_mpool_miner.sh | bash
```

#### Windows

```powershell
powershell -Command "$wc = New-Object System.Net.WebClient; $f = \"$env:TEMP\uninstall_mpool_miner.bat\"; $wc.DownloadFile('https://raw.githubusercontent.com/mpoolpro/xmrig_setup/main/uninstall_mpool_miner.bat', $f); Start-Process cmd -ArgumentList '/c', $f -Wait; Remove-Item $f"
```

### Поддержка

- Пул: https://mpool.pro
- Discord: https://discord.gg/m2z6rkCgc3
- Email: support@mpool.pro
