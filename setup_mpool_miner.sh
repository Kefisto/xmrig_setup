#!/bin/bash

VERSION=2.11

# printing greetings

echo "mpool mining setup script v$VERSION."
echo "(please report issues to support@mpool.pro email with full output of this script with extra \"-x\" \"bash\" option)"
echo

if [ "$(id -u)" == "0" ]; then
  echo "WARNING: Generally it is not advised to run this script under root"
fi

# command line arguments
WALLET=$1

# checking prerequisites

if [ -z $WALLET ]; then
  echo "Script usage:"
  echo "> setup_mpool_miner.sh <wallet address>"
  echo "ERROR: Please specify your wallet address"
  exit 1
fi

WALLET_BASE=`echo $WALLET | cut -f1 -d"."`
if [ ${#WALLET_BASE} != 106 -a ${#WALLET_BASE} != 95 ]; then
  echo "ERROR: Wrong wallet base address length (should be 106 or 95): ${#WALLET_BASE}"
  exit 1
fi

if [ -z $HOME ]; then
  echo "ERROR: Please define HOME environment variable to your home directory"
  exit 1
fi

if [ ! -d $HOME ]; then
  echo "ERROR: Please make sure HOME directory $HOME exists or set it yourself using this command:"
  echo '  export HOME=<dir>'
  exit 1
fi

if ! type curl >/dev/null; then
  echo "ERROR: This script requires \"curl\" utility to work correctly"
  exit 1
fi

if ! type lscpu >/dev/null; then
  echo "WARNING: This script requires \"lscpu\" utility to work correctly"
fi

# calculating projected hash rate

CPU_THREADS=$(nproc)
EXP_MONERO_HASHRATE=$(( CPU_THREADS * 700 / 1000))
if [ -z $EXP_MONERO_HASHRATE ]; then
  echo "ERROR: Can't compute projected Monero CN hashrate"
  exit 1
fi

# selecting port based on hashrate

if [ $EXP_MONERO_HASHRATE -gt 10 ]; then
  PORT=7777
elif [ $EXP_MONERO_HASHRATE -gt 2 ]; then
  PORT=5555
else
  PORT=3333
fi

# selecting best server by ping

echo "[*] Checking latency to pool servers..."
GULF_PING=$(ping -c 2 -W 2 gulf.mpool.pro 2>/dev/null | tail -1 | awk -F '/' '{printf "%.0f", $5}')
DE_PING=$(ping -c 2 -W 2 de.mpool.pro 2>/dev/null | tail -1 | awk -F '/' '{printf "%.0f", $5}')

if [ -z "$GULF_PING" ] && [ -z "$DE_PING" ]; then
  POOL_HOST="gulf.mpool.pro"
  BACKUP_HOST="de.mpool.pro"
  echo "  WARNING: Can't ping either server, defaulting to gulf.mpool.pro"
elif [ -z "$GULF_PING" ]; then
  POOL_HOST="de.mpool.pro"
  BACKUP_HOST="gulf.mpool.pro"
  echo "  gulf.mpool.pro: unreachable | de.mpool.pro: ${DE_PING}ms -> using de.mpool.pro"
elif [ -z "$DE_PING" ]; then
  POOL_HOST="gulf.mpool.pro"
  BACKUP_HOST="de.mpool.pro"
  echo "  gulf.mpool.pro: ${GULF_PING}ms | de.mpool.pro: unreachable -> using gulf.mpool.pro"
elif [ "$GULF_PING" -le "$DE_PING" ]; then
  POOL_HOST="gulf.mpool.pro"
  BACKUP_HOST="de.mpool.pro"
  echo "  gulf.mpool.pro: ${GULF_PING}ms | de.mpool.pro: ${DE_PING}ms -> using gulf.mpool.pro"
else
  POOL_HOST="de.mpool.pro"
  BACKUP_HOST="gulf.mpool.pro"
  echo "  gulf.mpool.pro: ${GULF_PING}ms | de.mpool.pro: ${DE_PING}ms -> using de.mpool.pro"
fi

# printing intentions

echo
echo "I will download, setup and run in background mpool CPU miner."
echo "If needed, miner in foreground can be started by \$HOME/mpool/miner.sh script."
echo "Mining will happen to \$WALLET wallet."
echo

if ! sudo -n true 2>/dev/null; then
  echo "Since I can't do passwordless sudo, mining in background will start from your \$HOME/.profile file first time you login this host after reboot."
else
  echo "Mining in background will be performed using mpool_miner systemd service."
fi

echo
echo "JFYI: This host has $CPU_THREADS CPU threads, so projected Monero hashrate is around $EXP_MONERO_HASHRATE KH/s."
echo "      Pool connection: $POOL_HOST:$PORT"
echo

echo "Sleeping for 15 seconds before continuing (press Ctrl+C to cancel)"
sleep 15
echo
echo

# start doing stuff: preparing miner

echo "[*] Removing previous mpool miner (if any)"
if sudo -n true 2>/dev/null; then
  sudo systemctl stop mpool_miner.service
fi
killall -9 xmrig

echo "[*] Removing \$HOME/mpool directory"
rm -rf $HOME/mpool

echo "[*] Looking for the latest version of XMRig"
LATEST_XMRIG_LINUX_RELEASE=$(curl -sL https://api.github.com/repos/xmrig/xmrig/releases/latest | grep -o '"browser_download_url": *"[^"]*linux-static-x64.tar.gz"' | cut -d '"' -f 4)
if [ -z "$LATEST_XMRIG_LINUX_RELEASE" ]; then
  echo "ERROR: Can't determine latest XMRig release URL from GitHub API"
  exit 1
fi

echo "[*] Downloading $LATEST_XMRIG_LINUX_RELEASE to /tmp/xmrig.tar.gz"
if ! curl -L --progress-bar "$LATEST_XMRIG_LINUX_RELEASE" -o /tmp/xmrig.tar.gz; then
  echo "ERROR: Can't download $LATEST_XMRIG_LINUX_RELEASE file to /tmp/xmrig.tar.gz"
  exit 1
fi

echo "[*] Unpacking /tmp/xmrig.tar.gz to \$HOME/mpool"
[ -d $HOME/mpool ] || mkdir $HOME/mpool
if ! tar xf /tmp/xmrig.tar.gz -C $HOME/mpool --strip=1; then
  echo "ERROR: Can't unpack /tmp/xmrig.tar.gz to \$HOME/mpool directory"
  exit 1
fi
rm /tmp/xmrig.tar.gz

echo "[*] Checking if \$HOME/mpool/xmrig works fine (and not removed by antivirus software)"
sed -i 's/"donate-level": *[^,]*,/"donate-level": 1,/' $HOME/mpool/config.json
$HOME/mpool/xmrig --help >/dev/null
if (test $? -ne 0); then
  if [ -f $HOME/mpool/xmrig ]; then
    echo "ERROR: \$HOME/mpool/xmrig is not functional"
  else
    echo "ERROR: \$HOME/mpool/xmrig was removed by antivirus (or some other problem)"
  fi
  exit 1
fi

echo "[*] Miner \$HOME/mpool/xmrig is OK"

PASS=`hostname | cut -f1 -d"." | sed -r 's/[^a-zA-Z0-9\-]+/_/g'`
if [ "$PASS" == "localhost" ]; then
  PASS=`ip route get 1 | awk '{print $NF;exit}'`
fi
if [ -z $PASS ]; then
  PASS=na
fi

sed -i 's/"url": *"[^"]*",/"url": "'$POOL_HOST':'$PORT'",/' $HOME/mpool/config.json
sed -i 's/"user": *"[^"]*",/"user": "'$WALLET'",/' $HOME/mpool/config.json
sed -i 's/"pass": *"[^"]*",/"pass": "'$PASS'",/' $HOME/mpool/config.json
sed -i 's/"algo": *[^,]*,/"algo": "rx\/0",/' $HOME/mpool/config.json
sed -i 's/"coin": *[^,]*,/"coin": "monero",/' $HOME/mpool/config.json
sed -i 's/"max-cpu-usage": *[^,]*,/"max-cpu-usage": 100,/' $HOME/mpool/config.json
sed -i 's#"log-file": *null,#"log-file": "'$HOME/mpool/xmrig.log'",#' $HOME/mpool/config.json
sed -i 's/"syslog": *[^,]*,/"syslog": true,/' $HOME/mpool/config.json

echo "[*] Adding backup pool $BACKUP_HOST:$PORT for failover"
if type python3 >/dev/null 2>&1; then
  python3 -c "
import json, sys
try:
    with open(sys.argv[1]) as f: cfg = json.load(f)
    if cfg.get('pools') and len(cfg['pools']) > 0:
        import copy
        backup = copy.deepcopy(cfg['pools'][0])
        backup['url'] = sys.argv[2]
        cfg['pools'].append(backup)
        with open(sys.argv[1], 'w') as f: json.dump(cfg, f, indent=4)
except Exception as e:
    print('WARNING: Could not add backup pool: ' + str(e))
" $HOME/mpool/config.json "$BACKUP_HOST:$PORT"
elif type python >/dev/null 2>&1; then
  python -c "
import json, sys, copy
try:
    with open(sys.argv[1]) as f: cfg = json.load(f)
    if cfg.get('pools') and len(cfg['pools']) > 0:
        backup = copy.deepcopy(cfg['pools'][0])
        backup['url'] = sys.argv[2]
        cfg['pools'].append(backup)
        with open(sys.argv[1], 'w') as f: json.dump(cfg, f, indent=4)
except Exception as e:
    print('WARNING: Could not add backup pool: ' + str(e))
" $HOME/mpool/config.json "$BACKUP_HOST:$PORT"
else
  echo "WARNING: python not found, skipping backup pool (failover won't work)"
fi

cp $HOME/mpool/config.json $HOME/mpool/config_background.json
sed -i 's/"background": *false,/"background": true,/' $HOME/mpool/config_background.json

# preparing script

echo "[*] Creating \$HOME/mpool/miner.sh script"
cat >$HOME/mpool/miner.sh <<EOL
#!/bin/bash
if ! pidof xmrig >/dev/null; then
  nice \$HOME/mpool/xmrig \$*
else
  echo "Monero miner is already running in the background. Refusing to run another one."
  echo "Run \"killall xmrig\" or \"sudo killall xmrig\" if you want to remove background miner first."
fi
EOL

chmod +x $HOME/mpool/miner.sh

# preparing background start

if ! sudo -n true 2>/dev/null; then
  if ! grep mpool/miner.sh $HOME/.profile >/dev/null; then
    echo "[*] Adding \$HOME/mpool/miner.sh script to \$HOME/.profile"
    echo "\$HOME/mpool/miner.sh --config=\$HOME/mpool/config_background.json >/dev/null 2>&1" >>$HOME/.profile
  else 
    echo "Looks like \$HOME/mpool/miner.sh script is already in the \$HOME/.profile"
  fi
  echo "[*] Running miner in the background (see logs in \$HOME/mpool/xmrig.log file)"
  /bin/bash $HOME/mpool/miner.sh --config=$HOME/mpool/config_background.json >/dev/null 2>&1
else

  if [[ $(grep MemTotal /proc/meminfo | awk '{print $2}') > 3500000 ]]; then
    echo "[*] Enabling huge pages"
    echo "vm.nr_hugepages=$((1168+$(nproc)))" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -w vm.nr_hugepages=$((1168+$(nproc)))
  fi

  if ! type systemctl >/dev/null; then

    echo "[*] Running miner in the background (see logs in \$HOME/mpool/xmrig.log file)"
    /bin/bash $HOME/mpool/miner.sh --config=$HOME/mpool/config_background.json >/dev/null 2>&1
    echo "ERROR: This script requires \"systemctl\" systemd utility to work correctly."
    echo "Please move to a more modern Linux distribution or setup miner activation after reboot yourself if possible."

  else

    echo "[*] Creating mpool_miner systemd service"
    cat >/tmp/mpool_miner.service <<EOL
[Unit]
Description=mpool miner service

[Service]
ExecStart=$HOME/mpool/xmrig --config=$HOME/mpool/config.json
Restart=always
Nice=10
CPUWeight=1

[Install]
WantedBy=multi-user.target
EOL
    sudo mv /tmp/mpool_miner.service /etc/systemd/system/mpool_miner.service
    echo "[*] Starting mpool_miner systemd service"
    sudo killall xmrig 2>/dev/null
    sudo systemctl daemon-reload
    sudo systemctl enable mpool_miner.service
    sudo systemctl start mpool_miner.service
    echo "To see miner service logs run \"sudo journalctl -u mpool_miner -f\" command"
  fi
fi

echo ""
echo "NOTE: If you are using shared VPS it is recommended to avoid 100% CPU usage produced by the miner or you will be banned"
if [ "$CPU_THREADS" -lt "4" ]; then
  echo "HINT: Please execute these or similar commands under root to limit miner to 75% CPU usage:"
  echo "sudo apt-get update; sudo apt-get install -y cpulimit"
  echo "sudo cpulimit -e xmrig -l $((75*$CPU_THREADS)) -b"
  if [ "`tail -n1 /etc/rc.local`" != "exit 0" ]; then
    echo "sudo sed -i -e '\$acpulimit -e xmrig -l $((75*$CPU_THREADS)) -b\\n' /etc/rc.local"
  else
    echo "sudo sed -i -e '\$i \\cpulimit -e xmrig -l $((75*$CPU_THREADS)) -b\\n' /etc/rc.local"
  fi
else
  echo "HINT: Please execute these commands and reboot your VPS after that to limit miner to 75% CPU usage:"
  echo "sed -i 's/\"max-threads-hint\": *[^,]*,/\"max-threads-hint\": 75,/' \$HOME/mpool/config.json"
  echo "sed -i 's/\"max-threads-hint\": *[^,]*,/\"max-threads-hint\": 75,/' \$HOME/mpool/config_background.json"
fi
echo ""

echo "[*] Setup complete"
