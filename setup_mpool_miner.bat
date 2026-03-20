@echo off

set VERSION=2.5

rem printing greetings

echo mpool mining setup script v%VERSION%.
echo ^(please report issues to support@mpool.pro email^)
echo.

net session >nul 2>&1
if %errorLevel% == 0 (set ADMIN=1) else (set ADMIN=0)

rem command line arguments
set WALLET=%1

rem checking prerequisites

if [%WALLET%] == [] (
  echo Script usage:
  echo ^> setup_mpool_miner.bat ^<wallet address^>
  echo ERROR: Please specify your wallet address
  exit /b 1
)

for /f "delims=." %%a in ("%WALLET%") do set WALLET_BASE=%%a
call :strlen "%WALLET_BASE%", WALLET_BASE_LEN
if %WALLET_BASE_LEN% == 106 goto WALLET_LEN_OK
if %WALLET_BASE_LEN% ==  95 goto WALLET_LEN_OK
echo ERROR: Wrong wallet address length (should be 106 or 95): %WALLET_BASE_LEN%
exit /b 1

:WALLET_LEN_OK

if ["%USERPROFILE%"] == [""] (
  echo ERROR: Please define USERPROFILE environment variable to your user directory
  exit /b 1
)

if not exist "%USERPROFILE%" (
  echo ERROR: Please make sure user directory %USERPROFILE% exists
  exit /b 1
)

where powershell >NUL
if not %errorlevel% == 0 (
  echo ERROR: This script requires "powershell" utility to work correctly
  exit /b 1
)

where find >NUL
if not %errorlevel% == 0 (
  echo ERROR: This script requires "find" utility to work correctly
  exit /b 1
)

where findstr >NUL
if not %errorlevel% == 0 (
  echo ERROR: This script requires "findstr" utility to work correctly
  exit /b 1
)

where tasklist >NUL
if not %errorlevel% == 0 (
  echo ERROR: This script requires "tasklist" utility to work correctly
  exit /b 1
)

if %ADMIN% == 1 (
  where sc >NUL
  if not %errorlevel% == 0 (
    echo ERROR: This script requires "sc" utility to work correctly
    exit /b 1
  )
)

rem calculating port

set /a "EXP_MONERO_HASHRATE = %NUMBER_OF_PROCESSORS% * 700 / 1000"

if [%EXP_MONERO_HASHRATE%] == [] ( 
  echo ERROR: Can't compute projected Monero hashrate
  exit 
)

if %EXP_MONERO_HASHRATE% gtr 10 ( set PORT=7777 & goto PORT_OK )
if %EXP_MONERO_HASHRATE% gtr 2  ( set PORT=5555 & goto PORT_OK )
set PORT=3333

:PORT_OK

rem selecting best server by ping

echo [*] Checking latency to pool servers...
for /f "tokens=*" %%a in ('powershell -Command "try { [math]::Round((Test-Connection gulf.mpool.pro -Count 2 -EA Stop | Measure-Object -Property ResponseTime -Average).Average) } catch { 9999 }"') do set GULF_PING=%%a
for /f "tokens=*" %%a in ('powershell -Command "try { [math]::Round((Test-Connection de.mpool.pro -Count 2 -EA Stop | Measure-Object -Property ResponseTime -Average).Average) } catch { 9999 }"') do set DE_PING=%%a

if %GULF_PING% leq %DE_PING% (
  set POOL_HOST=gulf.mpool.pro
  set BACKUP_HOST=de.mpool.pro
) else (
  set POOL_HOST=de.mpool.pro
  set BACKUP_HOST=gulf.mpool.pro
)

if %GULF_PING% == 9999 ( set "GULF_DISP=unreachable" ) else ( set "GULF_DISP=%GULF_PING%ms" )
if %DE_PING% == 9999 ( set "DE_DISP=unreachable" ) else ( set "DE_DISP=%DE_PING%ms" )
echo   gulf.mpool.pro: %GULF_DISP% ^| de.mpool.pro: %DE_DISP% -^> using %POOL_HOST%

rem printing intentions

set "LOGFILE=%USERPROFILE%\mpool\xmrig.log"

echo I will download, setup and run in background Monero CPU miner with logs in %LOGFILE% file.
echo If needed, miner in foreground can be started by %USERPROFILE%\mpool\miner.bat script.
echo Mining will happen to %WALLET% wallet.
echo.

if %ADMIN% == 0 (
  echo Since I do not have admin access, mining in background will be started using your startup directory script and only work when your are logged in this host.
) else (
  echo Mining in background will be performed using mpool_miner service.
)

echo.
echo JFYI: This host has %NUMBER_OF_PROCESSORS% CPU threads, so projected Monero hashrate is around %EXP_MONERO_HASHRATE% KH/s.
echo.

pause

rem start doing stuff: preparing miner

echo [*] Removing previous mpool miner (if any)
sc stop mpool_miner
sc delete mpool_miner
taskkill /f /t /im xmrig.exe

:REMOVE_DIR0
echo [*] Removing "%USERPROFILE%\mpool" directory
timeout 5
rmdir /q /s "%USERPROFILE%\mpool" >NUL 2>NUL
IF EXIST "%USERPROFILE%\mpool" GOTO REMOVE_DIR0

echo [*] Downloading mpool advanced version of xmrig to "%USERPROFILE%\xmrig.zip"
powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/mpoolpro/xmrig_setup/main/xmrig.zip', '%USERPROFILE%\xmrig.zip')"
if errorlevel 1 (
  echo ERROR: Can't download mpool advanced version of xmrig
  goto MINER_BAD
)

echo [*] Unpacking "%USERPROFILE%\xmrig.zip" to "%USERPROFILE%\mpool"
powershell -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('%USERPROFILE%\xmrig.zip', '%USERPROFILE%\mpool')"
if errorlevel 1 (
  echo [*] Downloading 7za.exe to "%USERPROFILE%\7za.exe"
  powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/mpoolpro/xmrig_setup/main/7za.exe', '%USERPROFILE%\7za.exe')"
  if errorlevel 1 (
    echo ERROR: Can't download 7za.exe to "%USERPROFILE%\7za.exe"
    exit /b 1
  )
  echo [*] Unpacking stock "%USERPROFILE%\xmrig.zip" to "%USERPROFILE%\mpool"
  "%USERPROFILE%\7za.exe" x -y -o"%USERPROFILE%\mpool" "%USERPROFILE%\xmrig.zip" >NUL
  del "%USERPROFILE%\7za.exe"
)
del "%USERPROFILE%\xmrig.zip"

echo [*] Checking if advanced version of "%USERPROFILE%\mpool\xmrig.exe" works fine ^(and not removed by antivirus software^)
powershell -Command "$out = cat '%USERPROFILE%\mpool\config.json' | %%{$_ -replace '\"donate-level\": *\d*,', '\"donate-level\": 1,'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\mpool\config.json'"
"%USERPROFILE%\mpool\xmrig.exe" --help >NUL
if %ERRORLEVEL% equ 0 goto MINER_OK
:MINER_BAD

if exist "%USERPROFILE%\mpool\xmrig.exe" (
  echo WARNING: Advanced version of "%USERPROFILE%\mpool\xmrig.exe" is not functional
) else (
  echo WARNING: Advanced version of "%USERPROFILE%\mpool\xmrig.exe" was removed by antivirus
)

echo [*] Looking for the latest version of Monero miner
for /f tokens^=2^ delims^=^" %%a IN ('powershell -Command "[Net.ServicePointManager]::SecurityProtocol = 'tls12, tls11, tls'; $wc = New-Object System.Net.WebClient; $str = $wc.DownloadString('https://github.com/xmrig/xmrig/releases/latest'); $str | findstr msvc-win64.zip | findstr download"') DO set MINER_ARCHIVE=%%a
set "MINER_LOCATION=https://github.com%MINER_ARCHIVE%"

echo [*] Downloading "%MINER_LOCATION%" to "%USERPROFILE%\xmrig.zip"
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = 'tls12, tls11, tls'; $wc = New-Object System.Net.WebClient; $wc.DownloadFile('%MINER_LOCATION%', '%USERPROFILE%\xmrig.zip')"
if errorlevel 1 (
  echo ERROR: Can't download "%MINER_LOCATION%" to "%USERPROFILE%\xmrig.zip"
  exit /b 1
)

:REMOVE_DIR1
echo [*] Removing "%USERPROFILE%\mpool" directory
timeout 5
rmdir /q /s "%USERPROFILE%\mpool" >NUL 2>NUL
IF EXIST "%USERPROFILE%\mpool" GOTO REMOVE_DIR1

echo [*] Unpacking "%USERPROFILE%\xmrig.zip" to "%USERPROFILE%\mpool"
powershell -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('%USERPROFILE%\xmrig.zip', '%USERPROFILE%\mpool')"
if errorlevel 1 (
  echo [*] Downloading 7za.exe to "%USERPROFILE%\7za.exe"
  powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/mpoolpro/xmrig_setup/main/7za.exe', '%USERPROFILE%\7za.exe')"
  if errorlevel 1 (
    echo ERROR: Can't download 7za.exe to "%USERPROFILE%\7za.exe"
    exit /b 1
  )
  echo [*] Unpacking advanced "%USERPROFILE%\xmrig.zip" to "%USERPROFILE%\mpool"
  "%USERPROFILE%\7za.exe" x -y -o"%USERPROFILE%\mpool" "%USERPROFILE%\xmrig.zip" >NUL
  if errorlevel 1 (
    echo ERROR: Can't unpack "%USERPROFILE%\xmrig.zip" to "%USERPROFILE%\mpool"
    exit /b 1
  )
  del "%USERPROFILE%\7za.exe"
)
del "%USERPROFILE%\xmrig.zip"

echo [*] Checking if stock version of "%USERPROFILE%\mpool\xmrig.exe" works fine ^(and not removed by antivirus software^)
powershell -Command "$out = cat '%USERPROFILE%\mpool\config.json' | %%{$_ -replace '\"donate-level\": *\d*,', '\"donate-level\": 0,'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\mpool\config.json'" 
"%USERPROFILE%\mpool\xmrig.exe" --help >NUL
if %ERRORLEVEL% equ 0 goto MINER_OK

if exist "%USERPROFILE%\mpool\xmrig.exe" (
  echo WARNING: Stock version of "%USERPROFILE%\mpool\xmrig.exe" is not functional
) else (
  echo WARNING: Stock version of "%USERPROFILE%\mpool\xmrig.exe" was removed by antivirus
)

exit /b 1

:MINER_OK

echo [*] Miner "%USERPROFILE%\mpool\xmrig.exe" is OK

for /f "tokens=*" %%a in ('powershell -Command "hostname | %%{$_ -replace '[^a-zA-Z0-9]+', '_'}"') do set PASS=%%a
if [%PASS%] == [] (
  set PASS=na
)

powershell -Command "$out = cat '%USERPROFILE%\mpool\config.json' | %%{$_ -replace '\"url\": *\".*\",', '\"url\": \"%POOL_HOST%:%PORT%\",'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\mpool\config.json'" 
powershell -Command "$out = cat '%USERPROFILE%\mpool\config.json' | %%{$_ -replace '\"user\": *\".*\",', '\"user\": \"%WALLET%\",'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\mpool\config.json'" 
powershell -Command "$out = cat '%USERPROFILE%\mpool\config.json' | %%{$_ -replace '\"pass\": *\".*\",', '\"pass\": \"%PASS%\",'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\mpool\config.json'" 
powershell -Command "$out = cat '%USERPROFILE%\mpool\config.json' | %%{$_ -replace '\"algo\": *null,', '\"algo\": \"rx/0\",'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\mpool\config.json'" 
powershell -Command "$out = cat '%USERPROFILE%\mpool\config.json' | %%{$_ -replace '\"coin\": *null,', '\"coin\": \"monero\",'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\mpool\config.json'" 
powershell -Command "$out = cat '%USERPROFILE%\mpool\config.json' | %%{$_ -replace '\"max-cpu-usage\": *\d*,', '\"max-cpu-usage\": 100,'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\mpool\config.json'" 
set LOGFILE2=%LOGFILE:\=\\%
powershell -Command "$out = cat '%USERPROFILE%\mpool\config.json' | %%{$_ -replace '\"log-file\": *null,', '\"log-file\": \"%LOGFILE2%\",'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\mpool\config.json'" 

echo [*] Adding backup pool %BACKUP_HOST%:%PORT% for failover
powershell -Command "$j = Get-Content '%USERPROFILE%\mpool\config.json' -Raw | ConvertFrom-Json; if ($j.pools.Count -gt 0) { $b = $j.pools[0] | ConvertTo-Json -Depth 5 | ConvertFrom-Json; $b.url = '%BACKUP_HOST%:%PORT%'; $j.pools = @($j.pools[0], $b) }; $j | ConvertTo-Json -Depth 10 | Out-File -Encoding ASCII '%USERPROFILE%\mpool\config.json'"

copy /Y "%USERPROFILE%\mpool\config.json" "%USERPROFILE%\mpool\config_background.json" >NUL
powershell -Command "$out = cat '%USERPROFILE%\mpool\config_background.json' | %%{$_ -replace '\"background\": *false,', '\"background\": true,'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\mpool\config_background.json'" 

rem preparing script
(
echo @echo off
echo tasklist /fi "imagename eq xmrig.exe" ^| find ":" ^>NUL
echo if errorlevel 1 goto ALREADY_RUNNING
echo start /low %%~dp0xmrig.exe %%^*
echo goto EXIT
echo :ALREADY_RUNNING
echo echo Monero miner is already running in the background. Refusing to run another one.
echo echo Run "taskkill /IM xmrig.exe" if you want to remove background miner first.
echo :EXIT
) > "%USERPROFILE%\mpool\miner.bat"

rem preparing script background work and work under reboot

if %ADMIN% == 1 goto ADMIN_MINER_SETUP

if exist "%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" (
  set "STARTUP_DIR=%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
  goto STARTUP_DIR_OK
)
if exist "%USERPROFILE%\Start Menu\Programs\Startup" (
  set "STARTUP_DIR=%USERPROFILE%\Start Menu\Programs\Startup"
  goto STARTUP_DIR_OK  
)

echo ERROR: Can't find Windows startup directory
exit /b 1

:STARTUP_DIR_OK
echo [*] Adding call to "%USERPROFILE%\mpool\miner.bat" script to "%STARTUP_DIR%\mpool_miner.bat" script
(
echo @echo off
echo "%USERPROFILE%\mpool\miner.bat" --config="%USERPROFILE%\mpool\config_background.json"
) > "%STARTUP_DIR%\mpool_miner.bat"

echo [*] Running miner in the background
call "%STARTUP_DIR%\mpool_miner.bat"
goto OK

:ADMIN_MINER_SETUP

echo [*] Downloading tools to make mpool_miner service to "%USERPROFILE%\nssm.zip"
powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/mpoolpro/xmrig_setup/main/nssm.zip', '%USERPROFILE%\nssm.zip')"
if errorlevel 1 (
  echo ERROR: Can't download tools to make mpool_miner service
  exit /b 1
)

echo [*] Unpacking "%USERPROFILE%\nssm.zip" to "%USERPROFILE%\mpool"
powershell -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('%USERPROFILE%\nssm.zip', '%USERPROFILE%\mpool')"
if errorlevel 1 (
  echo [*] Downloading 7za.exe to "%USERPROFILE%\7za.exe"
  powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/mpoolpro/xmrig_setup/main/7za.exe', '%USERPROFILE%\7za.exe')"
  if errorlevel 1 (
    echo ERROR: Can't download 7za.exe to "%USERPROFILE%\7za.exe"
    exit /b 1
  )
  echo [*] Unpacking "%USERPROFILE%\nssm.zip" to "%USERPROFILE%\mpool"
  "%USERPROFILE%\7za.exe" x -y -o"%USERPROFILE%\mpool" "%USERPROFILE%\nssm.zip" >NUL
  if errorlevel 1 (
    echo ERROR: Can't unpack "%USERPROFILE%\nssm.zip" to "%USERPROFILE%\mpool"
    exit /b 1
  )
  del "%USERPROFILE%\7za.exe"
)
del "%USERPROFILE%\nssm.zip"

echo [*] Creating mpool_miner service
sc stop mpool_miner
sc delete mpool_miner
"%USERPROFILE%\mpool\nssm.exe" install mpool_miner "%USERPROFILE%\mpool\xmrig.exe"
if errorlevel 1 (
  echo ERROR: Can't create mpool_miner service
  exit /b 1
)
"%USERPROFILE%\mpool\nssm.exe" set mpool_miner AppDirectory "%USERPROFILE%\mpool"
"%USERPROFILE%\mpool\nssm.exe" set mpool_miner AppPriority BELOW_NORMAL_PRIORITY_CLASS
"%USERPROFILE%\mpool\nssm.exe" set mpool_miner AppStdout "%USERPROFILE%\mpool\stdout"
"%USERPROFILE%\mpool\nssm.exe" set mpool_miner AppStderr "%USERPROFILE%\mpool\stderr"

echo [*] Starting mpool_miner service
"%USERPROFILE%\mpool\nssm.exe" start mpool_miner
if errorlevel 1 (
  echo ERROR: Can't start mpool_miner service
  exit /b 1
)

echo
echo Please reboot system if mpool_miner service is not activated yet (if "%USERPROFILE%\mpool\xmrig.log" file is empty)
goto OK

:OK
echo
echo [*] Setup complete
pause
exit /b 0

:strlen string len
setlocal EnableDelayedExpansion
set "token=#%~1" & set "len=0"
for /L %%A in (12,-1,0) do (
  set/A "len|=1<<%%A"
  for %%B in (!len!) do if "!token:~%%B,1!"=="" set/A "len&=~1<<%%A"
)
endlocal & set %~2=%len%
exit /b





